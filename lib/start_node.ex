defmodule EPMDLess.StartNode do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl GenServer
  def init(opts) do
    :net_kernel.start(:"epmdless_parent_#{opts[:parent]}", %{name_domain: :shortnames})
    port = start_node(opts)
    {:ok, port}
  end

  @impl GenServer
  def handle_info({_port, {:data, data}}, state) do
    IO.puts("Received from child node: #{data}")
    {:noreply, state}
  end

  def start_node(opts) do
    parent_node = node()
    elixir = System.find_executable("elixir")

    beams_path = Path.join(tmp_path(), "epmd")

    prepare_module(EPMDLess.EPMD, beams_path)
    prepare_module(EPMDLess.NodePortMapper, beams_path)
    prepare_module(EPMDLess.Store, beams_path)

    Port.open({:spawn_executable, elixir}, [
      :binary,
      :stderr_to_stdout,
      args: [
        "--erl",
        "-start_epmd false -epmd_module Elixir.EPMDLess.EPMD",
        "--no-halt",
        "-pa",
        beams_path,
        "-e",
        """
        Node.start(:epmdless_child_#{opts[:child]}, :shortnames);
        EPMDLess.NodePortMapper.register();
        IO.puts("ok");
        """
      ],
      env: [
        {~c"EPMDLESS_PARENT_NODE", to_charlist(parent_node)},
        {~c"EPMDLESS_PARENT_PORT", to_charlist(EPMDLess.EPMD.dist_port())}
      ]
    ])
  end

  def prepare_module(module, dest_path) do
    File.mkdir_p!(dest_path)
    {_module, binary, path} = :code.get_object_code(module)
    File.write!(Path.join(dest_path, Path.basename(path)), binary)
  end

  def tmp_path() do
    tmp_dir = System.tmp_dir!() |> Path.expand()
    Path.join([tmp_dir, "epmdless"])
  end
end
