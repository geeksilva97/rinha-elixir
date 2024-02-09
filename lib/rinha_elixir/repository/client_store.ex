defmodule RinhaElixir.ClientStore do
  require Logger

  @spec start_link(list({id :: integer(), limite :: integer()})) :: {:ok, pid()}
  def start_link(items) do
    {_, state_map} = items |> Enum.map_reduce(%{}, fn {id, limite}, acc -> { nil, Map.put(acc, id, %{limite: limite, saldo: 0})} end)

    GenServer.start_link(__MODULE__, state_map, name: __MODULE__)
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

  def init(state) do
    Logger.info("#{inspect(state)}")

    {:ok, state}
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
    {:reply, state[id], state}
  end

  def handle_call({:get_saldo, id}, _from, state) do
    {:reply, state[id].saldo, state}
  end

  def handle_call(_event, _from, state) do
    Logger.error("unexpected call")

    {:reply, :noop, state}
  end
end
