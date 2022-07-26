defmodule BB.Player.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  @doc false
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc false
  def start_player(name) do
    DynamicSupervisor.start_child(__MODULE__, {BB.Player, %{name: name}})
  end

  @doc false
  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
