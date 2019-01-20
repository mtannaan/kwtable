defmodule KWTable.Samples do
  @moduledoc """
  Sample data for test purposes.
  """

  def simple1() do
    [
      [a: 1, b: 2, c: 3],
      [a: 4, b: 5, c: 6],
      [a: 7, b: 8, c: 9],
      [a: 10, b: 11, c: 12]
    ]
  end

  def simple2() do
    [
      [a: 1, b: 2, d: 93],
      [a: 4, b: 5, d: 96],
      [a: 7, b: 8, d: 99],
      [a: 10, b: 11, d: 102]
    ]
  end

  def missing1() do
    [
      [a: 1, b: 2, c: 3],
      [a: 4, c: 6],
      [a: 7, b: 8, c: 9],
      [a: 10, b: 11, c: 12]
    ]
  end

  def missing1_normalized(fill \\ nil) do
    [
      [a: 1, b: 2, c: 3],
      [a: 4, b: fill, c: 6],
      [a: 7, b: 8, c: 9],
      [a: 10, b: 11, c: 12]
    ]
  end

  def missing2() do
    [
      [a: 1, b: 2, d: 93],
      [a: 4, b: 5, d: 96],
      [b: 8, d: 99],
      [a: 10, b: 11, d: 102]
    ]
  end

  def missing2_normalized(fill \\ nil) do
    [
      [a: 1, b: 2, d: 93],
      [a: 4, b: 5, d: 96],
      [a: fill, b: 8, d: 99],
      [a: 10, b: 11, d: 102]
    ]
  end

  def dup1() do
    [
      [a: 1, b: 2, a: 101, c: 3],
      [a: 4, b: 5, a: 104, c: 6],
      [a: 7, b: 8, a: 107, c: 9],
      [a: 10, b: 11, a: 110, c: 12]
    ]
  end

  def dup2() do
    [
      [a: 1, b: 2, d: 93, b: 102],
      [a: 4, b: 5, d: 96, b: 105],
      [b: 8, d: 99, a: 1008],
      [a: 10, b: 11, d: 102, b: 111]
    ]
  end

  def dup2_normalized(fill \\ nil) do
    [
      [a: 1, b: 2, d: 93, b: 102, a: fill],
      [a: 4, b: 5, d: 96, b: 105, a: fill],
      [a: fill, b: 8, d: 99, b: fill, a: 1008],
      [a: 10, b: 11, d: 102, b: 111, a: fill]
    ]
  end
end
