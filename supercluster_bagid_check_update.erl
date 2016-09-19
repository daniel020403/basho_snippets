% run on `riak attach`

% ----- check objects in a Riak CS bucket for their BagId's -----
% -- this writes the output to /tmp/out.txt
% -- example bucket: backups
code:add_paths(filelib:wildcard("/usr/lib*/riak-cs/lib/riak_cs-*/ebin")).
rr(riak_cs_lfs_utils),
BucketName = <<"backups">>,
{ok, C}=riak:local_client(),
ObjectsBucket = riak_cs_utils:to_bucket_name('objects', BucketName),
{ok,Objects} = C:list_keys(ObjectsBucket),

CheckObject = fun(ObjectKey) ->
   case catch C:get(ObjectsBucket, ObjectKey) of
      {ok, RObject} ->
          file:write_file("/tmp/out.txt", list_to_binary(io_lib:format("~p =>~n",[ObjectKey])),[append]),
          Contents = riak_object:get_contents(RObject),
          Decoded = [ binary_to_term(V) || {_,V}=Content <- Contents, not riak_cs_utils:has_tombstone(Content)],
          Manifests = lists:usort(lists:flatten(riak_cs_manifest_utils:upgrade_wrapped_manifests(Decoded))),
          [ file:write_file("/tmp/out.txt",list_to_binary(io_lib:format("    ~p    ~p~n",[M#lfs_manifest_v3.state,
              (catch proplists:get_value(block_bag, M#lfs_manifest_v3.props, bag_not_set))])),[append])
          || {_UUID, M} <- Manifests ], ok;
      Other -> io:format("Error getting object {~p, ~p}.~n",[ObjectsBucket, ObjectKey])
   end
end.

[ CheckObject(O) || O <- Objects ], ok.


% ----- should be run on `riak attach` in the master cluster -----
% ----- updates the Riak CS bucket's BagId to undefined -----
% -- example bucket: backups
{ok,C} = riak:local_client(),
case catch C:get(<<"moss.buckets">>,<<"backups">>,[{pr,all}]) of
  {ok,Obj} ->
    case riak_object:value_count(Obj) of
      1 ->
        Meta = riak_object:get_metadata(Obj),
        case catch dict:is_key(<<"X-Riak-Meta">>,Meta) of
          false -> io:format("X-Riak-Meta not found in object metadata~n");
          true ->
            InnerMeta = dict:fetch(<<"X-Riak-Meta">>,Meta),
            case catch proplists:is_defined(<<"X-Rcs-Bag">>, InnerMeta) of
              Boolean when Boolean =:= true;Boolean =:= false ->
                if Boolean -> io:format("X-Rcs-Bag not present in X-Riak-Meta.~n");
                   true -> ok
                end,
                io:format("Setting X-Rcs-Bag.~n"),
                CleanInnerMeta = proplists:delete(<<"X-Rcs-Bag">>, InnerMeta),
                NewInnerMeta = [{<<"X-Rcs-Bag">>,<<131,100,0,9,117,110,100,101,102,105,110,101,100>>}|CleanInnerMeta],
                NewMeta = dict:store(<<"X-Riak-Meta">>, NewInnerMeta, Meta),
                UpdatedObj = riak_object:update_metadata(Obj, NewMeta),
                NewObj = riak_object:apply_updates(UpdatedObj),
                Res = (catch C:put(NewObj,[{pw,all}])),
                io:format("Put result: ~p~n",[Res]);
              Error ->
                io:format("Error processing X-Riak-Meta: ~n~p~n",[Error])
            end;
          Other ->
            io:format("Error processing object metadata: ~n~p~n",[Other])
        end;
      O ->
        io:format("The bucket object has ~p values, expecting 1.~n",[O])
    end;
  GetError ->
    io:format("Error retrieving Riak object: ~p~n",[GetError])
end.