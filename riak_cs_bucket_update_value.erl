% value is the Owner Key Id

OwnerToSet = <<"0">>.

{ok,C} = riak:local_client(),

case catch C:get(<<"moss.buckets">>,<<"backups">>,[{pr,all}]) of
    {ok,Obj} ->
        UpdatedObj = riak_object:update_value(Obj, OwnerToSet),
        NewObj = riak_object:apply_updates(UpdatedObj),
        Res = (catch C:put(NewObj,[{pw,all}])),
        io:format("Put result: ~p~n",[Res]);
    GetError ->
        io:format("Error retrieving Riak object: ~p~n", [GetError])
end.