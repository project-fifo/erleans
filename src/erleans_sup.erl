%%%----------------------------------------------------------------------------
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
%%%----------------------------------------------------------------------------

%%%-------------------------------------------------------------------
%% @doc erleans top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(erleans_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).

-spec start_link(list()) -> {ok, pid()}.
start_link(ProviderPoolSpecs) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, [ProviderPoolSpecs]).

init([ProviderPools]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [#{id => erleans_grain_sup,
                    start => {erleans_grain_sup, start_link, []},
                    restart => permanent,
                    type => supervisor,
                    shutdown => 5000},
                  #{id => erleans_system_grain_sup,
                    start => {erleans_system_grain_sup, start_link, []},
                    restart => permanent,
                    type => supervisor,
                    shutdown => 5000},
                  #{id => erleans_stream_broker,
                    start => {erleans_stream_broker, start_link, []},
                    restart => permanent,
                    type => worker,
                    shutdown => 5000},
                  #{id => erleans_stream_agent_sup,
                    start => {erleans_stream_agent_sup, start_link, []},
                    restart => permanent,
                    type => supervisor,
                    shutdown => 5000},
                  #{id => erleans_stream_manager,
                    start => {erleans_stream_manager, start_link, []},
                    restart => permanent,
                    type => worker,
                    shutdown => 5000} | ProviderPools],
    {ok, {SupFlags, ChildSpecs}}.

%%====================================================================
%% Internal functions
%%====================================================================
