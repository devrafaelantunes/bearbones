defmodule BB.Webserver.Router do
  @moduledoc false

  use Plug.Router

  require Logger

  alias BB.Webserver.Plugs

  plug(CORSPlug, origin: "*")
  plug(Plugs.ParseQueryString)
  plug(Plugs.JSON)
  plug(:match)
  plug(:dispatch)

  get "/game" do
    BB.Controller.game(conn)
  end

  post "/game" do
    BB.Controller.game(conn)
  end

  match _ do
    Logger.debug("Returning 404 for: #{conn.method} #{inspect(conn.path_info)}")
    send_resp(conn, 404, "")
  end
end
