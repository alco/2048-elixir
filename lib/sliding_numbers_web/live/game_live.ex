defmodule SlidingNumbersWeb.GameLive do
  use SlidingNumbersWeb, :live_view

  alias SlidingNumbers.Game.Grid
  use Grid.Direction

  def mount(_params, _session, socket) do
    grid = Grid.new(5)
    # grid =
    #   Grid.from_list!([
    #     [1, 2, 4, 8, 16, 32],
    #     [0, 0, 0, 0, 0, 0],
    #     [16, 32, 64, 128, 256, 512],
    #     [0, 0, 0, 0, 0, 0],
    #     [256, 512, 1024, 2048, 0, 0],
    #     [0, 0, 0, 0, 0, 0]
    #   ])

    socket = assign(socket, :game_grid, grid)
    Grid.pretty_print(socket.assigns.game_grid)
    {:ok, socket}
  end

  def handle_event("keydown", %{"key" => _key}, %{assigns: %{keydown?: true}} = socket) do
    # Ignore all keydown events until the next keyup resets the @keydown? assign back to false.
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => key}, %{assigns: %{game_grid: grid}} = socket)
      when key in ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"] do
    direction =
      case key do
        "ArrowLeft" -> left()
        "ArrowRight" -> right()
        "ArrowUp" -> up()
        "ArrowDown" -> down()
      end

    {tag, next_grid} = Grid.make_move(grid, direction)
    IO.puts("Post-move result: #{tag}")
    Grid.pretty_print(next_grid)

    {:noreply, assign(socket, %{keydown?: true, game_grid: next_grid})}
  end

  def handle_event("keydown", _event, socket) do
    # Ignore all other keys not handled above.
    {:noreply, socket}
  end

  def handle_event("keyup", %{"key" => _key}, socket) do
    {:noreply, assign(socket, :keydown?, false)}
  end
end
