defmodule SlidingNumbers.Game.Grid.Direction do
  @moduledoc """
  Utility module that enables compile-time checking of atom constants.
  """

  @typedoc """
  The direction in which to shift all numbers on a grid.
  """
  @type t :: :left | :right | :up | :down

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      alias unquote(__MODULE__)
    end
  end

  defguard is_direction(atom) when atom in [:left, :right, :up, :down]

  defmacro left, do: :left
  defmacro right, do: :right
  defmacro up, do: :up
  defmacro down, do: :down
end
