-module(postget_vassal).
-behaviour(vassal).

-include_lib("clexical/include/clexical.hrl").

-export([
	init/1,
	work/2
	]).

-define(APP_URL_ENCODED, 
	"application/x-www-form-urlencoded").
-define(COMPLETE_PREDICATE(ID), 
	ws_herald:predicate_from_binary(<<"<onComplete id='", ID/binary , "'/>">>)).
-define(ERROR_PREDICATE(ID), 
	ws_herald:predicate_from_binary(<<"<onError id='", ID/binary , "'/>">>)).

init(_Opts) ->
	ok.

work(#letter{predicates=
				[#predicate{action={verb, <<"post">>}, adjectives=Dict, id=ID}|_]
			} = Letter, _LP) ->
	BURL = clexical:get_adjective(<<"url">>, Dict, <<"http://www.xmpp.com.br">>),
	URL = erlang:binary_to_list(BURL),
	BPayload = clexical:get_adjective(<<"payload">>, Dict, <<"">>),
	Payload = erlang:binary_to_list(BPayload),
	compose_reply(Letter, ID, 
		httpc:request(post, {URL, [], ?APP_URL_ENCODED, Payload}, [], []));

work(#letter{predicates=
				[#predicate{action={verb, <<"get">>}, adjectives=Dict, id=ID}|_]
			}=Letter, _LP) ->
	BURL = clexical:get_adjective(<<"url">>, Dict, <<"http://www.xmpp.com.br">>),
	URL = erlang:binary_to_list(BURL),
	compose_reply(Letter, ID, httpc:request(URL));
	
work(_P,_) ->
	lager:info("Unknown Work: ~p ~n", [_P]),
	undefined.

compose_reply(Letter, ID, {_,{{_,200,_},_,_Body}}) ->
	Letter#letter{type=bulletin, predicates=[?COMPLETE_PREDICATE(ID)]};		
compose_reply(Letter, ID, _) ->
	Letter#letter{type=bulletin, predicates=[?ERROR_PREDICATE(ID)]}.
