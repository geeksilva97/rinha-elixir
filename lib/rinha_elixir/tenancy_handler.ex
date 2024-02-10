defmodule RinhaElixir.TenancyHandler do
  use GenServer

  @me __MODULE__

  def start_link() do
    GenServer.start_link(@me, [], name: @me)
  end

  def init(_) do
    {:ok, %{}}
  end

  def add_tenant(id, initial_data = {_saldo, _limite}) do
    GenServer.cast(@me, {:add_tenant, id, initial_data})
  end

  def handle_cast({:add_tenant, tenant_id, { saldo, limite }}, state) do
    case Map.has_key?(state, tenant_id) do
      true ->
        {:noreply, state}
        _ >
        {:ok, pid} = GenServer.start_link(Tenant, {tenant_id, saldo, limite})

        {:noreply, Map.put(state, tenant_id, pid)}
    end
  end
end
