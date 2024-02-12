defmodule RinhaElixir.Repository.EventLogMnesia do
  alias :mnesia, as: Mnesia

  @table EventLog

  @spec save(%{client_id: integer(), data: map()}) :: tuple()
  def save(%{client_id: client_id, data: data}) do
    # {:atomic, :ok} = Mnesia.sync_transaction(fn ->
      :ok = Mnesia.dirty_write({@table, client_id, make_ref(), 1, data})
    # end)
  end
end
