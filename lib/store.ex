defmodule EPMDLess.Store do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: name())
  end

  def name() do
    {:global, __MODULE__}
  end

  def get(key) do
    GenServer.call(name(), {:get, key})
  end

  def put(key, value) do
    GenServer.call(name(), {:put, key, value})
  end

  # Server (callbacks)
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    new_state = Map.put(state, key, value)
    {:reply, :ok, new_state}
  end
end
