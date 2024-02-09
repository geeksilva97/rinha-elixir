defmodule RinhaElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias RinhaElixir.BankBalanceHandler
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting the application :: I am the node #{inspect(node())} / Cookie -> #{inspect(Node.get_cookie())}")

    Logger.info("Starting cluster")

    # TODO: Gotta add some retires here... just in case
    cluster_result = start_cluster(node())

    Logger.info("Clustering result #{inspect(cluster_result)}")

    Logger.info("Cluster: #{inspect([node() | Node.list()])}")

    port = System.get_env("PORT", "8080") |> :erlang.binary_to_integer()

    children = [
      {Plug.Cowboy, scheme: :http, plug: RinhaElixir.HttpHandlers.Router, port: port},
      RinhaElixir.Store,
      %{
        id: RinhaElixir.ClientStore,
        start: {RinhaElixir.ClientStore, :start_link, [
          [
            # client data {id, limite}
            {1, -100000},
            {2, -80000},
            {3, -1000000},
            {4, -10000000},
            {5, -500000},
          ]
        ]}
      },
      %{
        id: RinhaElixir.Bus,
        start: {RinhaElixir.Bus, :start_link, [[{BankBalanceHandler, []}]]}
      }
    ]

    opts = [strategy: :one_for_one, name: RinhaElixir.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def start_cluster(:diogenes@api01) do
    case Node.list() do
      [] -> Node.connect(:alexander@api02)
      _ -> {:ok, :already_connected}
    end
  end

  def start_cluster(:alexander@api02) do
    case Node.list() do
      [] -> Node.connect(:diogenes@api01)
      _ -> {:ok, :already_connected}
    end
  end
end
