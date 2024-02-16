defmodule RinhaElixir.TenancySupervisor do
  use Supervisor

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [1, 2, 3, 4, 5] |> Enum.map(fn client_id -> 
      %{
        id: RinhaElixir.Tenant.tenant_name(client_id),
        start: {RinhaElixir.Tenant, :start_link, [client_id]}
      }
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
