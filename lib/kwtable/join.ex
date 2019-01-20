defmodule KWTable.Join do
  @moduledoc """
  Join tables.
  """

  @doc """
  inner join.

  ## Options
    - `:on` - join key
    - `:on_left` - join key for `t1`. Exclusive with `:on`.
    - `:on_right` - join key for `t2`. Exclusive with `:on`.
    - `:delete_right_key` - Boolean.
    - `:validation` - one of `:one_to_one`, `:one_to_many`, and `:many_to_one`.
    - `:raise_when_duplicate` - Boolean. Defaults to false. When true, raises when resulting table has duplicate columns.
  """
  def inner(t1, t2, opts) do
    # get key columns
    {on_left, on_right} =
      cond do
        Keyword.has_key?(opts, :on) ->
          if Keyword.has_key?(opts, :on_left) or Keyword.has_key?(opts, :on_right) do
            raise ArgumentError,
              message: "keyword 'on' and 'on_left'/'on_right' cannot be given simultaneously."
          end

          {opts[:on], opts[:on]}

        Keyword.has_key?(opts, :on_left) and Keyword.has_key?(opts, :on_right) ->
          {opts[:on_left], opts[:on_right]}
      end

    # convert to list
    ensure_list = fn
      x when is_list(x) -> x
      x -> [x]
    end

    on_left = ensure_list.(on_left)
    on_right = ensure_list.(on_right)

    # key validations
    unless length(on_left) === length(on_right) do
      raise ArgumentError,
        message:
          "keys have to be the same number of members: #{inspect(on_left)}, #{inspect(on_right)}"
    end

    unless length(on_left) > 0 do
      raise ArgumentError, message: "join key is empty."
    end

    # one-to-many/many-to-one validations
    raise_if_error = fn
      :ok ->
        nil

      {:error, {:key_left, key_left}} ->
        raise "validation #{inspect(opts[:validation])} failed. key: #{inspect(key_left)}"
    end

    if opts[:validation] in [:many_to_one, :one_to_one] do
      raise_if_error.(assert_many_to_one(t1, t2, on_left, on_right))
    end

    if opts[:validation] in [:one_to_many, :one_to_one] do
      raise_if_error.(assert_many_to_one(t2, t1, on_right, on_left))
    end

    # return value
    ret =
      t1
      |> Enum.flat_map(fn r1 ->
        inner_single_row(r1, t2, on_left, on_right, opts[:delete_right_key])
      end)

    # check duplicate
    if opts[:raise_when_duplicate] do
      ret |> Enum.each(fn row ->
        cols = row |> Keyword.keys()
        dup_cols = (cols -- Enum.uniq(cols)) |> Enum.uniq()
        if length(dup_cols) > 0 do
          raise "duplicate columns: #{inspect(dup_cols)}"
        end
      end)
    end

    ret
  end

  defp inner_single_row(r1, t2, on_left, on_right, delete_right_key) do
    Stream.filter(t2, fn r2 -> keys_match?(r1, r2, on_left, on_right) end)
    |> Stream.map(fn r2 -> join_row(r1, r2, on_left, on_right, delete_right_key) end)
  end

  @doc """
  Whether if join keys matches.

  ## Examples
    iex> KWTable.Join.keys_match?([a: 1, b: 2, c: 3], [a: 1, b: 2, d: 444], [:a], [:a])
    true

    iex> KWTable.Join.keys_match?([a: 1, b: 2, c: 3], [a: 111, b: 2, d: 444], [:a], [:a])
    false

    iex> KWTable.Join.keys_match?([a: 1, b: 2, c: 3], [a: 1, b: 2, d: 444], [:a, :b], [:a, :b])
    true

    iex> KWTable.Join.keys_match?([a: 1, b: 2, c: 3], [a: 1, b: 3, d: 444], [:a, :b], [:a, :b])
    false
  """
  def keys_match?(r1, r2, on_left, on_right) do
    k1 = on_left |> Enum.map(fn key -> Keyword.fetch!(r1, key) end)
    k2 = on_right |> Enum.map(fn key -> Keyword.fetch!(r2, key) end)
    k1 === k2
  end

  @doc """
  If t1 and t2 have a many-to-one relation, returns :ok.

  ## Examples
    iex> KWTable.Join.assert_many_to_one([[a: 1, b: 11], [a: 2, b: 12]], [[a: 1, c: 21]], [:a], [:a])
    :ok

    iex> KWTable.Join.assert_many_to_one([[a: 1, b: 11], [a: 2, b: 12]], [[a: 1, c: 21], [a: 1, c: 29]], [:a], [:a])
    {:error, {:key_left, [a: 1]}}
  """
  @spec assert_many_to_one(list(), list(), list(), list()) ::
          :ok | {:error, {:key_left, Keyword.t()}}
  def assert_many_to_one(t1, t2, on_left, on_right) do
    count_matching_rows = fn r1 ->
      Enum.count(t2, fn r2 -> keys_match?(r1, r2, on_left, on_right) end)
    end

    case t1 |> Enum.find(nil, fn r1 -> count_matching_rows.(r1) > 1 end) do
      nil -> :ok
      r1 -> {:error, {:key_left, r1 |> Enum.filter(fn {key, _value} -> key in on_left end)}}
    end
  end

  @doc """
  join a single row.

  ## Examples
    iex> KWTable.Join.join_row([a: 1, b: 2], [a: 1, c: 3], :a, :a, nil)
    [a: 1, b: 2, a: 1, c: 3]
  """
  def join_row(r1, r2, _on_left, on_right, delete_right_key) do
    right =
      if delete_right_key do
        on_right
        |> Enum.reduce(r2, fn key, row -> Keyword.delete(row, key) end)
      else
        r2
      end

    r1 ++ right
  end
end
