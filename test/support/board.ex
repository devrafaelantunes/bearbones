defmodule TestUtils.Board do
  @doc """
  Avoids flakiness between tests by removing state. Notice we don't actually
  remove the genservers but that's fine
  """
  def reset do
    :ets.tab2list(:bb_player_presence)
    |> Enum.each(fn {_name, pid} ->
      # Avoids flakiness by ensuring that killed players from previous tests
      # don't pop up in future tests
      GenServer.call(pid, {:cancel_respawn})
    end)

    :ets.delete_all_objects(:bb_player_presence)
    :ets.delete_all_objects(:bb_board_state)
  end
end
