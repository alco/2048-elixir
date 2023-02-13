defmodule SlidingNumbersWeb.Plugs.IdentifyUser do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    seed = Plug.Conn.get_session(conn, :game_seed)

    if seed do
      conn
    else
      Plug.Conn.put_session(conn, :game_seed, System.unique_integer())
    end
  end
end
