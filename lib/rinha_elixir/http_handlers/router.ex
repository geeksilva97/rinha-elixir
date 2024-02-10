defmodule RinhaElixir.HttpHandlers.Router do
  use Plug.Router
  alias RinhaElixir.Bus
  alias RinhaElixir.ClientStore
  require Logger
  alias RinhaElixir.Reporitory.BalanceAggregateMnesia
  alias RinhaElixir.HttpHandlers.TransactionsHttpHandler

  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10

  # https://hexdocs.pm/plug/1.3.6/Plug.Conn.html#read_body/2

  plug(:match)
  plug(:check_client_id)
  plug(:dispatch)

  get "/clientes/:client_id/extrato" do
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
    valor = payload["valor"]

    result = TransactionsHttpHandler.handle_transaction(tipo, %{ client_id: client_id, payload: payload })

    case result do
      {:ok, content} ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(200, content)

      {:unprocessable, _} ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(422, [])

      _ ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(422, [])
    end
  end

  # post "/clientes/:client_id/transacoes" do
  #   {:ok, raw_body, _} = read_body(conn)

  #   payload = Jason.decode!(raw_body)
  #   client_id = client_id |> :erlang.binary_to_integer()
  #   tipo = payload[ "tipo"]
  #   valor = payload["valor"]

  #   case tipo do
  #     "c" ->
  #       {:atomic, result} = Mnesia.sync_transaction(fn ->
  #         [{_, _, saldo, limite}] = Mnesia.read({BalanceAggregate, client_id})

  #         latest_txns = case Mnesia.read({LatestEvents, client_id}) do
  #           [] ->
  #             []
  #           [{_, _client_id, latest_events}] -> 
  #             latest_events
  #         end

  #           Logger.info("Latest bla: #{inspect(latest_txns)}")

  #         novo_saldo = saldo + valor

  #         :ok = Mnesia.write({BalanceAggregate, client_id, novo_saldo, limite})

  #         transaction = Map.delete(payload, "client_id") |> Map.put("realizada_em", DateTime.utc_now())

  #           new_list = case length(latest_txns) >= @amount_txns_to_keep do
  #             true -> [transaction | latest_txns] |> List.delete_at(-1)
  #             _ -> [transaction | latest_txns]
  #           end

  #           :ok = Mnesia.write({LatestEvents, client_id, new_list})

  #         %{saldo: novo_saldo, limite: limite}
  #       end)

  #       conn
  #       |> put_resp_header("Content-Type", "application/json")
  #       |> send_resp(200, Jason.encode!(result))

  #     "d" ->
  #     {:atomic, result} = Mnesia.sync_transaction(fn ->
  #       [{_, _, saldo, limite}] = Mnesia.read({BalanceAggregate, client_id})

  #       latest_txns = case Mnesia.read({LatestEvents, client_id}) do
  #         [] ->
  #           []
  #         [{_, _client_id, latest_events}] -> 
  #           latest_events
  #       end

  #         novo_saldo = saldo - valor

  #         if novo_saldo < limite do
  #           conn
  #           |> put_resp_header("Content-Type", "application/json")
  #           |> send_resp(422, [])
  #         else
  #           :ok = Mnesia.write({BalanceAggregate, client_id, novo_saldo, limite})

  #           transaction = Map.delete(payload, "client_id") |> Map.put("realizada_em", DateTime.utc_now())

  #           new_list = case length(latest_txns) >= @amount_txns_to_keep do
  #             true -> [transaction | latest_txns] |> List.delete_at(-1)
  #             _ -> [transaction | latest_txns]
  #           end

  #             :ok = Mnesia.write({LatestEvents, client_id, new_list})

  #             conn
  #             |> put_resp_header("Content-Type", "application/json")
  #             |> send_resp(200, Jason.encode!(%{limite: -1*limite, saldo: novo_saldo }))
  #         end
  #     end)


  #     result

  #     _ ->
  #       conn
  #       |> put_resp_header("Content-Type", "application/json")
  #       |> send_resp(422, [])

  #   end
  # end

  defp check_client_id(conn, _) do
    client_id = conn.params["client_id"] |> :erlang.binary_to_integer()

    unless client_id in 1..5 do
      send_resp(conn, 404, []) |> halt()
    else
      conn
    end
  end
end
