defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router
  alias RinhaElixir.Bus
  alias RinhaElixir.ClientStore
  require Logger
  alias RinhaElixir.Reporitory.BalanceAggregateMnesia
  alias RinhaElixir.HttpHandlers.TransactionsHttpHandler
  alias RinhaElixir.Repository.LatestEventsMnesia

  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10

  # https://hexdocs.pm/plug/1.3.6/Plug.Conn.html#read_body/2

  plug(:match)
  plug(:check_client_id)
  plug(:dispatch)

  get "/clientes/:client_id/extrato" do
    client_id = client_id |> :erlang.binary_to_integer()
    {:atomic, { saldo, limite, latest_transactions }} = Mnesia.sync_transaction(fn ->
      {:ok, saldo, limite} = BalanceAggregateMnesia.get_with_write_lock(client_id)
      latest_events = LatestEventsMnesia.get(client_id)

      {saldo, limite, latest_events}
    end)

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
        saldo: %{
          total: saldo,
          data_extrato: DateTime.utc_now(),
          limite: -1*limite
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
    valor = payload["valor"] || 0
    descricao = payload["descricao"] || ""
    size_descricao = String.length(descricao)

    unless is_float(valor) or valor <= 0 or size_descricao == 0 or size_descricao > 10 do
      result = TransactionsHttpHandler.handle_transaction(tipo, %{ client_id: client_id, payload: payload })

      case result do
        {:ok, content} ->
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(200, content)

        {:unprocessable, content} ->
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(422, content)

        _ ->
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(422, [])
      end

      else
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(422, [])
    end

  end

  defp check_client_id(conn, _) do
    client_id = conn.params["client_id"] |> :erlang.binary_to_integer()


    unless client_id in 1..5 do
      send_resp(conn, 404, []) |> halt()
    else
      conn
    end
  end
end
