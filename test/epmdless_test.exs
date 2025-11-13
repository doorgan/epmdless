defmodule EpmdlessTest do
  use ExUnit.Case
  doctest Epmdless


  test "starts node with custom epmd" do
    {:ok, hostname} = :inet.gethostname()
    {:ok, _pid} = EPMDLess.StartNode.start_link([parent: "foo", child: "bar"])

    Process.sleep(1000)

    assert Node.ping(:"epmdless_child_bar@#{hostname}") == :pong
  end
end
