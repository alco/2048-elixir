defmodule SlidingNumbersWeb.GameLive do
  use SlidingNumbersWeb, :live_view

  alias SlidingNumbers.Game.Grid
  use Grid.Direction

  @default_grid_size 5

  def mount(params, _session, socket) do
    if not connected?(socket) do
      {:ok, push_navigate(socket, to: "/")}
    else
      do_mount(params, socket)
    end
  end

  defp do_mount(params, socket) do
    grid_size =
      with size_str when not is_nil(size_str) <- params["grid_size"],
           {size, ""} <- Integer.parse(size_str) do
        size
      else
        _ -> @default_grid_size
      end

    grid = Grid.new(grid_size)

    {:ok, assign(socket, grid_size: grid_size, prev_grid: grid, grid: grid, game_over: nil)}
  end

  def handle_event(_event, _params, %{assigns: %{game_over: game_over}} = socket)
      when not is_nil(game_over) do
    # Ignore all events if the game is already over.
    {:noreply, socket}
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

    {:noreply,
     socket
     |> update_private(:keydown?, true)
     |> assign(prev_grid: grid, grid: next_grid)
     |> push_event("make-move", %{transitions: encode_transitions(next_grid.transitions)})
     |> check_game_over(tag)}
  end

  def handle_event("keydown", _params, socket) do
    # Ignore all other keys not handled above.
    {:noreply, socket}
  end

  def handle_event("keyup", %{"key" => _key}, socket) do
    {:noreply, update_private(socket, :keydown?, false)}
  end

  def handle_event("end-game", _params, socket) do
    {:noreply, push_navigate(socket, to: "/")}
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

  defp check_game_over(socket, :ok), do: socket
  defp check_game_over(socket, won_or_lost), do: assign(socket, :game_over, won_or_lost)
end
