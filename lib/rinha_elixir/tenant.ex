defmodule RinhaElixir.Tenant do
  use GenServer

  require Logger

  def start_link(client_id) do
    Logger.info("Starting tenant #{client_id}")
    GenServer.start_link(__MODULE__, :init_arg, name: tenant_name(client_id))
  end

  def init(_) do
    {:ok, nil}
  end

  def tenant_name(client_id), do: String.to_atom("tenant#{client_id}")
end
