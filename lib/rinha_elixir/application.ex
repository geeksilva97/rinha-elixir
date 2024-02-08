defmodule RinhaElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: RinhaElixir.HttpHandlers.Router, port: 8080}
    ]

    opts = [strategy: :one_for_one, name: RinhaElixir.Supervisor]

    Logger.info("Starting the application")

    Supervisor.start_link(children, opts)
  end
end
