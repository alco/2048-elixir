defmodule SlidingNumbers.Game.Grid do
  @moduledoc """
  The grid data structure and core game logic.
  """

  defstruct [:size, :cells, :empty_set, :transitions]

  alias __MODULE__, as: Grid
  use Grid.Direction

  # Type of the value stored in a non-empty grid cell.
  @typep cell_value :: pos_integer

  # A transition describes how a single cell changes its state from the previous
  # grid cell to the current one following a move.
  @typep transition ::
           {:shift, coord, coord, cell_value}
           | {:merge, coord, coord, cell_value}
           | {:appear, coord, cell_value}

  @typedoc """
  Grid is the core data structure of the game.

  The `size` field defines the number of rows and columns in the grid. It is
  always a square.

  The `cells` field stores the contents of the grid.

  The `empty_set` field is used internally, it stores a set of all empty grid cells.

  The `transitions` field stores a list of transitions made by individual cells
  during a single move. It can be used to animate the transition from the
  previous grid state to the current one.
  """

  # NOTE: A brief explanation of the data type chosen to represent the grid.
  #
  # A game like this is easy to implement in an imperative language with mutable
  # arrays. In a functional language like Elixir tuples can sometimes be used as
  # substitute for array. However, updating a single tuple element requires
  # copying of the whole tuple. Doing these updates in a loop may quickly
  # produce a lot of work for the garbage collector.
  #
  # Erlang has an implementation of purely-functional arrays included, see the
  # `:array` module. It uses a tree-like data structure under the hood to make
  # modifications of array elements at random indices more efficient.
  #
  # In spite of that, I decided to use a single tuple for grid representation
  # for the following reasons:
  #
  #   - it provides maximimum read performance compared to other container types
  #
  #   - updates can be made by building a list of non-default tuple elements along
  #     with their indices and passing that to `:erlang.make_tuple/3`
  #
  #   - the latter function is a builtin implemented in C, so it efficiently
  #     builds a new tuple without wasteful memory allocations

  @type t :: %Grid{
          size: pos_integer,
          cells: tuple,
          empty_set: MapSet.t() | nil,
          transitions: [transition] | nil
        }

  @typedoc """
  A pair of coordinates used to look up and update cells in the grid.
  """
  @type coord :: {non_neg_integer, non_neg_integer}

  @doc """
  Seed the PRNG in the current process enable generation of repeatable
  pseudo-random number sequences.
  """
  @spec seed(integer) :: :ok
  def seed(seed) when is_integer(seed) do
    _ = :rand.seed(:default, seed)
    :ok
  end

  @doc """
  Create a new grid of the given size.

  The grid is populated by a single number 2 placed at random coordinates.
  """
  @spec new(pos_integer) :: t
  def new(size) when is_integer(size) and size >= 2 do
    random_index = :rand.uniform(size * size) - 1
    coord = index_to_coord(random_index, size)
    %Grid{size: size, cells: create_cells(size, [{coord, 2}])}
  end

  @doc """
  Get the cell value at the specified coordinates.
  """
  @spec get(t, coord) :: integer
  def get(%Grid{} = grid, {_x, _y} = coord) do
    elem(grid.cells, coord_to_index(coord, grid.size))
  end

  @doc """
  Put a new value into the grid cell at the given coordinates.
  """
  @spec put(t, coord, cell_value) :: t
  def put(%Grid{} = grid, {_x, _y} = coord, n) when is_integer(n) and n > 0 do
    %{grid | cells: put_elem(grid.cells, coord_to_index(coord, grid.size), n)}
  end

  @doc """
  Shift numbers in the specified direction and check for a game over condition.

  If, following the move, there's at least one cell containing number 2048, the
  game is won and `{:won, <grid>}` is returned.

  Otherwise, if there are empty cells remaining, a random empty cell is
  populated with number 1 and `{:ok, <grid>}` is returned with the new grid
  state.

  If no more empty cells are remaining, even though the specification for the
  coding task treats this as lost game, another move might still be possible if
  it involves merging existing cells; `{:ok, <grid>}` is returned in that case.

  If none of the above pans out, the game is lost and `{:lost, <grid>}` is
  returned.
  """
  @spec make_move(t, Direction.t()) :: {:ok | :won | :lost, t}
  def make_move(%Grid{} = grid, direction) when is_direction(direction) do
    next_grid = shift_numbers(grid, direction)

    cond do
      next_grid.cells == grid.cells ->
        # All numbers remain in the same places, so this does not count as a move.
        # Therefore we don't need to put a new number.
        {:ok, next_grid}

      find_n_coord(next_grid, 2048) ->
        {:won, next_grid}

      true ->
        # In addition to calculating new cell positions, the shift_numbers()
        # function call above also populates the `empty_cell` field on the
        # returned grid which is a MapSet of coordinates of all empty grid cells.
        #
        # This is not an inefficient way of finding a random empty cell on the grid
        # but considering the small grid sizes we're dealing with, I've decided
        # to trade efficiency for simplicity.
        coord = Enum.random(next_grid.empty_set)

        # NOTE: using `put()` here is expensive in principle because it creates
        # a copy of the cells tuple. In practical terms, though, we're dealing
        # with very small grid sizes, so it's an alright trade-off to make as
        # opposed to making the implementation of `shift_numbers()` more complex.
        next_grid = %{
          put(next_grid, coord, 1)
          | empty_set: MapSet.delete(next_grid.empty_set, coord),
            transitions: [transition_appear(coord, 1) | next_grid.transitions]
        }

        check_loss_condition(next_grid)
    end
  end

  # Shift all numbers on the grid in the specified direction.
  #
  # The returned grid will also have its `empty_set` and `transitions` fields
  # populated.
  @spec shift_numbers(t, Direction.t()) :: t
  defp shift_numbers(grid, direction) do
    {new_coords, transitions} =
      case direction do
        right() -> calculate_shifted_coords(grid, 1, 0)
        left() -> calculate_shifted_coords(grid, -1, 0)
        up() -> calculate_shifted_coords(grid, 0, -1)
        down() -> calculate_shifted_coords(grid, 0, 1)
      end

    cells = create_cells(grid.size, new_coords)
    empty_set = create_empty_set(grid.size, new_coords)

    %{grid | cells: cells, empty_set: empty_set, transitions: transitions}
  end

  # Calculate new positions for non-empty grid cells.
  #
  # This returns a list of pairs {<coordinates>, <number>} where
  # <number> > 0. The new grid state can then determined by creating a new empty
  # grid and populating it with the numbers from this list.
  #
  # Additionally, a list of transitions is returned that describes how each cell
  # value has ended up in its current state: it has either been moved from a
  # different position or created as a result of merging two other cells.
  #
  # The algorithm implemented here works both for horizontal and vertical shifts.
  # `xdir` and `ydir` are used to define the direction and to
  # increment/decrement the loop counter maintained by `shift_loop()`.
  @spec calculate_shifted_coords(t, -1 | 0 | 1, -1 | 0 | 1) ::
          {[{coord, cell_value}], [transition]}
  defp calculate_shifted_coords(grid, xdir, ydir) do
    dir = xdir + ydir

    # coord_fun builds a coordinate tuple from two loop counters. Depending on
    # whether the shifting direction is horizontal or vertical, the two loop counters
    # iterate over rows first, then columns, or the other way around.
    coord_fun =
      case {xdir, ydir} do
        {0, _} -> fn i, j -> {i, j} end
        {_, 0} -> fn i, j -> {j, i} end
      end

    # Each call to `shift_loop()` below produces a list of coordinate-number
    # pairs that define new positions for cell values belonging to a single grid
    # row or column.
    #
    # The variables `dir` and `limit` are working together here to drive the
    # nested loop counter either from 0 to grid.size-1 or in the other direction.
    {list_of_accs, list_of_trans} =
      Enum.reduce(0..(grid.size - 1), {[], []}, fn i, {list_of_accs, list_of_trans} ->
        limit =
          case dir do
            -1 -> 0
            1 -> grid.size - 1
          end

        {acc, trans} = shift_loop(grid, dir, coord_fun, i, limit, limit, nil, [], [])
        {[acc | list_of_accs], [trans | list_of_trans]}
      end)

    {List.flatten(list_of_accs), List.flatten(list_of_trans)}
  end

  defp shift_loop(grid, _, _, _, j, _, _, acc, trans) when j < 0 or j == grid.size,
    do: {acc, trans}

  defp shift_loop(grid, dir, coord_fun, i, j, limit, merge_candidate, acc, trans) do
    current_coord = coord_fun.(i, j)

    case {get(grid, current_coord), merge_candidate} do
      {0, _} ->
        shift_loop(grid, dir, coord_fun, i, j - dir, limit, merge_candidate, acc, trans)

      {n, {merge_coord, n}} ->
        # The current cell has the same value as the merge candidate from a
        # previous loop iteration. This means we have a merge of two adjacent
        # cells, hence the doubling of the value of the most recently added
        # coordinate-number pair in `acc`.
        merge_candidate = nil
        acc = List.replace_at(acc, 0, {merge_coord, n * 2})

        # When it comes to animating the transition, we need to account both for
        # the shifting of the old cell and the creation of a new one as a result
        # of the merge, hence the following two transitions.
        trans = [
          transition_merge(current_coord, merge_coord, n * 2),
          transition_shift(current_coord, merge_coord, n)
          | trans
        ]

        shift_loop(grid, dir, coord_fun, i, j - dir, limit, merge_candidate, acc, trans)

      {n, _} ->
        new_coord = coord_fun.(i, limit)

        # At each iteration of the loop, we're keeping track of the last seen
        # number so that on the next iteration we can check if a merge of two
        # cells is going to occur.
        merge_candidate = {new_coord, n}

        acc = [merge_candidate | acc]
        trans = [transition_shift(current_coord, new_coord, n) | trans]

        shift_loop(grid, dir, coord_fun, i, j - dir, limit - dir, merge_candidate, acc, trans)
    end
  end

  defp check_loss_condition(grid) do
    if MapSet.size(grid.empty_set) > 0 or valid_move?(grid, right()) or valid_move?(grid, left()) or
         valid_move?(grid, up()) or valid_move?(grid, down()) do
      {:ok, grid}
    else
      {:lost, grid}
    end
  end

  defp valid_move?(grid, direction) do
    next_grid = shift_numbers(grid, direction)
    next_grid.cells != grid.cells
  end

  ###
  # Debug or test-only functions
  ###

  @doc """
  Create a new grid from the given list of lists of numbers.

  This can be useful in tests and when debugging.

  Example:

      Grid.from_list!([
        [0, 0, 0, 1],
        [0, 0, 2, 1],
        [0, 0, 0, 2],
        [0, 0, 2, 4]
      ])
  """
  @spec from_list!([[integer]]) :: t
  def from_list!([h | _] = list) do
    size = length(h)

    if size != length(list) do
      raise "Invalid grid dimensions"
    end

    cells =
      list
      |> Enum.flat_map(fn row ->
        if length(row) != size do
          raise "Invalid grid dimensions"
        end

        row
      end)
      |> List.to_tuple()

    %Grid{size: size, cells: cells}
  end

  @doc """
  Dump grid's state into a list of lists of numbers.

  The list shape prints nicely with IO.inspect() and makes diffs in failed tests
  easy to read.
  """
  @spec to_list(t) :: [[integer]]
  def to_list(%Grid{} = grid) do
    for row <- 1..grid.size do
      for col <- 1..grid.size do
        get(grid, {col - 1, row - 1})
      end
    end
  end

  @doc """
  Print grid's state, one row per line.
  """
  @spec pretty_print(t) :: :ok
  def pretty_print(%Grid{} = grid) do
    grid.cells
    |> Tuple.to_list()
    |> Stream.chunk_every(grid.size)
    |> Enum.each(&IO.inspect/1)
  end

  @doc false
  # Test helper.
  def shift_right(grid), do: shift_numbers(grid, right())

  @doc false
  # Test helper.
  def shift_left(grid), do: shift_numbers(grid, left())

  @doc false
  # Test helper.
  def shift_up(grid), do: shift_numbers(grid, up())

  @doc false
  # Test helper.
  def shift_down(grid), do: shift_numbers(grid, down())

  ###
  # Utility functions
  ###

  @doc """
  Find the coordinates of the first grid cell with the value `n`.

  If no such cell is found, `nil` is returned.
  """
  @spec find_n_coord(t, cell_value) :: coord | nil
  def find_n_coord(%Grid{} = grid, n) when n > 0 do
    index = find_n_index_loop(grid.cells, n, 0)
    if index, do: index_to_coord(index, grid.size)
  end

  defp find_n_index_loop(tuple, _n, i) when i == tuple_size(tuple), do: nil

  defp find_n_index_loop(tuple, n, i) do
    if elem(tuple, i) == n do
      i
    else
      find_n_index_loop(tuple, n, i + 1)
    end
  end

  defp create_cells(size, coords) do
    tuple_elements =
      for {coord, n} <- coords do
        {coord_to_erl_index(coord, size), n}
      end

    :erlang.make_tuple(size * size, 0, tuple_elements)
  end

  defp create_empty_set(size, coords) when is_list(coords) do
    coords_set = MapSet.new(coords, fn {coord, _n} -> coord end)

    for i <- 0..(size - 1), j <- 0..(size - 1) do
      {i, j}
    end
    |> MapSet.new()
    |> MapSet.difference(coords_set)
  end

  # Convert the internal cell array index to a coordinates tuple.
  defp index_to_coord(index, size) when index >= 0 and index < size * size and size > 0 do
    x = rem(index, size)
    y = div(index, size)
    {x, y}
  end

  # Convert a coordinates tuple to an internal cell array index.
  defp coord_to_index({x, y}, size), do: x + y * size

  # Same as `coord_to_index/2` but convert to a one-based index for use with Erlang functions.
  defp coord_to_erl_index(coord, size), do: 1 + coord_to_index(coord, size)

  # Constructor functions for transitions.
  defp transition_shift(from_coord, to_coord, n), do: {:shift, from_coord, to_coord, n}
  defp transition_merge(from_coord, to_coord, n), do: {:merge, from_coord, to_coord, n}
  defp transition_appear(coord, n), do: {:appear, coord, n}
end
