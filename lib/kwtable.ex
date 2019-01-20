defmodule KWTable do
  @moduledoc """
  Documentation for KWTable.
  """

  @typedoc """
  a table represented by keyword lists,
  where keyword lists represents each rows.

  A table:

  | a  | b |
  | ------------- | ------------- |
  | 1  | 2  |
  | 3  | 4  |

  is represented by:

  ```elixir
  [
    [a: 1, b: 2],
    [a: 3, b: 4]
  ]
  ```
  """
  @type t :: [row]
  @type row :: Keyword.t()

  @spec normalize(t, any) :: t
  def normalize(table, fill \\ nil) do
    cols_by_rows = table |> Enum.map(&Keyword.keys/1)

    cols = cols_by_rows |> Stream.concat() |> Enum.uniq()

    unless cols_by_rows |> Enum.flat_map(&duplicates/1) |> Enum.empty?() do
      raise ArgumentError, message: "duplicate column name is not supported yet"
    end

    table |> Enum.map(fn row -> interpolate_row(row, cols, fill) end)
  end

  @doc """
  lists duplicate items in `items`

  ## Examples
    iex> KWTable.duplicates([1, 2, 3, 1, 2])
    [1, 2]

    iex> KWTable.duplicates([:a, :b, :c])
    []
  """
  def duplicates(items) do
    {_founds, out_dups} =
      items
      |> Enum.reduce({[], []}, fn key, {founds, dups} ->
        if key in founds do
          if key not in dups do
            {founds, dups ++ [key]}
          else
            {founds, dups}
          end
        else
          {[key | founds], dups}
        end
      end)

    out_dups
  end

  @doc """
  interpolate a row to fit cols

  ## Examples
    iex> KWTable.interpolate_row([a: 1, c: 3], [:a, :b, :c, :d], 255)
    [a: 1, b: 255, c: 3, d: 255]
  """
  def interpolate_row(row, cols, fill \\ nil) do
    cols
    |> Enum.map(fn col ->
      case Keyword.get_values(row, col) do
        [value] -> {col, value}
        [] -> {col, fill}
      end
    end)
  end
end
