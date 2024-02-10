defmodule RinhaElixir.Repository.LatestEventsMnesia do
  alias :mnesia, as: Mnesia

  @spect get(client_id :: integer()) :: list(map())
  def get(client_id) do
    case Mnesia.read({LatestEvents, client_id}) do
      [] ->
        []
      [{_, _client_id, latest_events}] -> 
        latest_events
    end
  end
end
