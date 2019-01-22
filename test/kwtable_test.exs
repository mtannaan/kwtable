defmodule KWTableTest do
  use ExUnit.Case
  doctest KWTable
  doctest KWTable.Groupby

  import KWTable.Samples

  test "normalize" do
    s = KWTable.Samples.simple1()
    assert s |> KWTable.normalize() === s
  end

  test "normalize missing 1" do
    assert missing1() |> KWTable.normalize() === missing1_normalized()
  end

  test "normalize missing 2" do
    assert missing2() |> KWTable.normalize() === missing2_normalized()
  end

  @tag :dup
  test "normalize dup 2" do
    assert dup2() |> KWTable.normalize() === dup2_normalized()
  end
end
