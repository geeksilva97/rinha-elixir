defmodule RinhaElixir.Store do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def store_event(client_id, payload) do
    GenServer.call(__MODULE__, { :store_event, { client_id, payload } })
  end

  def wtf do
    GenServer.call(__MODULE__, :fodase)
  end

  defp write_log(client_id, event_data) do
    # Mnesia.dirty_write({EventLog, client_id, make_ref(), 1, event_data})

    {:atomic, :ok} = Mnesia.transaction(fn ->
      Mnesia.write({EventLog, client_id, make_ref(), 1, event_data})
    end)
  end

  def init(_) do
    Mnesia.create_schema([node()])
    Mnesia.start()

    {:atomic, :ok} = Mnesia.create_table(EventLog, [attributes: [:client_id, :event_id, :version, :event_data], type: :bag])

    Logger.info("Store started successfully")

    {:ok, %{}}
  end

  def handle_call({ :store_event, { client_id, payload } }, _from, state) do
    write_log(client_id, payload)

    {:reply, :ok, state}
  end

  def handle_call(_event, _from, state) do
    {:reply, :wtf, state}
  end
end
