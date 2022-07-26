defmodule BB.Player.Presence do
  @moduledoc """
    Manage players by creating an ETS table to control their presence
  """
  use GenServer

  @table_name :bb_player_presence

  @doc false
  def get_player(name) do
    :ets.lookup(@table_name, name)
    |> case do
      [] -> nil
      [{_, pid}] -> pid
    end
  end

  @doc false
  def register_player(name, pid) when is_binary(name) and is_pid(pid) do
    GenServer.call(__MODULE__, {:register, name, pid})
  end

  @doc false
  def deregister_player(name) do
    GenServer.call(__MODULE__, {:deregister, name})
  end

  ###

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @doc """
    Initialize an ETS table to store active players
  """
  def init(_) do
    table = :ets.new(@table_name, [:ordered_set, :named_table, :public])
    {:ok, table}
  end

  @doc """
    Register player by inserting it in the ETS table
  """
  def handle_call({:register, name, pid}, _from, state) do
    {:reply, :ets.insert(@table_name, {name, pid}), state}
  end

  @doc """
    Remove player from ETS table
  """
  def handle_call({:deregister, name}, _from, state) do
    {:reply, :ets.delete(@table_name, name), state}
  end
end
