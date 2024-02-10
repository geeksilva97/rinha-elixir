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
    # {:atomic, :ok} = Mnesia.transaction(fn ->
      Mnesia.write({EventLog, client_id, make_ref(), 1, event_data})
    # end)
  end

  defp cluster_nodes() do
    [node() | Node.list()]
  end

  defp create_mnesia_schema(:diogenes@api01) do
    :rpc.multicall(cluster_nodes(), :mnesia, :stop, [])

    schema_deletion_result = Mnesia.delete_schema(cluster_nodes()) 
    schema_creation_result = Mnesia.create_schema(cluster_nodes()) 

    Logger.info("Schema deletion result #{inspect(schema_deletion_result)}")
    Logger.info("Schema creation result #{inspect(schema_creation_result)}")
  end

  defp create_mnesia_schema(_), do: :noop

  def create_mnesia_tables(:diogenes@api01) do
    :rpc.multicall(cluster_nodes(), :mnesia, :start, [])
    Logger.info("Creating tables... #{inspect(cluster_nodes())}")

    Mnesia.info()

    {:atomic, :ok} = Mnesia.create_table(EventLog, [attributes: [:client_id, :event_id, :version, :event_data], type: :bag, disc_copies: cluster_nodes()])

    {:atomic, :ok} = Mnesia.create_table(BalanceAggregate, [attributes: [:client_id, :saldo, :limite], type: :set, ram_copies: cluster_nodes()])

    {:atomic, :ok} = Mnesia.create_table(LatestEvents, [attributes: [:client_id, :latest_events], type: :set, ram_copies: cluster_nodes()])
  end

  def create_mnesia_tables(_) do
    :ok
  end

  def init(_) do
    create_mnesia_schema(node())
    create_mnesia_tables(node())
    initialize_data(node())

    {:ok, %{}}
  end

  def handle_call({ :store_event, { client_id, payload } }, _from, state) do
    write_log(client_id, payload)

    {:reply, :ok, state}
  end

  def handle_call(_event, _from, state) do
    Logger.info("received an unexpected event")

    {:reply, :wtf, state}
  end

  defp initialize_data(:diogenes@api01) do
    [
            # client data {id, limite}
      {1, -100000},
      {2, -80000},
      {3, -1000000},
      {4, -10000000},
      {5, -500000},
    ] |> Enum.map(fn {client_id, limite} ->
      Mnesia.dirty_write({BalanceAggregate, client_id, 0, limite})
    end) |> IO.inspect() 
  end

  defp initialize_data(_), do: :ok
end
