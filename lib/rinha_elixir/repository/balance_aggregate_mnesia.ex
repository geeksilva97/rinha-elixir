defmodule RinhaElixir.Reporitory.BalanceAggregateMnesia do
  alias :mnesia, as: Mnesia

  def get(client_id) do
    [{_, _, saldo, limite}] = Mnesia.read({BalanceAggregate, client_id})

    {:ok, saldo, limite}
  end

  def transaction(fun) do
    Mnesia.transaction(fun)
  end

  def sync_transaction(fun) do
    Mnesia.sync_transaction(fun)
  end
end
