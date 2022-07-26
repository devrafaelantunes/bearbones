defmodule BB.Controller do
  @moduledoc """
    Game's controller
  """

  require Logger
  import Plug.Conn

  @doc """
    Login and register a new player
  """
  def game(%_{method: "GET", private: %{qs: %{"name" => name}}} = conn) do
    {:ok, _pid} = BB.Player.login(name)
    state = BB.Board.get_state()
    send_resp(conn, 200, Jason.encode!(state))
  end

  @doc false
  def game(%_{method: "GET"} = conn) do
    send_resp(conn, 400, "Missing `name` param")
  end

  @doc """
    Walk player in the desired direction
  """
  def game(
        %_{
          method: "POST",
          private: %{qs: %{"name" => name, "action" => "walk", "direction" => direction}}
        } = conn
      )
      when direction in ["up", "down", "right", "left"] do
    Logger.info("#{name} - Received request to walk #{direction}")
    direction = String.to_existing_atom(direction)

    {:ok, pid} = BB.Player.login(name)

    {status, response} =
      case BB.Player.walk(pid, direction) do
        {:ok, {x, y}} -> {200, ["ok", [x, y]]}
        {:error, reason} -> {400, ["error", reason]}
      end

    send_resp(conn, status, Jason.encode!(response))
  end

  # Attack all players in range
  def game(%_{method: "POST", private: %{qs: %{"name" => name, "action" => "attack"}}} = conn) do
    Logger.info("#{name} - Received request to attack")
    {:ok, pid} = BB.Player.login(name)

    {status, response} =
      case BB.Player.attack(pid) do
        {:ok, total} -> {200, ["ok", total]}
        {:error, reason} -> {400, ["error", reason]}
      end

    send_resp(conn, status, Jason.encode!(response))
  end

  @doc false
  def game(%_{method: "POST"} = conn) do
    send_resp(conn, 400, "Something's off with your payload")
  end
end
