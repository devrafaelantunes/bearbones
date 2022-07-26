defmodule BB.BoardTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  describe "calculate_walk_position/1" do
    test "returns expected position" do
      pos = {2, 2}

      [
        {:up, {2, 3}},
        {:down, {2, 1}},
        {:right, {3, 2}},
        {:left, {1, 2}}
      ]
      |> Enum.each(fn {direction, expected_pos} ->
        assert BB.Board.calculate_walk_position(pos, direction) == expected_pos
      end)
    end
  end

  describe "get_attack_surface/1" do
    test "returns expected surface" do
      pos = {2, 2}

      expected_result = [
        # Self
        {2, 2},
        # Up down left right
        {3, 2},
        {1, 2},
        {2, 3},
        {2, 1},
        # Diagonals
        {3, 3},
        {3, 1},
        {1, 3},
        {1, 1}
      ]

      assert BB.Board.get_attack_surface(pos) == expected_result
    end
  end

  describe "is_oob?/1" do
    test "returns expected result" do
      # Note: we are using size=10
      refute BB.Board.is_oob?({9, 9})
      assert BB.Board.is_oob?({10, 9})
      assert BB.Board.is_oob?({9, 10})

      refute BB.Board.is_oob?({0, 0})
      assert BB.Board.is_oob?({-1, 0})
      assert BB.Board.is_oob?({0, -1})
    end
  end

  describe "is_wall?/1" do
    test "returns expected result" do
      # To avoid flakiness, let's manually generate our own walls
      :persistent_term.put({:bb, :walls}, [{5, 5}])

      assert BB.Board.is_wall?({5, 5})
      refute BB.Board.is_wall?({5, 4})
      refute BB.Board.is_wall?({0, 0})
    end
  end

  @tag :capture_log
  describe "generate_walls/0" do
    test "generates walls" do
      :persistent_term.put({:bb, :walls}, [])

      log =
        capture_log(fn ->
          BB.Board.generate_walls()
        end)

      assert log =~ "Walls generated"

      walls = :persistent_term.get({:bb, :walls})
      refute Enum.empty?(walls)

      Enum.each(walls, fn wall_pos ->
        assert BB.Board.is_wall?(wall_pos)
      end)
    end
  end
end
