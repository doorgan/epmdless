defmodule EPMDLess.StoreTest do
  use ExUnit.Case, async: true

  alias EPMDLess.Store

  setup do
    {:ok, _pid} = Store.start_link()
    :ok
  end

  test "put and get operations" do
    assert :ok == Store.put(:key1, "value1")
    assert "value1" == Store.get(:key1)
  end
end
