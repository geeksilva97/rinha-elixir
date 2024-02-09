defmodule MnesiaDemo do
  alias :mnesia, as: Mnesia

  def run do
    node_name = System.get_env("NODE_NAME", nil) |> String.to_atom()

    unless is_nil(node_name) do
      IO.puts(:"Connecting to node #{node_name}")

      Node.connect(node_name)

      IO.inspect(Node.list())
    end

    # TODO: multicall

  end

  def cluster_nodes() do
    [node() | Node.list()]
  end

  def create_mnesia_schema() do
    IO.puts("Node #{inspect(node())} creating schema")
    Mnesia.delete_schema([node() | Node.list()])
    Mnesia.create_schema([node() | Node.list()])

    # Mnesia.start()
    :rpc.multicall(cluster_nodes(), :mnesia, :start, [])

    {:atomic, :ok} = Mnesia.create_table(Table, [attributes: [:id, :name], ram_copies: cluster_nodes()])
  end

  def do_some_writes() do
    Mnesia.dirty_write({Table, 1, "Hello world"})
    Mnesia.dirty_write({Table, 2, "WTF"})
  end

  def do_some_reads_in_the_other_node() do
    [other_node] = Node.list()


    :rpc.call(other_node, MnesiaDemo, :dirty_read, [1])
  end

  def dirty_read(id) do
    IO.puts("Node :: #{inspect(node())} is performin a dirty_read")

    Mnesia.dirty_read({Table, id})
  end
end
