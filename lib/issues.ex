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
        issues(first:20 #{pagination(cursor)}, states:CLOSED) {
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
    {status_code, body} = { Map.get(resp, :status_code), Map.get(resp, :body) }
  end

  def get(cursor, pagenum \\ 0) do
    if pagenum > 100 do
      Process.exit(self, :normal)
    end
    {status_code, body} = get_issues("octocat", "Hello-World", cursor)
    case {status_code, body} do
      {200, _} ->
        edges = Poison.Parser.parse!(body)
        |> Map.get("data")
        |> Map.get("repository")
        |> Map.get("issues")
        |> Map.get("edges")
        if Enum.count(edges) == 0 do
          :ok
        else
          edges
          |> Enum.map(&( &1 |> Map.get("node") |> Map.get("url")))
          |> Enum.map(&(mytask(&1)))
          edges
          |> Enum.at(-1)
          # get last edge cursor
          |> Map.get("cursor")
          |> IO.inspect
          # recurse to get next page
          |> get(pagenum + 1)
          :ok
        end
      _ ->
        IO.inspect(status_code)
        IO.inspect("[ERROR]")
        :error
    end
  end

  def mytask(url) do
    Task.start( fn -> IO.puts("Task: " <> IO.inspect(url)) end)
  end

end
