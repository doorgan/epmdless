defmodule EpmdlessTest do
  use ExUnit.Case
  doctest Epmdless

  test "starts node with custom epmd" do
    {:ok, _pid} = EPMDLess.StartNode.start_link(parent: "foo", child: "bar")
    {:ok, _pid} = EPMDLess.Store.start_link()
    child_node = :"epmdless_child_bar@macbook"

    Process.sleep(1000)

    assert Node.ping(child_node) == :pong

    pid = GenServer.whereis(EPMDLess.Store.name())

    assert Process.alive?(pid)

    assert EPMDLess.Store.name() ==
             :erpc.call(child_node, EPMDLess.Store, :name, [])

    assert :ok ==
             :erpc.call(child_node, EPMDLess.Store, :put, [
               :key1,
               "Hello from child node!"
             ])

    assert "Hello from child node!" ==
             :erpc.call(child_node, EPMDLess.Store, :get, [:key1])
  end
end
