%% issue: https://github.com/basho/riak_repl/issues/649

%% ----- sink -----

%% check for orphaned helper processes
[ Pid || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsink_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ].

%% remove orphans
[ exit(Pid, orphan) || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsink_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ].


%% ----- source -----

%% check for orphaned helper processes
[ Pid || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsource_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ].

%% remove orphans
[ exit(Pid, orphan) || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsource_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ].


%% combining

Kill = fun() ->
{length([ exit(Pid, orphan) || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsource_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ]),
length([ exit(Pid, orphan) || {Pid, false} <- [ {Pid, is_process_alive(Parent)} || {Pid, {riak_repl2_rtsink_helper,init,1}, [Parent|Others]} <- [ {Pid, proplists:get_value('$initial_call', D), proplists:get_value('$ancestors',D)} || {Pid,{dictionary,D}} <- [ {P,process_info(P,dictionary)} || P <- processes() ]]] ])}
end.
riak_core_util:rpc_every_member_ann(erlang, apply, [ Kill, []], 600000).