defmodule RinhaElixir.BankBalanceHandler do
  @behaviour :gen_event

  alias RinhaElixir.{Store, ClientStore}
  alias RinhaElixir.Repository.EventLogMnesia
  alias :mnesia, as: Mnesia
  require Logger

  def init([]) do
    {:ok, []}
  end

  def delete_handler() do
    RinhaElixir.Bus.delete_handler(__MODULE__, [])
  end

  def handle_event({:log_event, event_data}, state) do
    # Logger.info("handling event logging")

    client_id = event_data["client_id"]
    transaction = Map.delete(event_data, "client_id") |> Map.put("realizada_em", DateTime.utc_now())

    :ok = EventLogMnesia.save(%{
      client_id: client_id,
      data: transaction
    })

    # Logger.info("Event successfully registered")

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
