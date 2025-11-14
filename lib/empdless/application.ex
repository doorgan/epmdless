defmodule EPMDLess.Application do
  use Application

  def start(_type, _args) do
    set_epmd_module!()
    start_distribution!()

    children = [{EPMDLess.NodePortMapper, []}]
    opts = [strategy: :one_for_one, name: EPMDLess.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = result ->
        result

      {:error, error} ->
        abort!(inspect(error))
    end
  end

  defp set_epmd_module!() do
    # We use a custom EPMD module. In releases and Escript, we make
    # sure the necessary erl flags are set. When running from source,
    # we try to use the new :kernel configuration available in OTP 27.2,
    # otherwise it needs to be set explicitly.

    # TODO: always rely on :kernel configuration once we require OTP 27.2

    case :init.get_argument(:epmd_module) do
      {:ok, [[~c"Elixir.EPMDLess.EPMD"]]} ->
        :ok

      _ ->
        Application.put_env(:kernel, :epmd_module, EPMDLess.EPMD, persistent: true)

        # Note: this is a private API
        if :net_kernel.epmd_module() != EPMDLess.EPMD do
          abort!("""
          You must set the environment variable ELIXIR_ERL_OPTIONS="-epmd_module Elixir.EPMDLess.EPMD" \
          before the command (and exclusively before the command)
          """)
        end
    end
  end

  defp start_distribution!() do
    # Not IPV6 safe
    node = :"epmdless_parent_epmdless@127.0.0.1"
    case Node.start(node, :longnames) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        abort!("Could not start distributed node: #{inspect(reason)}")
    end
  end

  defp abort!(message) do
    IO.puts("\nERROR!!! [EPMDLess] " <> message)
    System.halt(1)
  end
end
