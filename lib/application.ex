defmodule BB.Application do
  use Application

  def start(_type, _args) do
    children = [
      BB.Board.State,
      BB.Player.Presence,
      BB.Player.Supervisor,
      cowboy_child_spec()
    ]

    opts = [strategy: :one_for_one, name: BB.Application]
    Supervisor.start_link(children, opts)
  end

  defp cowboy_child_spec do
    dispatch = [{:_, [{:_, Plug.Cowboy.Handler, {BB.Webserver.Router, []}}]}]

    {
      Plug.Cowboy,
      scheme: :http, plug: BB.Webserver.Router, port: 4040, dispatch: dispatch
    }
  end
end
