defmodule RinhaElixir.Store do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def store_event(client_id, payload) do
    GenServer.call(__MODULE__, { :store_event, { client_id, payload } })
  end

  defp write_log(client_id, event_data) do
    {:atomic, :ok} = Mnesia.transaction(fn ->
      Mnesia.write({EventLog, client_id, make_ref(), 1, event_data})
    end)

    :ok
  end

  def init([]) do
    Mnesia.create_schema([node()])
    Mnesia.start()
    {:atomic, :ok} = Mnesia.create_table(EventLog, [attributes: [:client_id, :event_id, :version, :event_data], type: :bag])

    {:ok, %{}}
  end

  def handle_call({ :store_event, { client_id, payload } }, _from, state) do
    IO.puts("gotta store this event")

    write_log(client_id, payload)

    {:noreply, state}
  end
end
