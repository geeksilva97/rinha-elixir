defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router
  alias RinhaElixir.Bus
  alias RinhaElixir.ClientStore
  require Logger

  # https://hexdocs.pm/plug/1.3.6/Plug.Conn.html#read_body/2

  plug(:match)
  plug(:dispatch)
  plug(:check_client_id)

  get "/clientes/:client_id/extrato" do
    # TODO: remove this info shit
    :mnesia.info()
    client_id = client_id |> :erlang.binary_to_integer()
    %{ limite: limite, saldo: saldo, latest_transactions: latest_transactions } = ClientStore.get_data(client_id)

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
        saldo: %{
          total: saldo,
          data_extrato: DateTime.utc_now(),
          limite: limite
        },
        ultimas_transacoes: latest_transactions
      })
    )
  end

  post "/clientes/:client_id/transacoes" do
    {:ok, raw_body, _} = read_body(conn)
    payload = Jason.decode!(raw_body)
    client_id = client_id |> :erlang.binary_to_integer()
    tipo = payload[ "tipo"]
    valor = payload["valor"]

    case tipo do
      "c" ->
        Bus.send_event({:log_event, Map.put(payload, "client_id", client_id)})

        %{ limite: limite, saldo: saldo_atual } = ClientStore.get_data(client_id)

        ClientStore.add_saldo(client_id, valor)

        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(200, Jason.encode!(%{limite: limite, saldo: saldo_atual + valor }))

      "d" ->
        %{ limite: limite, saldo: saldo_atual } = ClientStore.get_data(client_id)

        if (saldo_atual - valor) < limite do
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(422, [])
        else
          Bus.send_event({:log_event, Map.put(payload, "client_id", client_id)})
          ClientStore.subtract_saldo(client_id, valor)

          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(200, Jason.encode!(%{limite: limite, saldo: saldo_atual - valor }))
        end

      _ ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(422, [])

    end
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
