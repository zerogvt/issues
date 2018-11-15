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
  def pagination(cursor) do
    if cursor do
      """
        ,after: \\"#{cursor}\\"
        """
      else
        ""
      end
    end

  def get_page(cursor) do
    token = System.get_env("GH_TOKEN")
    org = "octocat"
    repo = "Hello-World"
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
    IO.puts(query)
    query2 = """
    {"query": "query { viewer { login }}"}
    """
    resp = HTTPoison.post!("https://api.github.com/graphql",
                            query,
                            [{"Content-Type", "application/json"},
                            {"Authorization", "Bearer #{token}"}])
    {status_code, body} = { Map.get(resp, :status_code), Map.get(resp, :body) }
  end

  def get(cursor, pagenum \\ 0) do
    if pagenum > 5 do
      Process.exit(self, :normal)
    end
    {status_code, body} = get_page(cursor)
    case {status_code, body} do
      {200, _} ->
        Poison.Parser.parse!(body)
        |> Map.get("data")
        |> Map.get("repository")
        |> Map.get("issues")
        |> Map.get("edges")
        |> Enum.at(-1)
        |> Map.get("cursor")
        |> IO.inspect
        |> get(pagenum + 1)
        :ok
      _ ->
        IO.inspect(status_code)
        IO.inspect("[ERROR]")
        :error
    end
  end


end
