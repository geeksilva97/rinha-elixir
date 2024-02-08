defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router
  alias RinhaElixir.Bus

  # https://hexdocs.pm/plug/1.3.6/Plug.Conn.html#read_body/2

  plug(:match)
  plug(:dispatch)
  plug(:check_client_id)

  get "/clientes/:client_id/extrato" do
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
        saldo: %{
          total: 0,
          data_extrato: "",
          limit: 0
        },
        ultimas_transacoes: []
      })
    )
  end

  post "/clientes/:client_id/transacoes" do
    {:ok, raw_body, _} = read_body(conn)
    payload = Jason.decode!(raw_body)

    Bus.send_event({:log_event, payload})
    # TODO: read saldo summary

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{limite: 0, saldo: 0}))
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
