%%%--------------------------------------------------------------------
%%% Copyright Space-Time Insight 2017. All Rights Reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%-----------------------------------------------------------------

%%%-------------------------------------------------------------------
%% @doc erleans public API
%% @end
%%%-------------------------------------------------------------------

-module(erleans_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    Specs = init_providers(),
    erleans_dns_peers:join(),
    {ok, Pid} = erleans_sup:start_link(Specs),
    post_init_providers(),
    {ok, Pid}.

%%--------------------------------------------------------------------
stop(_State) ->
    erleans_cluster:leave(),
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

init_providers() ->
    Providers = erleans_config:get(providers, []),
    lists:foldl(fun({ProviderName, Args}, Acc) ->
                    case init_provider(ProviderName, Args) of
                        {pool, Args1} ->
                            [#{id => {pool, ProviderName},
                               start => {erleans_provider_pool_sup, start_link, [ProviderName, Args1]},
                               restart => permanent,
                               type => supervisor,
                               shutdown => 5000} | Acc];
                        ok ->
                            Acc;
                        {error, Reason} ->
                            lager:error("failed to initialize provider ~s: reason=~p", [ProviderName, Reason]),
                            Acc
                    end
                end, [], Providers).

init_provider(ProviderName, Config) ->
    Module = proplists:get_value(module, Config),
    Module:init(ProviderName, Config).

post_init_providers() ->
    Providers = erleans_config:get(providers, []),
    lists:foreach(fun({ProviderName, Config}) ->
                      Module = proplists:get_value(module, Config),
                      Module:post_init(ProviderName, Config)
                  end, Providers).
