defmodule RinhaElixir.Tenant do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

  @amount_txns_to_keep 10

  def start_link({client_id, limit}) do
    Logger.info("Starting tenant #{client_id}")

    case GenServer.start_link(__MODULE__, {client_id, limit}, name: {:global, tenant_name(client_id)}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      any_error -> any_error
    end
  end

  def init({client_id, limit}) do
    event_table = String.to_atom("event_log#{client_id}")
    balance_table = String.to_atom("balance#{client_id}")

    # Mnesia.start()

    # {:atomic, :ok} = Mnesia.create_table(balance_table, [attributes: [:client_id, :saldo, :limite], type: :set, ram_copies: cluster_nodes()])
    # {:atomic, :ok} = Mnesia.create_table(event_table, [attributes: [:client_id, :latest_events], type: :set, ram_copies: cluster_nodes()])

    # :ok = Mnesia.dirty_write({balance_table, client_id, 0, limit})

    {:ok, %{events: [], balance: 0, limit: limit}}
  end

  def credit(client_id, payload) do
    GenServer.call({:global, tenant_name(client_id)}, {:credit, client_id, payload})
  end

  def debit(client_id, payload) do
    GenServer.call({:global, tenant_name(client_id)}, {:debit, client_id, payload})
  end

  def summary(client_id) do
    GenServer.call({:global, tenant_name(client_id)}, {:summary, client_id})
  end

  def tenant_name(client_id), do: String.to_atom("tenant#{client_id}")

  def handle_call({:summary, client_id}, _from, state = %{events: latest_txns, balance: balance, limit: limit}) do
    {:reply, {:ok, balance, limit, latest_txns}, state}
  end

  def handle_call({:credit, client_id, payload}, _from, state = %{events: latest_txns, balance: balance, limit: limit}) do
    transaction = payload_to_transaction(payload)

      # latest_txns = latest_events(events_table, client_id)

      new_list = case length(latest_txns) >= @amount_txns_to_keep do
        true -> [transaction | latest_txns] |> List.delete_at(-1)
        _ -> [transaction | latest_txns]
      end

        # :ok = Mnesia.dirty_write({events_table, client_id, new_list})

        # [{_, _, balance, limit}] = Mnesia.dirty_read({balance_table, client_id})

        new_balance = balance + transaction["valor"]

        # Mnesia.dirty_write({balance_table, client_id, new_balance, limit})

    {:reply, {:ok, new_balance, limit}, %{ state | events: new_list, balance: new_balance }}
  end

  def handle_call({:debit, client_id, payload}, _from, state = %{events: latest_txns, balance: balance, limit: limit}) do
    # [{_, _, balance, limit}] = Mnesia.dirty_read({balance_table, client_id})
    new_balance = balance - payload["valor"]

      case new_balance < limit do
        true ->
          {:reply, {:unprocessable, balance, limit}, state}
        _ -> 
          # latest_txns = latest_events(events_table, client_id)

          transaction = payload_to_transaction(payload)
          new_list = case length(latest_txns) >= @amount_txns_to_keep do
            true -> [transaction | latest_txns] |> List.delete_at(-1)
            _ -> [transaction | latest_txns]
          end

          # :ok = Mnesia.dirty_write({events_table, client_id, new_list})

          # Mnesia.dirty_write({balance_table, client_id, new_balance, limit})

          {:reply, {:ok, new_balance, limit}, %{ state | events: new_list, balance: new_balance }}
      end
  end

  defp cluster_nodes(), do: [node()]

  defp latest_events(table, client_id) do
    case Mnesia.dirty_read({table, client_id}) do
      [] ->
        []
      [{_, _client_id, latest_events}] -> 
        latest_events
    end
  end

  defp payload_to_transaction(payload) do
    Map.delete(payload, "client_id")
    |> Map.put("realizada_em", DateTime.utc_now())
  end
end
