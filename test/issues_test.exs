defmodule IssuesTest do
  use ExUnit.Case
  doctest Issues

  test "extract_edges: invalid json raises an error" do
    assert_raise RuntimeError, fn -> Issues.extract_edges!("invalid") end
  end

  test "extract_edges: valid json is parsed" do
    data = %{"data" => %{"repository" => %{"issues" => %{ "edges" => ["A", "B", "C"]}}}}
    assert Issues.extract_edges!(data) == ["A", "B", "C"]
  end
end
