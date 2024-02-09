defmodule RinhaElixir.BankBalanceHandler do
  @behaviour :gen_event

  alias RinhaElixir.{Store, ClientStore}

  def init([]) do
    {:ok, []}
  end

  def delete_handler() do
    RinhaElixir.Bus.delete_handler(__MODULE__, [])
  end

  def handle_event({:log_event, event_data}, state) do
    client_id = event_data["client_id"]
    transaction = Map.delete(event_data, "client_id") |> Map.put("realizada_em", DateTime.utc_now())

    Store.store_event(client_id, Map.delete(event_data, "client_id"))
    ClientStore.append_transaction(client_id, transaction)

    {:ok, state}
  end

  def handle_event(event, state) do
    IO.puts("Received event #{inspect(event)} :: state #{inspect(state)}")

    {:ok, state}
  end

  def handle_call(_, state) do
    {:ok, state}
  end
end
