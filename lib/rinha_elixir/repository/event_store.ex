defmodule RinhaElixir.Repository.EventStore do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, %{}}
  end

  def append_event(client_id, event) do
    GenServer.cast(__MODULE__, {:append_event, %{client_id: client_id, event: event}})
  end

  def handle_cast({:append_event, %{client_id: client_id, event: event}}, state) do
    events = state[client_id] || []
    new_state = Map.put(state, client_id, [event | events])

    {:noreply, new_state}
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end
end
