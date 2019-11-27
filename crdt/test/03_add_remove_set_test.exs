defmodule CrdtAddRemoveTest do
  use ExUnit.Case

  setup do
    nodes = LocalCluster.start_nodes("add_remove", 3, files: [__ENV__.file])

    :rpc.multicall(nodes, Application, :ensure_all_started, [:crdt])

    {:ok, nodes: nodes}
  end

  test "can add to an add-remove set", %{nodes: [node | _]} do
    test_pid = self()

    Node.spawn(node, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Elixir"])
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Erlang"])
      send(test_pid, {:set, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set, languages})
    assert Enum.sort(["Elixir", "Erlang"]) == Enum.sort(languages)
  end

  test "can remove from an add-remove set", %{nodes: [node | _]} do
    test_pid = self()

    Node.spawn(node, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Kotlin"])
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["ObjectiveC"])
      Crdt.mutate(Crdt.AddRemoveSet, :remove, ["ObjectiveC"])
      send(test_pid, {:set, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set, languages})
    assert Enum.sort(["Kotlin"]) == Enum.sort(languages)
  end

  test "can synchronize between nodes", %{nodes: nodes} do
    for n <- nodes do
      Node.spawn(n, fn ->
        Crdt.mutate(Crdt.AddRemoveSet, :add, ["Ruby"])
        Crdt.mutate(Crdt.AddRemoveSet, :add, ["Python"])
        Crdt.mutate(Crdt.AddRemoveSet, :remove, ["Python"])
      end)
    end

    Process.sleep(200)

    test_pid = self()

    Node.spawn(hd(nodes), fn ->
      send(test_pid, {:set, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set, ["Ruby"]})
  end

  test "can synchronize between nodes pt II", %{nodes: nodes} do
    [n1, n2, n3] = nodes

    Node.spawn(n1, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["C"])
      Crdt.mutate(Crdt.AddRemoveSet, :remove, ["B"])
    end)

    Node.spawn(n2, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["C++"])
    end)

    Node.spawn(n3, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["C"])
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["B"])
    end)

    Process.sleep(200)

    test_pid = self()

    Node.spawn(hd(nodes), fn ->
      send(test_pid, {:set, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set, languages})
    assert Enum.sort(["C", "C++"]) == Enum.sort(languages)
  end

  test "changes are synchronized after network failure heals", %{nodes: nodes} do
    [n1, n2, n3] = nodes

    Schism.partition([n1])
    Schism.partition([n2, n3])

    test_pid = self()

    Node.spawn(n1, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Photoshop"])
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Frontpage"])
      Crdt.mutate(Crdt.AddRemoveSet, :remove, ["DreamWeaver"])
      Process.sleep(200)
      send(test_pid, {:set_n1, Crdt.read(Crdt.AddRemoveSet)})
    end)

    Node.spawn(n2, fn ->
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["Photoshop"])
      Crdt.mutate(Crdt.AddRemoveSet, :add, ["DreamWeaver"])
      Process.sleep(200)
      send(test_pid, {:set_n2, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set_n1, prog1}, 300)
    assert Enum.sort(["Photoshop", "Frontpage"]) == Enum.sort(prog1)
    assert_receive({:set_n2, prog2}, 300)
    assert Enum.sort(["Photoshop", "DreamWeaver"]) == Enum.sort(prog2)

    Schism.heal(nodes)

    Process.sleep(200)

    Node.spawn(n1, fn ->
      send(test_pid, {:set_n1, Crdt.read(Crdt.AddRemoveSet)})
    end)

    Node.spawn(n2, fn ->
      send(test_pid, {:set_n2, Crdt.read(Crdt.AddRemoveSet)})
    end)

    assert_receive({:set_n1, prog1}, 300)
    assert Enum.sort(["Photoshop", "Frontpage"]) == Enum.sort(prog1)
    assert_receive({:set_n2, prog2}, 300)
    assert Enum.sort(["Photoshop", "Frontpage"]) == Enum.sort(prog2)
  end
end
