defmodule KWTable.Groupby do
  @moduledoc """
  Handles output of `KWTable.groupby`
  """

  @doc """
  Aggregate by specified function.
  Values for each group for each column are passed to `fun`.

  ## Examples
    iex> KWTable.groupby([[a: 1, b: 2], [a: 1, b: 3], [a: 9, b: 4]], :a) |>
    ...> KWTable.Groupby.agg(&Enum.sum/1)
    [[a: 1, b: 5], [a: 9, b: 4]]

    iex> KWTable.groupby([[a: 1, b: "1"], [a: 1, b: "2"]], :a) |>
    ...> KWTable.Groupby.agg(& Enum.join(&1, ","))
    [[a: 1, b: "1,2"]]
  """
  def agg(groupby, fun, fillna \\ nil) do
    groupby
    |> Enum.map(fn {key, rows} ->
      cols = rows |> KWTable.to_colbased(fillna)

      agged_cols =
        cols
        |> Enum.map(fn {col, values} ->
          {col, fun.(values)}
        end)

      key ++ agged_cols
    end)
  end
end
