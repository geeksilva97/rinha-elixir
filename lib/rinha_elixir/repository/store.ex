defmodule RinhaElixir.Store do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

  @me {:global, __MODULE__}

  def start_link() do
    case GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      any_error -> any_error
    end
  end

  def store_event(client_id, payload) do
    GenServer.call(@me, { :store_event, { client_id, payload } })
  end

  def init(_) do
    Logger.info("Starting central Store at node #{node()}")

    Mnesia.schema()

    create_mnesia_schema()
    create_mnesia_tables()
    initialize_data()

    Logger.info("store started successfully")

    Mnesia.info()

    {:ok, %{ node: node() }}
  end

  def terminate(reason, state) do
    Logger.error("What the hell happened here? #{reason}")
  end

  def handle_call(:fodase, _from, state) do
    {:reply, "Saporra ta funcionando", state}
  end

  def handle_call({ :store_event, { client_id, payload } }, _from, state) do
    write_log(client_id, payload)

    {:reply, :ok, state}
  end

  def handle_call(_event, _from, state) do
    Logger.info("received an unexpected event")

    {:reply, :wtf, state}
  end

  defp write_log(client_id, event_data) do
    Mnesia.write({EventLog, client_id, make_ref(), 1, event_data})
  end

  defp cluster_nodes() do
    [node() | Node.list()]
  end

  defp create_mnesia_schema() do
    :rpc.multicall(cluster_nodes(), :mnesia, :stop, [])

    schema_deletion_result = Mnesia.delete_schema(cluster_nodes()) 
    schema_creation_result = Mnesia.create_schema(cluster_nodes()) 

    Logger.info("Schema deletion result #{inspect(schema_deletion_result)}")
    Logger.info("Schema creation result #{inspect(schema_creation_result)}")
  end

  def create_mnesia_tables() do
    :rpc.multicall(cluster_nodes(), :mnesia, :start, [])

    # disc tables
    {:atomic, :ok} = Mnesia.create_table(Client, [attributes: [:client_id, :limite, :saldo], type: :set, disc_copies: cluster_nodes()])
    {:atomic, :ok} = Mnesia.create_table(EventLog, [attributes: [:client_id, :event_id, :version, :event_data], type: :bag, disc_copies: cluster_nodes()])

    # memory tables
    {:atomic, :ok} = Mnesia.create_table(BalanceAggregate, [attributes: [:client_id, :saldo, :limite], type: :set, ram_copies: cluster_nodes()])
    {:atomic, :ok} = Mnesia.create_table(LatestEvents, [attributes: [:client_id, :latest_events], type: :set, ram_copies: cluster_nodes()])
  end

  defp initialize_data() do
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
end
