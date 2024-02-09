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
    new_client_state = state[id] |> Map.update(:latest_transactions, 0, fn curr ->
      new_list = [transaction | curr]


      case length(new_list) > @amount_txns_to_keep do
        true -> new_list |> List.delete_at(-1)
        _ -> new_list
      end
    end)

    Logger.info("appending transaction :: #{inspect(new_client_state)}")

    {:noreply, Map.put(state, id, new_client_state)}
  end


  def handle_cast({:subtract_saldo, id, valor}, state) do
    new_client_state = state[id] |> Map.update(:saldo, 0, fn curr -> curr - valor end)

    {:noreply, Map.put(state, id, new_client_state)}
  end

  def handle_cast({:add_saldo, id, valor}, state) do
    new_client_state = state[id] |> Map.update(:saldo, 0, fn curr -> curr + valor end)

    {:noreply, Map.put(state, id, new_client_state)}
  end

  def handle_call({:get_data, id}, _from, state) do
    # TODO: we might wanna have a regular read here, using trasaction
    [{_, _, saldo, limite}] = Mnesia.dirty_read({BalanceAggregate, id})

    Logger.info("Found this damn data :: #{inspect(%{ saldo: saldo, limite: limite })}")

    {:reply, %{
      saldo: saldo,
      limite: limite,
      latest_transactions: []
    }, state}
  end

  def handle_call({:get_saldo, id}, _from, state) do
    {:reply, state[id].saldo, state}
  end

  def handle_call(_event, _from, state) do
    Logger.error("unexpected call")

    {:reply, :noop, state}
  end
end
