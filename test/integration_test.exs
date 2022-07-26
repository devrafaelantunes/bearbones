defmodule BB.IntegrationTest do
  use ExUnit.Case, async: false

  describe "walk" do
    @tag :capture_log
    test "walking around the board (valid moves)" do
      {:ok, pid} = BB.Player.login("foo")
      # No walls to avoid flakiness
      :persistent_term.put({:bb, :walls}, [])

      # Force player to be at position {0, 0}
      TestUtils.Player.move("foo", {0, 0})

      # Assert that the player is indeed at position {0, 0}
      assert TestUtils.Player.get_state(pid).position == {0, 0}
      assert [{{0, 0}, {"foo", _, _}}] = BB.Board.State.get_player({0, 0}, "foo")

      # Move around (within  bounds, no walls)
      assert {:ok, {0, 1}} = BB.Player.walk(pid, :up)
      assert {:ok, {0, 2}} = BB.Player.walk(pid, :up)
      assert {:ok, {1, 2}} = BB.Player.walk(pid, :right)
      assert {:ok, {1, 1}} = BB.Player.walk(pid, :down)
      assert {:ok, {0, 1}} = BB.Player.walk(pid, :left)

      # When player moves around, the board state is also updated
      assert [{_, {"foo", _, _}}] = BB.Board.State.get_alive_players_at_position({0, 1})

      assert {:ok, {0, 2}} = BB.Player.walk(pid, :up)
      assert [] = BB.Board.State.get_alive_players_at_position({0, 1})
      assert [{_, {"foo", _, _}}] = BB.Board.State.get_alive_players_at_position({0, 2})

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "unable to walk out of bounds" do
      {:ok, pid} = BB.Player.login("foo")

      # Force player to be at position {0, 0}
      TestUtils.Player.move("foo", {0, 0})

      assert {:error, :out_of_bounds} = BB.Player.walk(pid, :down)

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "unable to walk onto a wall" do
      {:ok, pid} = BB.Player.login("foo")

      # Force player to be at position {0, 0}
      TestUtils.Player.move("foo", {0, 0})

      # Player is surrounded by walls
      :persistent_term.put({:bb, :walls}, [{0, 1}, {1, 0}])

      assert {:error, :wall} = BB.Player.walk(pid, :up)
      assert {:error, :wall} = BB.Player.walk(pid, :right)

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "unable to walk when dead" do
      {:ok, pid_1} = BB.Player.login("foo")
      {:ok, pid_2} = BB.Player.login("bar")

      TestUtils.Player.move("foo", {0, 0})
      TestUtils.Player.move("bar", {0, 0})
      :persistent_term.put({:bb, :walls}, [])

      # `foo` killed `bar`
      assert {:ok, 1} = BB.Player.attack(pid_1)

      assert TestUtils.Player.get_state(pid_2).is_dead?
      assert {:error, :dead} = BB.Player.walk(pid_2, :up)

      TestUtils.Board.reset()
    end
  end

  describe "attack" do
    @tag :capture_log
    test "does not kill own player" do
      {:ok, pid} = BB.Player.login("foo")

      assert {:ok, 0} = BB.Player.attack(pid)

      # Player is not dead
      refute TestUtils.Player.get_state(pid).is_dead?

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "kills adjacent players" do
      TestUtils.Board.reset()

      {:ok, pid} = BB.Player.login("foo")

      TestUtils.Player.move("foo", {2, 2})
      :persistent_term.put({:bb, :walls}, [])

      {:ok, _p_self} = BB.Player.login("self")
      TestUtils.Player.move("self", {2, 2})

      {:ok, _p_n} = BB.Player.login("north")
      TestUtils.Player.move("north", {2, 3})

      {:ok, _p_ne} = BB.Player.login("northeast")
      TestUtils.Player.move("northeast", {3, 3})

      {:ok, _p_e} = BB.Player.login("east")
      TestUtils.Player.move("east", {3, 2})

      {:ok, _p_se} = BB.Player.login("southeast")
      TestUtils.Player.move("southeast", {1, 3})

      {:ok, _p_s} = BB.Player.login("south")
      TestUtils.Player.move("south", {2, 1})

      {:ok, _p_sw} = BB.Player.login("southwest")
      TestUtils.Player.move("southwest", {1, 1})

      {:ok, _p_w} = BB.Player.login("west")
      TestUtils.Player.move("west", {1, 2})

      {:ok, _p_nw} = BB.Player.login("northwest")
      TestUtils.Player.move("northwest", {3, 2})

      {:ok, _p_far} = BB.Player.login("far")
      TestUtils.Player.move("far", {4, 2})

      # Kill them all (except the far one)
      assert {:ok, 9} = BB.Player.attack(pid)

      expected_dead = [
        "self",
        "north",
        "northeast",
        "east",
        "southeast",
        "south",
        "southwest",
        "west",
        "northwest"
      ]

      # Asserts they are all dead
      Enum.each(expected_dead, fn name ->
        state = TestUtils.Player.get_state(name)
        assert state.is_dead?

        alive_at_position = BB.Board.State.get_alive_players_at_position(state.position)

        if name == "self" do
          assert [{{2, 2}, {"foo", _, true}}] = alive_at_position
        else
          assert [] == alive_at_position
        end
      end)

      # `far` player is alive and well
      refute TestUtils.Player.get_state("far").is_dead?
      assert [{_, {"far", _, true}}] = BB.Board.State.get_alive_players_at_position({4, 2})

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "player is respawned after 5 seconds" do
      {:ok, pid_1} = BB.Player.login("foo")
      {:ok, pid_2} = BB.Player.login("bar")

      TestUtils.Player.move("foo", {0, 0})
      TestUtils.Player.move("bar", {0, 0})
      :persistent_term.put({:bb, :walls}, [])

      # `foo` killed `bar`
      assert {:ok, 1} = BB.Player.attack(pid_1)

      assert TestUtils.Player.get_state(pid_2).is_dead?
      assert [{_, {_, _, false}}] = BB.Board.State.get_player({0, 0}, "bar")

      :timer.sleep(550)

      # Respawned at random location
      new_state = TestUtils.Player.get_state(pid_2)
      refute new_state.is_dead?
      assert [{_, {_, _, true}}] = BB.Board.State.get_player(new_state.position, "bar")

      TestUtils.Board.reset()
    end

    @tag :capture_log
    test "unable to attack when dead" do
      {:ok, pid_1} = BB.Player.login("foo")
      {:ok, pid_2} = BB.Player.login("bar")

      TestUtils.Player.move("foo", {0, 0})
      TestUtils.Player.move("bar", {0, 0})
      :persistent_term.put({:bb, :walls}, [])

      # `foo` killed `bar`
      assert {:ok, 1} = BB.Player.attack(pid_1)

      assert TestUtils.Player.get_state(pid_2).is_dead?
      assert {:error, :dead} = BB.Player.attack(pid_2)

      TestUtils.Board.reset()
    end
  end
end
