defmodule BB.Board do
  @moduledoc """
    Exposes the Board's API
  """

  require Logger

  alias BB.Board.State

  @type direction :: :up | :down | :left | :right
  @type position :: {x :: integer, y :: integer}

  @size Application.get_env(:bb, :size)
  @wall_probability Application.get_env(:bb, :wall_probability)
  @pt_walls {:bb, :walls}

  @spec register_new_player(BB.Player.name(), pid) :: {:ok, position}
  @doc false
  def register_new_player(name, pid) do
    initial_position = generate_random_position()
    State.add_player({name, pid}, initial_position)

    Logger.info("Registered player '#{name}' in #{inspect(initial_position)}")
    {:ok, initial_position}
  end

  @spec walk_player({BB.Player.name(), pid}, position, direction) ::
          {:ok, position}
          | {:error, :wall | :out_of_bounds | :dead}
  @doc false
  def walk_player({name, pid}, cur_pos, direction) do
    new_pos = calculate_walk_position(cur_pos, direction)

    cond do
      not State.is_player_alive?(cur_pos, name) ->
        Logger.error("Unable to move player '#{name}' to #{inspect(new_pos)}: dead")
        {:error, :dead}

      # Player cannot move to a wall
      is_wall?(new_pos) ->
        Logger.info("Unable to move player '#{name}' to #{inspect(new_pos)}: wall")
        {:error, :wall}

      # Check if the position is out of bounds
      is_oob?(new_pos) ->
        Logger.info("Unable to move player '#{name}' to #{inspect(new_pos)}: out of bounds")
        {:error, :out_of_bounds}

      :else ->
        State.move_player({name, pid}, cur_pos, new_pos)
        Logger.info("Moved player '#{name}' from #{inspect(cur_pos)} to #{inspect(new_pos)}")
        {:ok, new_pos}
    end
  end

  @spec record_attack(BB.Player.name(), position) ::
          {:ok, total_players_killed :: integer()}
          | {:error, :dead}
  @doc false
  def record_attack(attacker_name, pos) do
    Logger.info("Recording attack from '#{attacker_name}' at #{inspect(pos)}")

    if State.is_player_alive?(pos, attacker_name) do
      do_record_attack(attacker_name, pos)
    else
      Logger.error("Unable to record attack from '#{attacker_name}': dead")
      {:error, :dead}
    end
  end

  @doc false
  defp do_record_attack(attacker_name, pos) do
    attack_positions = get_attack_surface(pos)

    affected_players =
      attack_positions
      |> Enum.map(&State.get_alive_players_at_position(&1))
      |> List.flatten()
      |> Enum.reject(fn {_, {n, _, _}} -> n == attacker_name end)

    # Mark these players as dead
    Enum.each(affected_players, fn {pos, {n, _, _} = player} ->
      Logger.debug("[record_attack] Player '#{n}' is now dead")
      State.mark_as_dead({pos, player})
    end)

    # Notify the players that they are dead
    Enum.each(affected_players, fn {_, {_, pid, _}} ->
      BB.Player.notify_death(pid, attacker_name)
    end)

    {:ok, length(affected_players)}
  end

  @spec respawn_player({BB.Player.name(), pid}, position) ::
          {:ok, position}
          | {:error, :not_dead}
  @doc false
  def respawn_player({name, pid}, cur_position) do
    unless State.is_player_alive?(cur_position, name) do
      new_position = generate_random_position()
      State.respawn_player({name, pid}, cur_position, new_position)
      Logger.info("Respawned player '#{name}' at #{inspect(new_position)}")
      {:ok, new_position}
    else
      Logger.error("Tried to respawn alive player '#{inspect(name)}'")
      {:error, :not_dead}
    end
  end

  @doc false
  def get_state do
    walls =
      :persistent_term.get(@pt_walls)
      |> Enum.map(fn {x, y} -> [x, y] end)

    %{
      size: @size,
      walls: walls,
      players: State.dump()
    }
  end

  # Utils

  @spec generate_random_position() :: position
  @doc false
  def generate_random_position do
    pos = {Enum.random(0..(@size - 1)), Enum.random(0..(@size - 1))}
    if is_wall?(pos), do: generate_random_position(), else: pos
  end

  @spec calculate_walk_position(position, direction) :: position
  def calculate_walk_position({x, y}, :up), do: {x, y + 1}
  def calculate_walk_position({x, y}, :down), do: {x, y - 1}
  def calculate_walk_position({x, y}, :right), do: {x + 1, y}
  def calculate_walk_position({x, y}, :left), do: {x - 1, y}

  @spec get_attack_surface(position) :: [position]
  @doc false
  def get_attack_surface({x, y}) do
    [
      # Own position
      {x, y},
      # Up down left right
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1},
      # Diagonals
      {x + 1, y + 1},
      {x + 1, y - 1},
      {x - 1, y + 1},
      {x - 1, y - 1}
    ]
  end

  @spec generate_walls() :: term
  @doc false
  def generate_walls do
    total_walls = (@size * @size * @wall_probability) |> ceil()
    :persistent_term.put(@pt_walls, [])

    Enum.each(1..total_walls, fn _ ->
      walls = [generate_random_position() | :persistent_term.get(@pt_walls)]
      :persistent_term.put(@pt_walls, walls)
    end)

    walls = :persistent_term.get(@pt_walls)
    Logger.info("Walls generated: #{inspect(walls)}")
  end

  @spec is_oob?(position) :: boolean
  def is_oob?({x, y}) when x < 0 or y < 0, do: true
  def is_oob?({x, y}) when x > @size - 1 or y > @size - 1, do: true
  def is_oob?(_), do: false

  @spec is_wall?(position) :: boolean
  @doc false
  def is_wall?(pos) do
    walls = :persistent_term.get(@pt_walls)
    pos in walls
  end
end
