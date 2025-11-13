defmodule EPMDLess.StartNode do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
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

    Port.open({:spawn_executable, elixir}, [
      :binary,
      :stderr_to_stdout,
      args: [
        "--erl",
        "-start_epmd false -epmd_module Elixir.EPMDLess.EPMD",
        "--sname",
        "epmdless_child_#{opts[:child]}",
        "--no-halt",
        "-pa",
        epmd_module_path!(),
        "-e",
        ~s[IO.puts("ok")]
      ],
      env: [
        {~c"EPMDLESS_PARENT_NODE", to_charlist(parent_node)},
        {~c"EPMDLESS_PARENT_PORT", to_charlist(EPMDLess.EPMD.dist_port())}
      ]
    ])
  end

  defp epmd_module_path!() do
    epmd_path = Path.join(tmp_path(), "epmd")
    File.rm_rf!(epmd_path)
    File.mkdir_p!(epmd_path)
    {_module, binary, path} = :code.get_object_code(EPMDLess.EPMD)
    File.write!(Path.join(epmd_path, Path.basename(path)), binary)
    epmd_path
  end

  def tmp_path() do
    tmp_dir = System.tmp_dir!() |> Path.expand()
    Path.join([tmp_dir, "epmdless"])
  end
end
