defmodule Issues do
  @moduledoc """
  Documentation for Issues.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Issues.hello()
      :world

  """
  def pagination(cursor) when is_bitstring(cursor) do
      """
      , after: \\"#{cursor}\\"
      """
  end
  def pagination(_) do
    ""
  end

  def get_issues(org, repo, cursor \\ nil) do
    token = System.get_env("GH_TOKEN")
    query = """
    { "query": "query {
      repository(owner:\\"#{org}\\", name:\\"#{repo}\\") {
        issues(first:5 #{pagination(cursor)}, states:CLOSED) {
          edges {
            node {
              title url labels(first:5) {
                 edges {
                   node {
                     name
                   }
                 }
              }
            }
            cursor
          }
        }
      }
    }"}
    """ |> String.replace("\n", "")
    resp = HTTPoison.post!("https://api.github.com/graphql",
                            query,
                            [{"Content-Type", "application/json"},
                            {"Authorization", "Bearer #{token}"}])
    { Map.get(resp, :status_code), Map.get(resp, :body) }
  end

  def issues(cursor, pagenum \\ 0)
  def issues(:finished, _), do: :finished
  def issues(_, pagenum) when pagenum > 100, do: :max_pages_reached
  def issues(cursor, pagenum) do
    resp = get_issues("octocat", "Hello-World", cursor)
    |> IO.inspect
    |> handle_response()
    |> issues(pagenum + 1)
  end

  defp handle_response({200, body}) do
    body
    |> Poison.Parser.parse!()
    |> extract_edges!()
    |> handle_edges()
    |> last_cursor()
  end
  defp handle_response(_), do: :error

  defp last_cursor([]), do: :finished
  defp last_cursor(edges) when is_list(edges) do
    edges
    |> Enum.at(-1)
    |> Map.get("cursor")
    |> IO.inspect
  end

  defp extract_edges!(%{"data" => %{"repository" => %{"issues" => %{"edges" => edges}}}}) do
    edges
  end

  defp extract_edges!(invalid_body) do
    raise("invalid_body: #{inspect(invalid_body)}")
  end

  defp handle_edges([]), do: :ok
  defp handle_edges(edges) when is_list(edges) do
    edges
    |> Enum.map(&( &1 |> Map.get("node") |> Map.get("url")))
    |> Enum.map(&(mytask(&1)))
    edges
  end

  def mytask(url) do
    Task.start( fn ->
      Process.sleep(1000);
      "Task: " <> IO.inspect(url)
    end)
  end

end
