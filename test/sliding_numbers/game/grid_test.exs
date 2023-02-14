defmodule SlidingNumbers.Game.GridTest do
  use ExUnit.Case, async: true

  alias SlidingNumbers.Game.Grid
  use Grid.Direction

  describe "new()" do
    test "creates a grid with the given size" do
      for size <- 2..10 do
        grid = Grid.new(size)
        assert grid.size == size
        assert tuple_size(grid.cells) == size * size
      end
    end

    test "creates a grid that has a single non-empty cell with the number 2 in it" do
      for size <- 2..10 do
        grid = Grid.new(size)

        {num_empty, num_non_empty} =
          Enum.reduce(1..(size * size), {0, 0}, fn i, {num_empty, num_non_empty} ->
            case elem(grid.cells, i - 1) do
              0 -> {num_empty + 1, num_non_empty}
              2 -> {num_empty, num_non_empty + 1}
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
          # both input and expected grids are the same
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
        # multiple merges at once
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
        # larger grids
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
            [0, 0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0, 0],
            [4, 2, 0, 0, 2, 0, 4],
            [1024, 0, 0, 0, 0, 0, 1024],
            [1, 1, 1, 1, 1, 1, 1],
            [128, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 8]
          ],
          [
            [0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 2, 8, 16],
            [0, 0, 0, 0, 4, 4, 4],
            [0, 0, 0, 0, 0, 0, 2048],
            [0, 0, 0, 1, 2, 2, 2],
            [0, 0, 0, 0, 0, 0, 128],
            [0, 0, 0, 0, 0, 0, 8]
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
          # both input and expected grids are the same
          [
            [1, 0, 0, 0],
            [1, 2, 0, 0],
            [2, 0, 0, 0],
            [4, 2, 0, 0]
          ],
          [
            [1, 0, 0, 0],
            [1, 2, 0, 0],
            [2, 0, 0, 0],
            [4, 2, 0, 0]
          ]
        },
        # multiple merges at once
        {
          [
            [2, 2, 1, 1],
            [0, 1, 0, 1],
            [4, 8, 4, 0],
            [2, 2, 0, 4]
          ],
          [
            [4, 2, 0, 0],
            [2, 0, 0, 0],
            [4, 8, 4, 0],
            [4, 4, 0, 0]
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
            [4, 2, 0, 0],
            [2, 2, 0, 0],
            [16, 8, 8, 0],
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
            [16, 8, 8, 0],
            [16, 16, 0, 0],
            [32, 0, 0, 0],
            [32, 0, 0, 0]
          ]
        },
        # larger grids
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
        },
        # -----------------------
        {
          [
            [0, 0, 0, 0, 0, 0, 0],
            [2, 0, 0, 8, 16, 0, 0],
            [4, 2, 0, 0, 2, 0, 4],
            [1024, 0, 0, 0, 0, 0, 1024],
            [1, 1, 1, 1, 1, 1, 1],
            [128, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 8]
          ],
          [
            [0, 0, 0, 0, 0, 0, 0],
            [2, 8, 16, 0, 0, 0, 0],
            [4, 4, 4, 0, 0, 0, 0],
            [2048, 0, 0, 0, 0, 0, 0],
            [2, 2, 2, 1, 0, 0, 0],
            [128, 0, 0, 0, 0, 0, 0],
            [8, 0, 0, 0, 0, 0, 0]
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
    test "correctly shifts numbers up" do
      test_grids = [
        {
          # both input and expected grids are the same
          [
            [2, 4, 0, 1],
            [1, 2, 0, 4],
            [2, 0, 0, 1],
            [4, 0, 0, 0]
          ],
          [
            [2, 4, 0, 1],
            [1, 2, 0, 4],
            [2, 0, 0, 1],
            [4, 0, 0, 0]
          ]
        },
        # multiple merges at once
        {
          [
            [1, 2, 0, 4, 0],
            [1, 2, 4, 4, 2],
            [1, 0, 4, 4, 4],
            [1, 8, 32, 4, 1],
            [0, 8, 32, 4, 0]
          ],
          [
            [2, 4, 8, 8, 2],
            [2, 16, 64, 8, 4],
            [0, 0, 0, 4, 1],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
          ]
        },
        # larger grids
        {
          [
            [32, 2, 64, 4, 128, 0],
            [0, 2, 0, 4, 0, 0],
            [0, 2, 0, 8, 0, 0],
            [0, 2, 0, 8, 128, 0],
            [0, 2, 64, 16, 0, 0],
            [32, 2, 0, 16, 0, 0]
          ],
          [
            [64, 4, 128, 8, 256, 0],
            [0, 4, 0, 16, 0, 0],
            [0, 4, 0, 32, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0]
          ]
        },
        # -----------------------
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
        # both input and expected grids are the same
        {
          [
            [2, 0, 0, 0],
            [1, 0, 0, 1],
            [2, 4, 0, 4],
            [4, 2, 0, 1]
          ],
          [
            [2, 0, 0, 0],
            [1, 0, 0, 1],
            [2, 4, 0, 4],
            [4, 2, 0, 1]
          ]
        },
        # multiple merges at once
        {
          [
            [1, 2, 0, 4, 0],
            [1, 2, 4, 4, 2],
            [1, 0, 4, 4, 4],
            [1, 8, 32, 4, 1],
            [0, 8, 32, 4, 0]
          ],
          [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 4, 2],
            [2, 4, 8, 8, 4],
            [2, 16, 64, 8, 1]
          ]
        },
        # larger grids
        {
          [
            [32, 2, 64, 4, 128, 0],
            [0, 2, 0, 4, 0, 0],
            [0, 2, 0, 8, 0, 0],
            [0, 2, 0, 8, 128, 0],
            [0, 2, 64, 16, 0, 0],
            [32, 2, 0, 16, 0, 0]
          ],
          [
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0],
            [0, 4, 0, 8, 0, 0],
            [0, 4, 0, 16, 0, 0],
            [64, 4, 128, 32, 256, 0]
          ]
        },
        # -----------------------
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

  describe "make_move()" do
    test "shifts numbers in the specified direction and replaces a random empty cell with 1" do
      # NOTE: Make sure you don't have 1s in the expected grids below.
      test_grids = [
        {
          left(),
          [
            [0, 1, 1, 2],
            [4, 0, 4, 8],
            [1, 0, 0, 1],
            [0, 0, 0, 16]
          ],
          [
            [2, 2, 0, 0],
            [8, 8, 0, 0],
            [2, 0, 0, 0],
            [16, 0, 0, 0]
          ]
        },
        {
          up(),
          [
            [0, 0, 32, 4, 0],
            [0, 0, 0, 4, 0],
            [8, 0, 32, 4, 0],
            [0, 16, 64, 4, 0],
            [0, 8, 0, 8, 0]
          ],
          [
            [8, 16, 64, 8, 0],
            [0, 8, 64, 8, 0],
            [0, 0, 0, 8, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
          ]
        },
        {
          right(),
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
        },
        {
          down(),
          [
            [8, 2, 1, 0, 16, 4, 0, 512],
            [8, 0, 1, 0, 0, 0, 0, 0],
            [4, 0, 1, 0, 8, 0, 0, 0],
            [4, 0, 1, 0, 0, 2, 0, 0],
            [2, 0, 1, 0, 8, 0, 0, 0],
            [2, 0, 1, 0, 16, 1, 0, 512],
            [2, 0, 1, 0, 0, 1, 0, 0],
            [2, 0, 1, 0, 16, 0, 0, 0]
          ],
          [
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [16, 0, 2, 0, 0, 0, 0, 0],
            [8, 0, 2, 0, 16, 4, 0, 0],
            [4, 0, 2, 0, 16, 2, 0, 0],
            [4, 2, 2, 0, 32, 2, 0, 1024]
          ]
        }
      ]

      Enum.each(test_grids, fn {direction, input, expected} ->
        assert {:ok, grid} = input |> Grid.from_list!() |> Grid.make_move(direction)

        # Verify that the grid contains a cell with number 1 in it
        one_coord = Grid.find_n_coord(grid, 1)
        assert one_coord

        # Erase the randomly generated number 1 before checking for equivalence
        # with the expected grid.
        grid = Grid.put_internal(grid, one_coord, 0)
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end

    test "does not add 1 when no shifting has occurred" do
      test_grids = [
        {
          left(),
          [
            [1, 2, 0, 0],
            [0, 0, 0, 0],
            [8, 4, 2, 1],
            [1, 0, 0, 0]
          ],
          [
            [1, 2, 0, 0],
            [0, 0, 0, 0],
            [8, 4, 2, 1],
            [1, 0, 0, 0]
          ]
        },
        {
          right(),
          [
            [0, 0, 0, 0, 1],
            [0, 0, 0, 2, 1],
            [0, 0, 4, 1, 8],
            [0, 8, 2, 1, 8],
            [4, 2, 4, 1, 8]
          ],
          [
            [0, 0, 0, 0, 1],
            [0, 0, 0, 2, 1],
            [0, 0, 4, 1, 8],
            [0, 8, 2, 1, 8],
            [4, 2, 4, 1, 8]
          ]
        },
        {
          down(),
          [
            [0, 0, 0, 0, 1, 0],
            [0, 0, 0, 2, 4, 0],
            [0, 0, 4, 4, 8, 0],
            [0, 8, 2, 1, 2, 0],
            [8, 1, 8, 2, 8, 0],
            [4, 2, 4, 1, 1, 0]
          ],
          [
            [0, 0, 0, 0, 1, 0],
            [0, 0, 0, 2, 4, 0],
            [0, 0, 4, 4, 8, 0],
            [0, 8, 2, 1, 2, 0],
            [8, 1, 8, 2, 8, 0],
            [4, 2, 4, 1, 1, 0]
          ]
        },
        {
          up(),
          [
            [1, 0, 2, 8, 1, 4, 1],
            [2, 0, 0, 4, 4, 1, 4],
            [4, 0, 0, 8, 8, 0, 32],
            [8, 0, 0, 4, 2, 0, 0],
            [4, 0, 0, 0, 8, 0, 0],
            [2, 0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0, 0]
          ],
          [
            [1, 0, 2, 8, 1, 4, 1],
            [2, 0, 0, 4, 4, 1, 4],
            [4, 0, 0, 8, 8, 0, 32],
            [8, 0, 0, 4, 2, 0, 0],
            [4, 0, 0, 0, 8, 0, 0],
            [2, 0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0, 0]
          ]
        }
      ]

      Enum.each(test_grids, fn {direction, input, expected} ->
        assert {:ok, grid} = input |> Grid.from_list!() |> Grid.make_move(direction)
        assert {input, Grid.to_list(grid)} == {input, expected}
      end)
    end

    test "indicates when the game is lost" do
      test_grids = [
        {
          left(),
          [
            [1, 1, 4, 2],
            [8, 1, 8, 16],
            [2, 4, 2, 1],
            [1, 8, 1, 2]
          ]
        },
        {
          right(),
          [
            [2, 1, 8, 2, 2],
            [4, 1, 8, 2, 1],
            [8, 2, 4, 1, 8],
            [2, 1, 2, 8, 4],
            [4, 8, 4, 1, 2]
          ]
        },
        {
          down(),
          [
            [8, 4, 1, 4, 2, 1],
            [2, 2, 4, 2, 4, 8],
            [2, 1, 8, 4, 8, 2],
            [1, 8, 2, 1, 2, 4],
            [8, 1, 8, 2, 8, 2],
            [4, 2, 4, 1, 4, 1]
          ]
        },
        {
          up(),
          [
            [8, 4, 1, 4, 2, 1, 2],
            [2, 2, 4, 2, 4, 8, 4],
            [2, 1, 8, 4, 8, 4, 2],
            [2, 4, 2, 1, 2, 8, 4],
            [8, 1, 8, 2, 8, 4, 2],
            [4, 2, 4, 1, 4, 1, 4],
            [8, 4, 8, 2, 8, 2, 1]
          ]
        }
      ]

      Enum.each(test_grids, fn {direction, input} ->
        assert {:lost, _grid} = input |> Grid.from_list!() |> Grid.make_move(direction)
      end)
    end

    test "indicates when the game is won" do
      test_grids = [
        {
          left(),
          [
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [1024, 1024, 0, 0]
          ]
        },
        {
          right(),
          [
            [0, 0, 1024, 1024],
            [0, 512, 0, 512],
            [1, 1, 1, 1],
            [1024, 1024, 0, 0]
          ]
        },
        {
          up(),
          [
            [0, 0, 1024, 1024],
            [0, 512, 0, 512],
            [1, 1, 0, 1],
            [1024, 0, 1024, 0]
          ]
        },
        {
          down(),
          [
            [0, 0, 1024, 1024],
            [0, 512, 0, 1024],
            [1, 1, 0, 1024],
            [1024, 0, 1024, 1024]
          ]
        }
      ]

      Enum.each(test_grids, fn {direction, input} ->
        assert {:won, _grid} = input |> Grid.from_list!() |> Grid.make_move(direction)
      end)
    end
  end
end
