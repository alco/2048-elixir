defmodule SlidingNumbers.Game.GridTest do
  use ExUnit.Case, async: true

  alias SlidingNumbers.Game.Grid

  describe "new()" do
    test "creates a grid with the given size" do
      for size <- 2..10 do
        grid = Grid.new(size)
        assert grid.size == size
        assert tuple_size(grid.cells) == size * size
      end
    end

    test "creates a grid that has a single non-empty cell with the number 1 in it" do
      for size <- 2..10 do
        grid = Grid.new(size)

        {num_empty, num_non_empty} =
          Enum.reduce(1..(size * size), {0, 0}, fn i, {num_empty, num_non_empty} ->
            case elem(grid.cells, i - 1) do
              0 -> {num_empty + 1, num_non_empty}
              1 -> {num_empty, num_non_empty + 1}
            end
          end)

        assert num_empty == size * size - 1
        assert num_non_empty == 1
      end
    end
  end

  describe "put() and get()" do
    test "put() puts a value in a grid cell and get() retrieves it" do
      size = 6
      grid = Grid.new(size)
      coord = {:rand.uniform(size) - 1, :rand.uniform(size) - 1}

      n = :rand.uniform(2047) + 1
      new_grid = Grid.put(grid, coord, n)

      refute grid.cells == new_grid.cells
      refute Grid.get(grid, coord) == n
      assert Grid.get(new_grid, coord) == n
    end
  end

  describe "shift_right()" do
    test "correctly shifts numbers to the right" do
      test_grids = [
        {
          [
            [0, 0, 0, 1],
            [0, 0, 2, 1],
            [0, 0, 0, 2],
            [0, 0, 2, 4]
          ],
          [
            [0, 0, 0, 1],
            [0, 0, 2, 1],
            [0, 0, 0, 2],
            [0, 0, 2, 4]
          ]
        },
        # -----------------------
        {
          [
            [2, 2, 1, 1],
            [0, 1, 0, 1],
            [4, 8, 4, 0],
            [2, 2, 0, 4]
          ],
          [
            [0, 0, 4, 2],
            [0, 0, 0, 2],
            [0, 4, 8, 4],
            [0, 0, 4, 4]
          ]
        },
        # -----------------------
        {
          [
            [2, 2, 1, 1],
            [1, 1, 1, 1],
            [16, 8, 4, 4],
            [1, 2, 4, 8]
          ],
          [
            [0, 0, 4, 2],
            [0, 0, 2, 2],
            [0, 16, 8, 8],
            [1, 2, 4, 8]
          ]
        },
        # -----------------------
        {
          [
            [16, 8, 4, 4],
            [0, 16, 8, 8],
            [0, 0, 16, 16],
            [0, 0, 0, 32]
          ],
          [
            [0, 16, 8, 8],
            [0, 0, 16, 16],
            [0, 0, 0, 32],
            [0, 0, 0, 32]
          ]
        },
        # -----------------------
        {
          [
            [1, 1, 2, 4, 8, 16],
            [0, 2, 2, 4, 8, 16],
            [0, 0, 4, 4, 8, 16],
            [0, 0, 0, 8, 8, 16],
            [0, 0, 0, 0, 16, 16],
            [0, 0, 0, 0, 0, 32]
          ],
          [
            [0, 2, 2, 4, 8, 16],
            [0, 0, 4, 4, 8, 16],
            [0, 0, 0, 8, 8, 16],
            [0, 0, 0, 0, 16, 16],
            [0, 0, 0, 0, 0, 32],
            [0, 0, 0, 0, 0, 32]
          ]
        },
        # -----------------------
        {
          [
            [0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0],
            [4, 2, 0, 0, 0, 128],
            [0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0],
            [0, 64, 32, 32, 8, 0]
          ],
          [
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 2, 8, 16],
            [0, 0, 0, 4, 2, 128],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 1],
            [0, 0, 0, 64, 64, 8]
          ]
        }
      ]

      Enum.each(test_grids, fn {input, expected} ->
        grid = input |> Grid.from_list!() |> Grid.shift_right()
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end
  end

  describe "shift_left()" do
    test "correctly shifts numbers to the left" do
      test_grids = [
        {
          [
            [0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0],
            [4, 2, 0, 0, 0, 128],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0],
            [0, 64, 32, 32, 8, 0]
          ],
          [
            [0, 0, 0, 0, 0, 0],
            [2, 8, 16, 0, 0, 0],
            [4, 2, 128, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0],
            [64, 64, 8, 0, 0, 0]
          ]
        }
      ]

      Enum.each(test_grids, fn {input, expected} ->
        grid = input |> Grid.from_list!() |> Grid.shift_left()
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end
  end

  describe "shift_up()" do
    test "correctly shifts numbers to the top" do
      test_grids = [
        {
          [
            [0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0],
            [4, 2, 0, 0, 0, 128],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0],
            [0, 64, 32, 32, 8, 0]
          ],
          [
            [2, 2, 1, 8, 16, 128],
            [4, 64, 32, 32, 8, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0]
          ]
        }
      ]

      Enum.each(test_grids, fn {input, expected} ->
        grid = input |> Grid.from_list!() |> Grid.shift_up()
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end
  end

  describe "shift_down()" do
    test "correctly shifts numbers to the bottom" do
      test_grids = [
        {
          [
            [0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0],
            [4, 2, 0, 0, 0, 128],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0],
            [0, 64, 32, 32, 8, 0]
          ],
          [
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [2, 2, 1, 8, 16, 0],
            [4, 64, 32, 32, 8, 128]
          ]
        }
      ]

      Enum.each(test_grids, fn {input, expected} ->
        grid = input |> Grid.from_list!() |> Grid.shift_down()
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end
  end

  test "make_move(:right) shifts numbers to the right and replaces a random empty cell with 1" do
    # TODO: bug in ExUnit's diff?
    # NOTE: Make sure you don't have 1s in these test grids.
    test_grids = [
      {
        [
          [0, 0, 0, 0, 2, 0],
          [0, 0, 0, 2, 2, 0],
          [0, 0, 2, 2, 0, 0],
          [0, 2, 2, 0, 0, 0],
          [2, 2, 0, 0, 0, 0],
          [2, 0, 0, 0, 0, 0]
        ],
        [
          [0, 0, 0, 0, 0, 2],
          [0, 0, 0, 0, 0, 4],
          [0, 0, 0, 0, 0, 4],
          [0, 0, 0, 0, 0, 4],
          [0, 0, 0, 0, 0, 4],
          [0, 0, 0, 0, 0, 2]
        ]
      }
    ]

    Enum.each(test_grids, fn {input, expected} ->
      assert {:ok, grid} = input |> Grid.from_list!() |> Grid.make_move(:right)

      # Verify that the grid contains a cell with number 1 in it
      one_coord = Grid.find_n_coord(grid, 1)
      assert one_coord

      # Erase the randomly generated number 1 before checking the updated grid
      # against the expected result.
      grid = Grid.put(grid, one_coord, 0)
      assert {input, Grid.to_list(grid)} == {input, expected}
    end)
  end

  test "make_move(:right) does not add 1 at random when no shifting has occurred" do
    test_grids = [
      {
        [
          [0, 0, 0, 1],
          [0, 0, 2, 1],
          [0, 0, 0, 8],
          [0, 0, 1, 8]
        ],
        [
          [0, 0, 0, 1],
          [0, 0, 2, 1],
          [0, 0, 0, 8],
          [0, 0, 1, 8]
        ]
      }
    ]

    Enum.each(test_grids, fn {input, expected} ->
      assert {:ok, grid} = input |> Grid.from_list!() |> Grid.make_move(:right)
      assert {input, Grid.to_list(grid)} == {input, expected}
    end)
  end
end
