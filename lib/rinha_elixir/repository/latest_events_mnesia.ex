defmodule RinhaElixir.Repository.LatestEventsMnesia do
  alias :mnesia, as: Mnesia

  @spec get(client_id :: integer()) :: list(map())
  def get(client_id) do
    case Mnesia.read({LatestEvents, client_id}) do
      [] ->
        []
      [{_, _client_id, latest_events}] -> 
        latest_events
    end
  end

  def dirty_get(client_id) do
    case Mnesia.dirty_read({LatestEvents, client_id}) do
      [] ->
        []
      [{_, _client_id, latest_events}] -> 
        latest_events
    end
  end

  @spec set(client_id :: integer(), transactions :: list()) :: term()
  def set(client_id, transactions) do
    Mnesia.write({LatestEvents, client_id, transactions})
  end
end
