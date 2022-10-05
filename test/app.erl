%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright © 2022 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(app).

-include_lib("eunit/include/eunit.hrl").

-include("src/internal.hrl").
-include("src/khepri_error.hrl").

app_starts_workers_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
       [?_assertMatch({ok, _}, application:ensure_all_started(khepri)),
        ?_assert(is_process_alive(whereis(khepri_event_handler))),
        ?_assertEqual([?FUNCTION_NAME], khepri:get_store_ids()),
        ?_assert(khepri_utils:should_collect_code_for_module(some_mod)),
        ?_assertNot(khepri_utils:should_collect_code_for_module(khepri_tx)),
        ?_assertEqual(ok, application:stop(khepri)),
        ?_assertEqual(undefined, whereis(khepri_event_handler)),
        ?_assertEqual([], khepri:get_store_ids()),
        ?_assertEqual([], [PT || {Key, _} = PT <- persistent_term:get(),
                                 element(1, Key) =:= khepri])]}]}.

event_handler_gen_server_callbacks_test() ->
    %% This testcase is mostly to improve code coverage. We don't really care
    %% about the unused mandatory callbacks of this gen_server.
    ?assertMatch({ok, _}, application:ensure_all_started(khepri)),
    ?assert(is_process_alive(whereis(khepri_event_handler))),
    khepri_event_handler ! timeout,
    khepri_event_handler ! any_message,
    ?assertEqual(ok, gen_server:cast(khepri_event_handler, any_cast)),
    ?assertEqual(ok, gen_server:call(khepri_event_handler, any_call)),
    ?assert(is_process_alive(whereis(khepri_event_handler))),
    ?assertEqual(ok, application:stop(khepri)).

get_default_timeout_with_no_app_env_test() ->
    ?assertEqual(
       infinity,
       khepri_app:get_default_timeout()).

get_default_timeout_with_infinity_app_env_test() ->
    Timeout = infinity,
    application:set_env(
      khepri, default_timeout, Timeout, [{persistent, true}]),
    ?assertEqual(
       Timeout,
       khepri_app:get_default_timeout()),
    application:unset_env(
      khepri, default_timeout, [{persistent, true}]).

get_default_timeout_with_non_neg_integer_app_env_test() ->
    Timeout = 0,
    application:set_env(
      khepri, default_timeout, Timeout, [{persistent, true}]),
    ?assertEqual(
       Timeout,
       khepri_app:get_default_timeout()),
    application:unset_env(
      khepri, default_timeout, [{persistent, true}]).

