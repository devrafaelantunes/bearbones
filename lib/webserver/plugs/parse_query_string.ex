defmodule BB.Webserver.Plugs.ParseQueryString do
  @moduledoc false

  import Plug.Conn

  def init([]), do: false

  def call(conn, _opts) do
    qs =
      conn.query_string
      |> URI.query_decoder()
      |> Enum.to_list()
      |> Map.new()

    put_private(conn, :qs, qs)
  end
end
