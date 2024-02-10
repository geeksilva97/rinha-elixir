defmodule RinhaElixir.Reporitory.BalanceAggregateMnesia do
  alias :mnesia, as: Mnesia

  @table BalanceAggregate

  def get(client_id) do
    [{_, _, saldo, limite}] = Mnesia.read({@table, client_id})

    {:ok, saldo, limite}
  end

  def get_with_write_lock(client_id) do
    [{_, _, saldo, limite}] = Mnesia.wread({@table, client_id})

    {:ok, saldo, limite}
  end

  @spec set(client_id :: integer(), { saldo :: integer(), limite :: integer() }) :: tuple()
  def set(client_id, { saldo, limite }) do
    Mnesia.write({@table, client_id, saldo, limite})
  end

  def increment_saldo(client_id, incrementing_value) do
    {:ok, saldo, limite} = get_with_write_lock(client_id)
    novo_saldo = saldo + incrementing_value
    :ok = set(client_id, { novo_saldo, limite })

    {:ok, novo_saldo, limite}
  end
end
