defmodule RinhaElixir.BankBalanceHandler do
  @behaviour :gen_event

  alias RinhaElixir.Store

  def init([]) do
    {:ok, []}
  end

  def delete_handler() do
    RinhaElixir.Bus.delete_handler(__MODULE__, [])
  end

  def handle_event({:log_event, %{"client_id" => client_id}}, state) do
    Store.store_event(client_id, :hello_world)

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
