-module(mnesia_demo).

-record(person, {id, name}).

-export([run/0]).

run() ->
  mnesia:start(),
  mnesia:create_table(my_table, [{attributes, record_info(fields, person)}]).
