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
  def get() do
    token = "a5e6377d9115458bce189d0e6bb2c0e59ec3f4d7"
    org = "octocat"
    repo = "Hello-World"
    query = """
    { "query": "query {
      repository(owner:\\"#{org}\\", name:\\"#{repo}\\") {
        issues(last:20, states:CLOSED) {
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
    case {status_code, body} do
      {200, _} ->
        IO.inspect(body)
        :ok
      _ ->
        IO.inspect(resp)
        IO.inspect("[ERROR]")
        :error
    end
  end


end
