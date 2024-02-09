defmodule RinhaElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias RinhaElixir.BankBalanceHandler
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: RinhaElixir.HttpHandlers.Router, port: 8080},
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

    Logger.info("Starting the application")

    Supervisor.start_link(children, opts)
  end
end
