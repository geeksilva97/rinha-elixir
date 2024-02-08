defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/clientes/:client_id/extrato" do
    send_resp(conn, 200, "Extrato #{client_id}")
  end

  post "/clientes/:client_id/transacoes" do
    send_resp(conn, 200, "Creating transaction for client :: #{client_id}")
  end
end
