defmodule RinhaElixir.HttpHandlers.TransactionsHttpHandler do
  alias RinhaElixir.Repository.LatestEventsMnesia
  alias RinhaElixir.Reporitory.BalanceAggregateMnesia
  alias RinhaElixir.Bus
  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10


  def handle_transaction("c", %{ client_id: client_id, payload: payload }) do
    Bus.send_event({ :log_event, Map.put(payload, "client_id", client_id)})
    # EventLogMnesia.save(%{
    #   client_id: client_id,
    #   data: payload
    # })

    {:atomic, result} = Mnesia.transaction(fn ->
      latest_txns = LatestEventsMnesia.get(client_id)

      transaction = payload_to_transaction(payload)
      new_list = case length(latest_txns) >= @amount_txns_to_keep do
        true -> [transaction | latest_txns] |> List.delete_at(-1)
        _ -> [transaction | latest_txns]
      end

        :ok = LatestEventsMnesia.set(client_id, new_list)

        # TODO: talvez possamos voltar pra abordagem de event sourcing. Para transacoes de credito, nao há problema
        # ajustar saldo só depois
        {:ok, novo_saldo, limite} = BalanceAggregateMnesia.increment_saldo(client_id, payload["valor"])

        %{ saldo: novo_saldo, limite: -1*limite }
    end)

    {:ok, Jason.encode!(result)}
  end

  def handle_transaction("d", %{ client_id: client_id, payload: payload }) do
    Bus.send_event({ :log_event, Map.put(payload, "client_id", client_id)})
    # EventLogMnesia.save(%{
    #   client_id: client_id,
    #   data: payload
    # })

    {:atomic, result} = Mnesia.transaction(fn ->
      {:ok, saldo, limite} = BalanceAggregateMnesia.get_with_write_lock(client_id)

      case (saldo - payload["valor"]) < limite do
        true ->
          {:unprocessable, []}
        _ -> 
          latest_txns = LatestEventsMnesia.get(client_id)

          transaction = payload_to_transaction(payload)
          new_list = case length(latest_txns) >= @amount_txns_to_keep do
            true -> [transaction | latest_txns] |> List.delete_at(-1)
            _ -> [transaction | latest_txns]
          end

          :ok = LatestEventsMnesia.set(client_id, new_list)

          # TODO: maybe we can do a single set operation here since there a lock in the beggining of the function
          {:ok, novo_saldo, limite} = BalanceAggregateMnesia.increment_saldo(client_id, -1*payload["valor"])

          {:ok, Jason.encode!(%{
            saldo: novo_saldo,
            limite: -1*limite
          })}
      end
    end)

    result
  end

  def handle_transaction(_, _) do
  end

  defp payload_to_transaction(payload) do
    Map.delete(payload, "client_id")
    |> Map.put("realizada_em", DateTime.utc_now())
  end
end
