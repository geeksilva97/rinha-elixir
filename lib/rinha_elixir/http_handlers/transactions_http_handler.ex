defmodule RinhaElixir.HttpHandlers.TransactionsHttpHandler do
  alias RinhaElixir.Repository.LatestEventsMnesia
  alias RinhaElixir.Reporitory.BalanceAggregateMnesia
  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10


  def handle_transaction("c", %{ client_id: client_id, payload: payload }) do
    {:atomic, result} = Mnesia.sync_transaction(fn ->
      latest_txns = LatestEventsMnesia.get(client_id)

      transaction = payload_to_transaction(payload)
      new_list = case length(latest_txns) >= @amount_txns_to_keep do
        true -> [transaction | latest_txns] |> List.delete_at(-1)
        _ -> [transaction | latest_txns]
      end

        :ok = LatestEventsMnesia.set(client_id, new_list)

        {:ok, novo_saldo, limite} = BalanceAggregateMnesia.increment_saldo(client_id, payload["valor"])

        %{ saldo: novo_saldo, limite: -1*limite }
    end)

    {:ok, Jason.encode!(result)}
  end

  def handle_transaction("d", %{ client_id: _client_id, payload: _payload }) do
  end

  def handle_transaction(_, _) do
  end

  defp payload_to_transaction(payload) do
    Map.delete(payload, "client_id")
    |> Map.put("realizada_em", DateTime.utc_now())
  end
end
