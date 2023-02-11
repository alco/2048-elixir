defmodule SlidingNumbers do
  alias SlidingNumbers.Game

  @doc """
  Run this function in IEx to start a local interactive game session.
  """
  def start_local(grid_size) do
    Game.Grid.new(grid_size)
    |> game_loop()
  end

  defp game_loop(grid) do
    Game.Grid.pretty_print(grid)

    input = IO.gets("Enter a direction for the next move and press ENTER (r/l/u/d): ")

    direction =
      case input |> String.trim() |> String.downcase() do
        "r" -> :right
        "l" -> :left
        "u" -> :up
        "d" -> :down
        _ -> nil
      end

    if direction do
      Game.Grid.make_move(grid, direction)
      |> decode_move_result()
    else
      IO.puts("Input error. Try again, please.")
      game_loop(grid)
    end
  end

  defp decode_move_result({:ok, next_grid}) do
    game_loop(next_grid)
  end

  defp decode_move_result({:won, grid}) do
    Game.Grid.pretty_print(grid)
    IO.puts("-== CONGRATULATIONS! YOU WIN! ==-")
  end

  defp decode_move_result({:lost, grid}) do
    Game.Grid.pretty_print(grid)
    IO.puts("-== NO VALID MOVES LEFT. YOU LOSE! ==-")
  end
end
