defmodule CrdtGCounterTest do
  use ExUnit.Case

  setup do
    nodes = LocalCluster.start_nodes("counter", 3, files: [__ENV__.file])

    :rpc.multicall(nodes, Application, :ensure_all_started, [:crdt])

    {:ok, nodes: nodes}
  end

  test "can edit a gcounter", %{nodes: [node | _]} do
    test_pid = self()

    Node.spawn(node, fn ->
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      send(test_pid, {:count, Crdt.read(Crdt.GCounter)})
    end)

    assert_receive({:count, 2})
  end

  test "can synchronize between nodes", %{nodes: nodes} do
    for n <- nodes do
      Node.spawn(n, fn ->
        Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      end)
    end

    Process.sleep(200)

    test_pid = self()

    Node.spawn(hd(nodes), fn ->
      send(test_pid, {:count, Crdt.read(Crdt.GCounter)})
    end)

    assert_receive({:count, 3})
  end

  test "changes are synchronized after network failure heals", %{nodes: nodes} do
    [n1, n2, n3] = nodes

    Schism.partition([n1])
    Schism.partition([n2, n3])

    test_pid = self()

    Node.spawn(n1, fn ->
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      Process.sleep(200)
      send(test_pid, {:count_n1, Crdt.read(Crdt.GCounter)})
    end)

    Node.spawn(n2, fn ->
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      Crdt.mutate(Crdt.GCounter, :increment, [Node.self()])
      Process.sleep(200)
      send(test_pid, {:count_n2, Crdt.read(Crdt.GCounter)})
    end)

    assert_receive({:count_n1, 2}, 300)
    assert_receive({:count_n2, 2}, 300)

    Schism.heal(nodes)

    Process.sleep(200)

    Node.spawn(n1, fn ->
      send(test_pid, {:count_n1, Crdt.read(Crdt.GCounter)})
    end)

    Node.spawn(n2, fn ->
      send(test_pid, {:count_n2, Crdt.read(Crdt.GCounter)})
    end)

    assert_receive({:count_n1, 4})
    assert_receive({:count_n2, 4})
  end
end