get_default_timeout_with_neg_integer_app_env_test() ->
    Timeout = -5000,
    application:set_env(
      khepri, default_timeout, Timeout, [{persistent, true}]),
    ?assertError(
       ?khepri_exception(
          invalid_default_timeout_value,
          #{default_timeout := Timeout}),
       khepri_app:get_default_timeout()),
    application:unset_env(
      khepri, default_timeout, [{persistent, true}]).

get_default_timeout_with_invalid_app_env_test() ->
    %% We change the log level so that another branch of the `?LOG_*' macro is
    %% taken, to improve code coverage. It is not necessary for the testcase
    %% itself.
    #{level := LogLevel} = logger:get_primary_config(),
    ok = logger:set_primary_config(level, none),

    Invalid = {invalid},
    application:set_env(
      khepri, default_timeout, Invalid, [{persistent, true}]),
    ?assertError(
       ?khepri_exception(
          invalid_default_timeout_value,
          #{default_timeout := Invalid}),
       khepri_app:get_default_timeout()),
    application:unset_env(
      khepri, default_timeout, [{persistent, true}]),

    %% Restore the previously changed log level.
    ok = logger:set_primary_config(level, LogLevel).

get_default_ra_system_or_data_dir_with_no_app_env_test() ->
    ?assertEqual(
       khepri_cluster:generate_default_data_dir(),
       khepri_cluster:get_default_ra_system_or_data_dir()).

get_default_ra_system_or_data_dir_with_atom_app_env_test() ->
    RaSystem = my_ra_system,
    application:set_env(
      khepri, default_ra_system, RaSystem, [{persistent, true}]),
    ?assertEqual(
       RaSystem,
       khepri_cluster:get_default_ra_system_or_data_dir()),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

get_default_ra_system_or_data_dir_with_string_app_env_test() ->
    DataDir = "/tmp",
    application:set_env(
      khepri, default_ra_system, DataDir, [{persistent, true}]),
    ?assertEqual(
       DataDir,
       khepri_cluster:get_default_ra_system_or_data_dir()),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

get_default_ra_system_or_data_dir_with_binary_app_env_test() ->
    DataDir = <<"/tmp">>,
    application:set_env(
      khepri, default_ra_system, DataDir, [{persistent, true}]),
    ?assertEqual(
       DataDir,
       khepri_cluster:get_default_ra_system_or_data_dir()),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

get_default_ra_system_or_data_dir_with_invalid_app_env_test() ->
    Invalid = {invalid},
    application:set_env(
      khepri, default_ra_system, Invalid, [{persistent, true}]),
    ?assertError(
       ?khepri_exception(
          invalid_default_ra_system_value,
          #{default_ra_system := Invalid}),
       khepri_cluster:get_default_ra_system_or_data_dir()),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

get_default_store_id_with_no_app_env_test() ->
    ?assertEqual(
       khepri,
       khepri_cluster:get_default_store_id()).

get_default_store_id_with_atom_app_env_test() ->
    StoreId = my_store,
    application:set_env(
      khepri, default_store_id, StoreId, [{persistent, true}]),
    ?assertEqual(
       StoreId,
       khepri_cluster:get_default_store_id()),
    application:unset_env(
      khepri, default_store_id, [{persistent, true}]).

get_default_store_id_with_invalid_app_env_test() ->
    Invalid = {invalid},
    application:set_env(
      khepri, default_store_id, Invalid, [{persistent, true}]),
    ?assertError(
       ?khepri_exception(
          invalid_default_store_id_value,
          #{default_store_id := Invalid}),
       khepri_cluster:get_default_store_id()),
    application:unset_env(
      khepri, default_store_id, [{persistent, true}]).

start_with_default_settings_test() ->
    DataDir = khepri_cluster:generate_default_data_dir(),
    ?assertNot(filelib:is_dir(DataDir)),
    ?assertEqual({ok, ?DEFAULT_STORE_ID}, khepri_cluster:start()),
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(ok, khepri_cluster:stop()),

    ?assertEqual(ok, application:stop(khepri)),
    ?assertEqual(ok, application:stop(ra)),
    ?assertEqual(ok, helpers:remove_store_dir(DataDir)).

start_with_data_dir_in_args_test() ->
    DataDir = helpers:store_dir_name(?FUNCTION_NAME),
    ?assertNot(filelib:is_dir(DataDir)),
    ?assertEqual(
       {ok, ?DEFAULT_STORE_ID},
       khepri_cluster:start(DataDir)),
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(ok, khepri_cluster:stop()),

    ?assertEqual(ok, application:stop(khepri)),
    ?assertEqual(ok, application:stop(ra)),
    ?assertEqual(ok, helpers:remove_store_dir(DataDir)).

start_with_data_dir_in_app_env_test() ->
    DataDir = helpers:store_dir_name(?FUNCTION_NAME),
    ?assertNot(filelib:is_dir(DataDir)),
    application:set_env(
      khepri, default_ra_system, DataDir, [{persistent, true}]),
    ?assertEqual({ok, ?DEFAULT_STORE_ID}, khepri_cluster:start()),
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(ok, khepri_cluster:stop()),

    ?assertEqual(ok, application:stop(khepri)),
    ?assertEqual(ok, application:stop(ra)),
    ?assertEqual(ok, helpers:remove_store_dir(DataDir)),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

start_with_ra_system_in_args_test() ->
    Props = helpers:start_ra_system(?FUNCTION_NAME),
    #{ra_system := RaSystem,
      store_dir := DataDir} = Props,
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(
       {ok, ?DEFAULT_STORE_ID},
       khepri_cluster:start(RaSystem)),
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(ok, khepri_cluster:stop(?DEFAULT_STORE_ID)),
    helpers:stop_ra_system(Props),
    ?assertNot(filelib:is_dir(DataDir)),

    ?assertEqual(ok, application:stop(khepri)),
    ?assertEqual(ok, application:stop(ra)),
    ?assertEqual(ok, helpers:remove_store_dir(DataDir)).

start_with_ra_system_in_app_env_test() ->
    Props = helpers:start_ra_system(?FUNCTION_NAME),
    #{ra_system := RaSystem,
      store_dir := DataDir} = Props,
    ?assert(filelib:is_dir(DataDir)),
    application:set_env(
      khepri, default_ra_system, RaSystem, [{persistent, true}]),
    ?assertEqual({ok, ?DEFAULT_STORE_ID}, khepri_cluster:start()),
    ?assert(filelib:is_dir(DataDir)),
    ?assertEqual(ok, khepri_cluster:stop()),
    helpers:stop_ra_system(Props),
    ?assertNot(filelib:is_dir(DataDir)),

    ?assertEqual(ok, application:stop(khepri)),
    ?assertEqual(ok, application:stop(ra)),
    ?assertEqual(ok, helpers:remove_store_dir(DataDir)),
    application:unset_env(
      khepri, default_ra_system, [{persistent, true}]).

for_code_coverage_test() ->
    ?assertEqual(ok, khepri_app:config_change([], [], [])).
