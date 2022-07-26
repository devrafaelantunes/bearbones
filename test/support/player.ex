defmodule TestUtils.Player do
  def move(name, new_pos) do
    pid = BB.Player.Presence.get_player(name)
    true = not is_nil(pid)

    :sys.replace_state(pid, fn %{position: cur_pos} = state ->
      BB.Board.State.move_player({name, pid}, cur_pos, new_pos)
      %{state | position: new_pos}
    end)
  end

  def get_state(name) when is_binary(name) do
    pid = BB.Player.Presence.get_player(name)
    get_state(pid)
  end

  def get_state(pid) when is_pid(pid) do
    :sys.get_state(pid)
  end
end
