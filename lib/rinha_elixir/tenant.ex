defmodule RinhaElixir.Tenant do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

  def start_link(client_id) do
    Logger.info("Starting tenant #{client_id}")

    case GenServer.start_link(__MODULE__, client_id, name: {:global, tenant_name(client_id)}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      any_error -> any_error
    end
  end

  def init(client_id) do
    event_table = String.to_atom("event_log#{client_id}")
    balance_table = String.to_atom("balance#{client_id}")

    {:atomic, :ok} = Mnesia.create_table(balance_table, [attributes: [:client_id, :saldo, :limite], type: :set, ram_copies: cluster_nodes()])
    {:atomic, :ok} = Mnesia.create_table(event_table, [attributes: [:client_id, :latest_events], type: :set, ram_copies: cluster_nodes()])

    {:ok, nil}
  end

  def tenant_name(client_id), do: String.to_atom("tenant#{client_id}")

  defp cluster_nodes(), do: [node()]
end
