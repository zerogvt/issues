defmodule IssuesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Issues

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    ExVCR.Config.filter_request_headers("Authorization")
    :ok
  end

  setup_all do
    HTTPoison.start
  end

  test "extract_edges: invalid json raises an error" do
    assert_raise RuntimeError, fn -> Issues.extract_edges!("invalid") end
  end

  test "extract_edges: valid json is parsed" do
    data = %{"data" => %{"repository" => %{"issues" => %{ "edges" => ["A", "B", "C"]}}}}
    assert Issues.extract_edges!(data) == ["A", "B", "C"]
  end

  test "get issues" do
    use_cassette "get_issues" do
      Issues.get_issues("octocat", "Hello-World", nil)
    end
  end
end
