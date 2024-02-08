defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router

  # https://hexdocs.pm/plug/1.3.6/Plug.Conn.html#read_body/2

  plug(:match)
  plug(:dispatch)
  plug(:check_client_id)

  get "/clientes/:client_id/extrato" do
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{limite: 0, saldo: 0}))
  end

  post "/clientes/:client_id/transacoes" do
    {:ok, raw_body, _} = read_body(conn)
    %{"tipo" => tipo, "valor" => valor, "descricao" => descricao} = Jason.decode!(raw_body)

    # TODO: atach event
    # TODO: read saldo summary

    send_resp(conn, 200, "Creating transaction for client :: #{client_id}")
  end

  defp check_client_id(conn, _) do
    client_id = conn.params["client_id"] |> :erlang.binary_to_integer()

    unless client_id in 1..5 do
      send_resp(conn, 404, [])
    else
      conn
    end
  end
end
