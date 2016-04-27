%% to check if cluster is affected
riak_core_util:rpc_every_member_ann(supervisor, count_children, [riak_kv_get_fsm_sup], 5000).