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
  def normalize(table, fillna \\ nil) do
    cols_by_rows = table |> Enum.map(&Keyword.keys/1)

    cols = cols_by_rows |> Stream.concat() |> Enum.uniq()

    unless cols_by_rows |> Enum.flat_map(&duplicates/1) |> Enum.empty?() do
      raise ArgumentError, message: "duplicate column name is not supported yet"
    end

    table |> Enum.map(fn row -> interpolate_row(row, cols, fillna) end)
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
  def interpolate_row(row, cols, fillna \\ nil) do
    cols
    |> Enum.map(fn col ->
      case Keyword.get_values(row, col) do
        [value] -> {col, value}
        [] -> {col, fillna}
      end
    end)
  end

  @doc """
  check if a table is already normalized (i.e. each row has no missing column)

  ## Examples
    iex> KWTable.normalized?([[a: 1, b: 2], [a: 3, b: 4]])
    true

    iex> KWTable.normalized?([[a: 1, b: 2], [a: 3, c: 5]])
    false
  """
  @spec normalized?(t) :: boolean
  def normalized?(table) do
    table |> Enum.dedup_by(&Keyword.keys/1) |> length() |> (fn x -> x in [0, 1] end).()
  end

  @spec column_keys(t) :: [atom()]
  def column_keys(table) do
    table
    |> Stream.concat()
    |> Stream.map(fn {k, _v} -> k end)
    |> Enum.uniq()
  end

  @doc """
  values of a single column

  ## Examples
    iex> KWTable.column([[a: 1, b: 2], [a: 3, b: 4]], :a)
    [1, 3]

    iex> KWTable.column([[a: 1, b: 2], [b: 4]], :a, 9999)
    [1, 9999]

    iex> KWTable.column([[a: 1, b: 2], [b: 4]], :c)
    [nil, nil]
  """
  def column(table, col_key, fillna \\ nil) do
    table
    |> Enum.map(fn row -> Keyword.get(row, col_key, fillna) end)
  end

  @doc """
  Select columns

  ## Examples
    iex> KWTable.select_columns([[a: 1, b: 2], [b: 4]], [:a], 9999)
    [[a: 1], [a: 9999]]
  """
  def select_columns(table, col_keys, fillna \\ nil) do
    table
    |> Enum.map(fn row ->
      Enum.map(col_keys, fn key ->
        {key, Keyword.get(row, key, fillna)}
      end)
    end)
  end

  @doc """
  Transform row-based (default) table to column-based one.

  ## Examples
    iex> KWTable.to_colbased([[a: 1, b: 2], [a: 3, b: 4], [a: 5, b: 6]])
    [a: [1, 3, 5], b: [2, 4, 6]]

    iex> KWTable.to_colbased([[a: 1, b: 2], [b: 4], [a: 5, b: 6]], 9999)
    [a: [1, 9999, 5], b: [2, 4, 6]]
  """
  def to_colbased(table, fillna \\ nil) do
    column_keys(table)
    |> Enum.map(fn key ->
      {key, Enum.map(table, fn row -> Keyword.get(row, key, fillna) end)}
    end)
  end

  @doc """
  Transforms keyword-based table to list-based,
  whose first row is a header containing column names.
  If fillna is not :raise, the table is normalized if not yet.

  ## Examples
    iex> KWTable.to_rows([[a: 1, b: 2], [a: 3, b: 4], [a: 5, b: 6]])
    [["a", "b"], [1, 2], [3, 4], [5, 6]]

    iex> KWTable.to_rows([[a: 1, b: 2], [a: 3], [a: 5, b: 6]], 255)
    [["a", "b"], [1, 2], [3, 255], [5, 6]]
  """
  @spec to_rows(t, :raise | any) :: [[any]]
  def to_rows(table, fillna \\ :raise) do
    norm_table =
      case {fillna, normalized?(table)} do
        {:raise, false} -> raise ArgumentError, message: "input table is not normalized"
        {_, false} -> table |> normalize(fillna)
        {_, true} -> table
      end

    cols = hd(norm_table) |> Keyword.keys() |> Enum.map(&Kernel.to_string/1)
    norm_table |> Enum.into([cols], &Keyword.values/1)
  end

  @doc """
  Group by specified columns.
  Returns list of {key cols, corresponding rows} tuples.

  ## Examples
    iex> KWTable.groupby([[a: 1, b: 2, c: 3], [a: 1, b: 4, c: 9], [a: 5, b: 6, c: 1]], :a)
    [{[a: 1], [[b: 2, c: 3], [b: 4, c: 9]]}, {[a: 5], [[b: 6, c: 1]]}]
  """
  def groupby(table, by) do
    by = List.wrap(by)
    table |> Enum.reduce([], &update_groups(&1, &2, by))
  end

  defp update_groups(row, groups, by) do
    key = Keyword.take(row, by)
    rest = Keyword.drop(row, by)
    {^key, rows} = List.keyfind(groups, key, 0, {key, []})
    List.keystore(groups, key, 0, {key, rows ++ [rest]})
  end

  @doc """
  converts table to an `Elixlsx.Sheet` struct
  """
  @spec to_sheet(t, sheet_opts) :: Elixlsx.Sheet.t()
  @type sheet_opts :: [{:fillna, :raise | any} | {:sheet_name, String.t()}]
  def to_sheet(table, opts \\ []) do
    fillna = Keyword.get(opts, :fillna, :raise)
    sheet_name = Keyword.get(opts, :sheet_name, "Sheet")
    %Elixlsx.Sheet{name: sheet_name, rows: to_rows(table, fillna)}
  end

  @doc """
  converts table to an `Elixlsx.Workbook` struct which has a single sheet.
  """
  @spec to_workbook(t, sheet_opts) :: Elixlsx.Workbook.t()
  def to_workbook(table, opts \\ []) do
    sheet = to_sheet(table, opts)
    %Elixlsx.Workbook{sheets: [sheet]}
  end

  @spec to_xlsx(t, String.t(), sheet_opts) :: {:ok, String.t()} | {:error, any()}
  def to_xlsx(table, file_name, opts \\ []) do
    table |> to_workbook(opts) |> Elixlsx.write_to(file_name)
  end
end
