defmodule SlidingNumbersWeb.GameLive do
  @moduledoc """
  Live view of the game.

  This view can be reached only from the main menu. If you try to load this view
  directly, you'll be redirected to the main menu anyway. The reason for this is
  that it allows us to not worry about any game state persistance.

  If we allowed the game view to be loaded in the web browser directly, we'd
  need to preserve the initial game state between the first call to `mount()`,
  which happens in response to the web browser's GET request, and the second
  call to `mount()` which happens after the live view socket connection has been
  established, in order to avoid any flickering on the game grid.
  """

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

  # Ignore all events if the game is already over.
  def handle_event(_event, _params, %{assigns: %{game_over: game_over}} = socket)
      when not is_nil(game_over) do
    {:noreply, socket}
  end

  # Ignore all keydown events until the next keyup resets the keydown? field back to false.
  def handle_event(
        "keydown",
        %{"key" => _key},
        %{private: %{game_live: %{keydown?: true}}} = socket
      ) do
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
     # The @prev_grid assign represents the grid state preceding the latest move
     # and it's the one that is actually rendered on the client. But since the
     # client will also animate grid cells using the data from next_grid.transitions,
     # the game grid's appearance will end up the same as if @grid had been
     # rendered in the first place.
     |> assign(prev_grid: grid, grid: next_grid)
     |> push_event("make-move", %{transitions: encode_transitions(next_grid.transitions)})
     |> check_game_over(tag)}
  end

  # Ignore all other keys not handled above.
  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  # A game move is triggered by a keydown event to make the game feel
  # responsive. But in order to avoid accidentally triggering the next move, we
  # set a flag after receiving the first keydown event and only reset it after
  # a subsequent keyup event.
  #
  # Thus, the game grid is updated immediately after the player presses an array
  # key, but they will have to release the key and press it again to trigger the
  # next move.
  def handle_event("keyup", %{"key" => _key}, socket) do
    {:noreply, update_private(socket, :keydown?, false)}
  end

  # The "end-game" event is triggered when the player clicks on the "End game"
  # button and confirms they want to forfeit the game.
  def handle_event("end-game", _params, socket) do
    {:noreply, push_navigate(socket, to: "/")}
  end

  defp update_private(socket, key, val) do
    private = Map.update(socket.private, :game_live, %{key => val}, &Map.put(&1, key, val))
    %{socket | private: private}
  end

  # Before the list of game grid transitions can be sent to the client, it needs
  # to be made JSON-encodable.
  defp encode_transitions(transitions), do: Enum.map(transitions, &encode_transition/1)

  defp encode_transition({:shift, {xfrom, yfrom}, {xto, yto}, _n}),
    do: %{kind: "shift", x: xfrom, y: yfrom, xTo: xto, yTo: yto}

  defp encode_transition({:appear, {x, y}, n}), do: %{kind: "appear", x: x, y: y, n: n}

  defp encode_transition({:merge, {xfrom, yfrom}, {xto, yto}, n}),
    do: %{kind: "merge", x: xfrom, y: yfrom, xTo: xto, yTo: yto, n: n}

  defp check_game_over(socket, :ok), do: socket
  # With this assign in place, the game live view will ignore any incoming events.
  defp check_game_over(socket, won_or_lost), do: assign(socket, :game_over, won_or_lost)
end
