defmodule BB.Webserver.Plugs.JSON do
  @moduledoc false

  import Plug.Conn

  def init([]), do: false

  def call(conn, _opts) do
    put_resp_header(conn, "content-type", "application/json")
  end
end
