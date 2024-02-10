defmodule RinhaElixir.Tenant do
  use GenServer

  # https://elixirforum.com/t/creating-a-supervised-global-singleton-genserver/4570

  @me __MODULE__

  def start_link({client_id, saldo, limite}) do
    tenant_name = String.to_atom("client_#{client_id}")

    case GenServer.start_link(@me, {client_id, saldo, limite}, name: {:global, tenant_name}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      anything_else -> anything_else
    end
  end

  def init(data = {client_id, _saldo, _limite}) do
    # TODO:  create two tables one for balance aggregate, one for latest events
    # TODO: implement functions used in client store like append_transaction and add_saldo

    latest_events_table_name = String.to_atom("latest_events_log_tenant#{client_id}")
    balance_aggregate_table_name = String.to_atom("balance_aggregate_tenant#{client_id}")

    {:ok, %{
      me: nil,
      data: data,
      events_table: latest_events_table_name,
      balance_agg_table: balance_aggregate_table_name
    }}
  end

  def set_me(pid) when is_pid(pid) do
    GenServer.cast(pid, {:set_me, pid})
  end

  def handle_cast({:set_me, pid}, _from, state) do
    {:noreply, %{ state | me: pid }}
  end
end
