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

    # Works exactly like mnesia:dirty_first/1 but returns the last object in Erlang term order for the ordered_set table type. For all other table types, mnesia:dirty_first/1 and mnesia:dirty_last/1 are synonyms.

    {:atomic, :ok} = Mnesia.create_table(Table, [attributes: [:id, :name], type: :bag, ram_copies: cluster_nodes()])
  end

  def do_some_writes() do
    Mnesia.dirty_write({Table, 1, "Hello world"})
    Mnesia.dirty_write({Table, 2, "WTF"})
    Mnesia.dirty_write({Table, 3, "heeeeey"})
    Mnesia.dirty_write({Table, 4, "ola mundo"})
    Mnesia.dirty_write({Table, 5, "blah blah"})
    Mnesia.dirty_write({Table, 3, "bag"})
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
