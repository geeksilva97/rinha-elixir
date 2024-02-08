defmodule RinhaElixir.Bus do
  require Logger

  def start_link(handlers) when is_list(handlers) do
    Logger.info("Bus started :: it is up #{inspect(self())}")
    :gen_event.start_link({:local, __MODULE__})

    Logger.info("Initializing handlers")

    init_handlers(handlers)

    Logger.info("handlers are up")

    {:ok, self()}
  end

  def add_handler(handler, args) do
    :gen_event.add_handler(__MODULE__, handler, args)
  end

  def delete_handler(handler, args) do
    :gen_event.delete_handler(__MODULE__, handler, args)
  end

  def send_event(event) do
    :gen_event.notify(__MODULE__, event)
  end

  defp init_handlers([]) do
    :ok
  end

  defp init_handlers([{handler, args} | tail]) do
    add_handler(handler, args)

    init_handlers(tail)
  end
end
