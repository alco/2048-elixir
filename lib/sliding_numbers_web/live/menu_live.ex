defmodule SlidingNumbersWeb.MenuLive do
  use SlidingNumbersWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, grid_size: 4)
    {:ok, socket}
  end

  def handle_event("select-size", %{"size" => size}, socket) do
    socket = assign(socket, grid_size: String.to_integer(size))
    {:noreply, socket}
  end
end
