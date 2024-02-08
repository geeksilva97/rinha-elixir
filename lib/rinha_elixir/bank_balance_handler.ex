defmodule RinhaElixir.BankBalanceHandler do
  @behaviour :gen_event

  def init([]) do
    {:ok, []}
  end

  def delete_handler() do
    RinhaElixir.Bus.delete_handler(__MODULE__, [])
  end

  def handle_event(event, state) do
    IO.puts("Receive event #{inspect(event)} :: state #{inspect(state)}")

    {:ok, state}
  end

  def handle_call(_, state) do
    {:ok, state}
  end
end
