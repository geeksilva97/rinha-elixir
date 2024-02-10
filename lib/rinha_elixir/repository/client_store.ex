defmodule RinhaElixir.ClientStore do
  require Logger

  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10

  @spec start_link(list({id :: integer(), limite :: integer()})) :: {:ok, pid()}
  def start_link(_items) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, :rinha_fuck}
  end

  def get_saldo(id) do
    GenServer.call(__MODULE__, { :get_saldo, id })
  end

  def get_data(id) do
    GenServer.call(__MODULE__, { :get_data, id })
  end

  def add_saldo(id, valor) do
    GenServer.cast(__MODULE__, { :add_saldo, id, valor })
  end

  def subtract_saldo(id, valor) do
    GenServer.cast(__MODULE__, { :subtract_saldo, id, valor })
  end

  def append_transaction(id, transaction) do
    GenServer.cast(__MODULE__, { :append_transaction, id, transaction })
  end

  def handle_cast({:append_transaction, id, transaction}, state) do
    Logger.info("appending transaction :: Cliente [#{id}] :: #{inspect(transaction)}")

    # {:atomic, :ok} = Mnesia.transaction(fn ->
    #   [{_, _client_id, latest_events}] = Mnesia.read({LatestEvents, id})

    #   new_list = case length(latest_events) >= @amount_txns_to_keep do
    #     true -> [transaction | latest_events] |> List.delete_at(-1)
    #     _ -> [transaction | latest_events]
    #   end

    #   Mnesia.write({LatestEvents, id, new_list})
    # end)

    {:noreply, state}
  end


  def handle_cast({:subtract_saldo, id, valor}, state) do
    Logger.info("Subtraindo saldo :: cliente [#{id}]")

    {:atomic, :ok} = Mnesia.transaction(fn ->
      [{_table_name, _id, saldo, limite}] = Mnesia.read({BalanceAggregate, id})

      :ok = Mnesia.write({BalanceAggregate, id, saldo - valor, limite})
    end)

    {:noreply, state}
  end

  def handle_cast({:add_saldo, id, valor}, state) do
    Logger.info("Adicionando saldo :: cliente [#{id}]")

    {:atomic, :ok} = Mnesia.transaction(fn ->
      [{_table_name, _id, saldo, limite}] = Mnesia.read({BalanceAggregate, id})

      :ok = Mnesia.write({BalanceAggregate, id, saldo + valor, limite})
    end)

    {:noreply, state}
  end

  def handle_call({:get_data, id}, _from, state) do
    # TODO: we might wanna have a regular read here, using trasaction
    [{_, _, saldo, limite}] = Mnesia.dirty_read({BalanceAggregate, id})

    latest_txns = case Mnesia.dirty_read({LatestEvents, id}) do
      [] ->
        Logger.error("nao encontrei carai de evento aqui --  move saporra pra um modulo separado")
        []
      [{_, _client_id, latest_events}] -> 
        latest_events
    end

    Logger.info("Found this damn data :: #{inspect(%{ saldo: saldo, limite: limite })}")

    {:reply, %{
      saldo: saldo,
      limite: limite,
      latest_transactions: latest_txns
    }, state}
  end

  def handle_call({:get_saldo, id}, _from, state) do
    {:reply, :tava_esperando_saldo_aqui, state}
  end

  def handle_call(_event, _from, state) do
    Logger.error("unexpected call")

    {:reply, :noop, state}
  end
end
