defmodule BB.Player do
  @moduledoc """
    Exposes the Players's API
  """

  use GenServer

  require Logger

  @type name :: String.t()

  @respawn_interval Application.get_env(:bb, :respawn_threshold)

  @spec login(name) :: {:ok, pid}
  @doc false
  def login(name) do
    case BB.Player.Presence.get_player(name) do
      pid when is_pid(pid) ->
        {:ok, pid}

      nil ->
        {:ok, pid} = __MODULE__.Supervisor.start_player(name)
        BB.Player.Presence.register_player(name, pid)
        {:ok, pid}
    end
  end

  @spec walk(pid, BB.Board.direction()) ::
          {:ok, BB.Board.position()}
          | {:error, :dead | :out_of_bounds | :wall}
  @doc false
  def walk(pid, direction) when direction in [:up, :down, :left, :right] do
    GenServer.call(pid, {:walk, direction})
  end

  @spec attack(pid) ::
          {:ok, total_players_killed :: integer()}
          | {:error, :dead}
  @doc false
  def attack(pid) do
    GenServer.call(pid, {:attack})
  end

  @spec notify_death(pid, name) ::
          term
  @doc false
  def notify_death(pid, killer_name) do
    GenServer.cast(pid, {:notification, :death, killer_name})
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # Server API

  @doc false
  def init(%{name: name}) do
    # Register the player in the Board state
    {:ok, initial_position} = BB.Board.register_new_player(name, self())

    state = %{
      name: name,
      position: initial_position,
      is_dead?: false,
      timer: nil
    }

    Logger.debug("Player '#{name}' is being handled by process #{inspect(self())}")

    {:ok, state}
  end

  @doc false
  def handle_call({:walk, _}, _from, %{is_dead?: true} = state) do
    {:reply, {:error, :dead}, state}
  end

  @doc false
  def handle_call({:walk, direction}, _from, state) do
    result = BB.Board.walk_player({state.name, self()}, state.position, direction)

    new_state =
      case result do
        {:ok, new_pos} ->
          %{state | position: new_pos}

        {:error, _} ->
          state
      end

    {:reply, result, new_state}
  end

  @doc false
  def handle_call({:attack}, _from, %{is_dead?: true} = state) do
    {:reply, {:error, :dead}, state}
  end

  @doc false
  def handle_call({:attack}, _from, state) do
    result = BB.Board.record_attack(state.name, state.position)
    {:reply, result, state}
  end

  if Mix.env() == :test do
    # This is a hack to avoid flakiness in tests
    def handle_call({:cancel_respawn}, _from, state) do
      if not is_nil(state.timer),
        do: Process.cancel_timer(state.timer)

      {:reply, :ok, %{state | timer: nil}}
    end
  end

  @doc false
  def handle_cast({:notification, :death, _killer_name}, state) do
    # Respawn the player in 5 secs
    timer = Process.send_after(self(), :respawn, @respawn_interval)

    Logger.info("Player '#{state.name}' was notified of its death")
    {:noreply, %{state | is_dead?: true, timer: timer}}
  end

  @doc false
  def handle_info(:respawn, state) do
    {:ok, new_position} = BB.Board.respawn_player({state.name, self()}, state.position)

    new_state =
      state
      |> Map.put(:is_dead?, false)
      |> Map.put(:position, new_position)

    {:noreply, new_state}
  end
end
