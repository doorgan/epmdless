defmodule EPMDLess.EPMD do
  @moduledoc false

  # From Erlang/OTP 23+
  @epmd_dist_version 6

  @doc ~S"""
  This is the distribution port of the current node.

  The parent node must be named `epmdless_parent_*`.
  The child node must be named `epmdless_child_*`.

  When the parent boots the child, it must pass
  its node name and port as the respective environment
  variables `EPMDLESS_PARENT_NODE` and `EPMDLESS_PARENT_PORT`.

  The parent must have this as a child in its supervision tree:

      {EPMDLess.NodePortMapper, []}

  The child, in turn, must have this:

      {Task, &EPMDLess.NodePortMapper.register/0}

  This will register the child within the parent, so they can
  find each other.

  ## Example

  In order to manually simulate the connections, run `elixirc epmd.ex` to compile
  this file and follow the steps below. Notice we call the functions in the
  `EPMDLess.NodePortMapper` module directly, while in practice they will be called
  as part of the app's supervision tree.

      # In one node
      $ iex --erl "-start_epmd false -epmd_module Elixir.EPMDLess.EPMD" --sname epmdless_parent_foo
      iex(epmdless_parent_foo@macstudio)> EPMDLess.NodePortMapper.start_link([])
      iex(epmdless_parent_foo@macstudio)> EPMDLess.EPMD.dist_port()
      52914

  Get the port name from the step above and then, in another terminal, do:

      $ EPMDLESS_PARENT_NODE=epmdless_parent_foo@HOSTNAME EPMDLESS_PARENT_PORT=52914 \
          iex --erl "-start_epmd false -epmd_module Elixir.EPMDLess.EPMD" --sname epmdless_child_bar
      iex> EPMDLess.NodePortMapper.register()

  And in another terminal:

      $ EPMDLESS_PARENT_NODE=epmdless_parent_foo@HOSTNAME EPMDLESS_PARENT_PORT=52914 \
          iex --erl "-start_epmd false -epmd_module Elixir.EPMDLess.EPMD -epmdless_port 52914" --sname epmdless_child_baz
      iex> EPMDLess.NodePortMapper.register()

  If you try `Node.ping(:epmdless_child_bar@HOSTNAME)` from the last node, it should work.
  The child nodes will find each other even without EPMD.
  """
  def dist_port do
    :persistent_term.get(:epmdless_dist_port, nil)
  end

  # EPMD callbacks

  def register_node(name, port), do: register_node(name, port, :inet)

  def register_node(name, port, family) do
    :persistent_term.put(:epmdless_dist_port, port)

    # We don't care if EPMD is not running
    case :erl_epmd.register_node(name, port, family) do
      {:error, _} -> {:ok, -1}
      {:ok, _} = ok -> ok
    end
  end

  def port_please(name, host), do: port_please(name, host, :infinity)

  def port_please(~c"epmdless_parent_" ++ _ = name, host, timeout) do
    if port = System.get_env("EPMDLESS_PARENT_PORT") do
      {:port, String.to_integer(port), @epmd_dist_version}
    else
      :erl_epmd.port_please(name, host, timeout)
    end
  end

  def port_please(~c"epmdless_child_" ++ _ = name, host, timeout) do
    if port = EPMDLess.NodePortMapper.get_port(List.to_atom(name)) do
      {:port, port, @epmd_dist_version}
    else
      :erl_epmd.port_please(name, host, timeout)
    end
  end

  def port_please(name, host, timeout) do
    :erl_epmd.port_please(name, host, timeout)
  end

  defdelegate start_link(), to: :erl_epmd
  defdelegate listen_port_please(name, host), to: :erl_epmd
  defdelegate address_please(name, host, family), to: :erl_epmd
  defdelegate names(host_name), to: :erl_epmd
end

