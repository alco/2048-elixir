defmodule SlidingNumbersWeb.Router do
  use SlidingNumbersWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SlidingNumbersWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", SlidingNumbersWeb do
    pipe_through :browser

    live "/", MenuLive
    live "/play", GameLive
  end
end
