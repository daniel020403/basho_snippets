%% readable
rr(riak_core_ring).
PrintRing = fun(File) ->
  {ok,Bin}=file:read_file(File),
  rp(erlang:binary_to_term(Bin))
end.
PrintRing("riak_core_ring.default.20140917063939").

%% record is not recognized
f().
File="riak_core_ring.default.20140917063939".
{ok,Bin}=file:read_file(File).
{chstate_v2, Name, Vclock, Chring, Meta, Clustername, Next, Members, Claimant, Seen, Rvsn}=erlang:binary_to_term(Bin).
rp(proplists:get_keys(Members)).
