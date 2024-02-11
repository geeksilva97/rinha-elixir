defmodule RinhaElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias RinhaElixir.BankBalanceHandler
  require Logger

  @impl true
  def start(_type, _args) do
    System.get_env("BOOTSTRAP_NODES", "")
    |> String.split()
    |> start_cluster()

    port = System.get_env("PORT", "8080") |> :erlang.binary_to_integer()

    # nao sei pq tem que ter esse carai aqui -- nao lembro porque adicionei e nao to com paciencia pra entender porque
    # nao consigo tirar
    Process.sleep(1000)

    children = [
      {Plug.Cowboy, scheme: :http, plug: RinhaElixir.HttpHandlers.Router, port: port},
      %{
        id: RinhaElixir.Store,
        start: {RinhaElixir.Store, :start_link, []}
      },
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

  defp start_cluster([]) do
    Logger.info("No bootstrap nodes present")
  end

  defp start_cluster(node_list) do
    Logger.info("No bootstrap nodes present")
    start_cluster(node_list, max_attempts: 10, interval_ms: 1000)
  end

  defp start_cluster(node_list, [max_attempts: 0]) do
    :erlang.exit(:error, {:network_issue, "Could not connect to nodes #{inspect(node_list)}"})
  end

  defp start_cluster(node_list, options = [max_attempts: max_attempts, interval_ms: interval_ms]) do
    cluster_created = node_list |> Enum.all?(fn node_name -> Node.connect(String.to_atom(node_name)) end)

    if cluster_created do
      Logger.info("The damn cluster was created... #{inspect(Node.list())}")
      :ok
    else
      Process.sleep(interval_ms)
      start_cluster(node_list, Keyword.put(options, :max_attempts, max_attempts - 1))
    end

  end


  # def start_cluster(:diogenes@api01) do
  #   case Node.list() do
  #     [] -> Node.connect(:alexander@api02)
  #     _ -> {:ok, :already_connected}
  #   end
  # end

  # def start_cluster(:alexander@api02) do
  #   case Node.list() do
  #     [] -> Node.connect(:diogenes@api01)
  #     _ -> {:ok, :already_connected}
  #   end
  # end
end
