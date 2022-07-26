defmodule BB.Player.PresenceTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  describe "presence" do
    @tag :capture_log
    test "registers player on first login" do
      assert [] == :ets.tab2list(:bb_player_presence)
      assert {:ok, pid} = BB.Player.login("foo")
      assert [{"foo", pid}] == :ets.tab2list(:bb_player_presence)

      TestUtils.Board.reset()
    end

    @tag :captur_log
    test "on subsequent logins, just returns the cached PID" do
      assert [] == :ets.tab2list(:bb_player_presence)

      # First call there is the "registered player" log
      log =
        capture_log(fn ->
          assert {:ok, pid} = BB.Player.login("foo")
          assert [{"foo", pid}] == :ets.tab2list(:bb_player_presence)
        end)

      assert log =~ "Registered player 'foo' in"

      # Subsequent calls have no logs because they never reach the Player's
      # GenServer `init` callback
      log =
        capture_log(fn ->
          assert {:ok, pid} = BB.Player.login("foo")
          assert [{"foo", pid}] == :ets.tab2list(:bb_player_presence)

          assert {:ok, pid} = BB.Player.login("foo")
          assert [{"foo", pid}] == :ets.tab2list(:bb_player_presence)
        end)

      assert log == ""

      TestUtils.Board.reset()
    end
  end
end
