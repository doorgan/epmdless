defmodule EpmdlessTest do
  use ExUnit.Case
  doctest Epmdless

  test "starts node with custom epmd" do
    {:ok, hostname} = :inet.gethostname()
    {:ok, _pid} = EPMDLess.Store.start_link()
    {:ok, _pid} = EPMDLess.StartNode.start_link(parent: "foo", child: "bar")
    child_node = :"epmdless_child_bar@#{hostname}"

    Process.sleep(1000)

    assert Node.ping(child_node) == :pong

    pid = GenServer.whereis(EPMDLess.Store.name())

    assert Process.alive?(pid)

    assert EPMDLess.Store.name() ==
      :erpc.call(child_node, EPMDLess.Store, :name, [])

    assert "Hello from child node!" ==
             :erpc.call(child_node, EPMDLess.Store, :put, [
               :key1,
               "Hello from child node!"
             ])
  end
end
