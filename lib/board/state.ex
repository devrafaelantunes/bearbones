defmodule BB.Board.State do
  @moduledoc """
    Handles the board's state. It uses ETS as a cache to increase performance
    and prevent GenServer's bottlenecks.
  """
  use GenServer

  @typep player :: {BB.Player.name(), pid, alive? :: boolean}
  @typep row :: {BB.Board.position(), player}

  @board_name :bb_board_state

  # High-level functions

  @spec get_player(BB.Board.position(), BB.Player.name()) :: [row]
  @doc """
    Fetches player from the ETS table
  """
  def get_player(pos, name) do
    :ets.match_object(@board_name, {pos, {name, :_, :_}})
  end

  @spec get_alive_players_at_position(BB.Board.position()) :: [row]
  @doc """
    Fetches all players in a determinated position
  """
  def get_alive_players_at_position(pos) do
    :ets.match_object(@board_name, {pos, {:_, :_, true}})
  end

  @spec is_player_alive?(BB.Board.position(), BB.Player.name()) :: boolean
  @doc """
    Checks if the player is alive
  """
  def is_player_alive?(pos, name) do
    [{_, {_, _, alive?}}] = get_player(pos, name)
    alive?
  end

  @spec add_player({BB.Player.name(), pid}, BB.Board.position()) :: term
  @doc """
    Add player to the board
  """
  def add_player({name, pid}, pos) do
    insert(pos, {name, pid, true})
  end

  @spec move_player({BB.Player.name(), pid}, BB.Board.position(), BB.Board.position()) :: term
  @doc """
    Move player through the board
  """
  def move_player({name, pid}, cur_pos, new_pos) do
    delete_by_name(cur_pos, name)
    insert(new_pos, {name, pid, true})
  end

  @spec mark_as_dead(row) :: term
  @doc """
    Delete the player from the state and mark it as dead
  """
  def mark_as_dead({pos, {name, pid, _}}) do
    delete_by_name(pos, name)
    insert(pos, {name, pid, false})
  end

  @spec respawn_player({BB.Player.name(), pid}, BB.Board.position(), BB.Board.position()) :: term
  @doc """
    Respawn player by deleting its old position and insert it back in the game after 5 seconds
  """
  def respawn_player({name, pid}, old_pos, new_pos) do
    delete_by_name(old_pos, name)
    insert(new_pos, {name, pid, true})
  end

  @doc false
  def dump do
    :ets.tab2list(@board_name)
    |> Enum.map(fn {{x, y}, {name, _pid, alive?}} -> [[x, y], name, alive?] end)
  end

  # Building blocks

  @spec delete_by_name(BB.Board.position(), BB.Player.name()) :: term
  @doc false
  def delete_by_name(pos, name) do
    GenServer.call(__MODULE__, {:delete, pos, name})
  end

  @spec insert(BB.Board.position(), player) :: term
  @doc false
  def insert(pos, {name, pid, alive?})
      when is_binary(name) and is_pid(pid) and is_boolean(alive?) do
    GenServer.call(__MODULE__, {:insert, {pos, {name, pid, alive?}}})
  end

  ###

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def init(_) do
    table = :ets.new(@board_name, [:bag, :named_table, :public])
    {:ok, table, {:continue, :initialize_board}}
  end

  @doc false
  def handle_continue(:initialize_board, state) do
    BB.Board.generate_walls()
    {:noreply, state}
  end

  @doc false
  def handle_call({:insert, {pos, player}}, _from, state) do
    {:reply, :ets.insert(@board_name, {pos, player}), state}
  end

  @doc false
  def handle_call({:delete, pos, name}, _from, state) do
    {:reply, :ets.match_delete(@board_name, {pos, {name, :_, :_}}), state}
  end
end
