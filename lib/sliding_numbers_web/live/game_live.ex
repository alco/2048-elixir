defmodule SlidingNumbersWeb.GameLive do
  use SlidingNumbersWeb, :live_view

  alias SlidingNumbers.Game.Grid
  use Grid.Direction

  def mount(_params, %{"game_seed" => game_seed}, socket) do
    Grid.seed(game_seed)
    grid = Grid.new(6)
    {:ok, assign(socket, grid_size: grid.size, prev_grid: grid, grid: grid)}
  end

  def handle_event(
        "keydown",
        %{"key" => _key},
        %{private: %{game_live: %{keydown?: true}}} = socket
      ) do
    # Ignore all keydown events until the next keyup resets the keydown? field back to false.
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => key}, %{assigns: %{grid: grid}} = socket)
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

    {:noreply,
     socket
     |> update_private(:keydown?, true)
     |> assign(prev_grid: grid, grid: next_grid)
     |> push_event("make-move", %{transitions: encode_transitions(next_grid.transitions)})}
  end

  def handle_event("keydown", _event, socket) do
    # Ignore all other keys not handled above.
    {:noreply, socket}
  end

  def handle_event("keyup", %{"key" => _key}, socket) do
    {:noreply, update_private(socket, :keydown?, false)}
  end

  defp update_private(socket, key, val) do
    private = Map.update(socket.private, :game_live, %{key => val}, &Map.put(&1, key, val))
    %{socket | private: private}
  end

  defp encode_transitions(transitions), do: Enum.map(transitions, &encode_transition/1)

  defp encode_transition({:shift, {xfrom, yfrom}, {xto, yto}, _n}),
    do: %{kind: "shift", x: xfrom, y: yfrom, xTo: xto, yTo: yto}

  defp encode_transition({:appear, {x, y}, n}), do: %{kind: "appear", x: x, y: y, n: n}

  defp encode_transition({:merge, {xfrom, yfrom}, {xto, yto}, n}),
    do: %{kind: "merge", x: xfrom, y: yfrom, xTo: xto, yTo: yto, n: n}
end
