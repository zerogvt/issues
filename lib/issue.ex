defmodule Issue.Server do
  use GenServer

  def init(url) do
    { :ok, url }
  end

  def handle_call(:get, _from, url) do
    get_issue(url)
    |> issue_to_map
    |> IO.inspect
    {:reply, url, url }
  end

  def handle_call({:commend, commend}, _from, url) do
    issue_id = get_issue(url) |> issue_to_map |> Map.fetch!("id")
    comment_issue(commend, issue_id) |> IO.inspect
    {:reply, url, url }
  end

  def get_issue(url) do
    token = System.get_env("GH_TOKEN")
    query = """
    { "query": "query {
      resource(url:\\"#{url}\\") {
        ... on Issue {
              body,
              number,
              state,
              title,
              id
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

  def comment_issue(commend, node_id) do
    token = System.get_env("GH_TOKEN")
    query = """
    { "query": "mutation {
        addComment(input: {body: \\"#{commend}\\", subjectId: \\"#{node_id}\\"}) {
          subject { id }
        }
      }
    }"}
    """ |> String.replace("\n", "") |> IO.inspect
    resp = HTTPoison.post!("https://api.github.com/graphql",
                            query,
                            [{"Content-Type", "application/json"},
                            {"Authorization", "Bearer #{token}"}])
    { Map.get(resp, :status_code), Map.get(resp, :body) }
  end

  defp issue_to_map({200, body}) do
    body
    |> Poison.Parser.parse!()
    |> extract!()
  end
  defp issue_to_map({error, body}) do
    raise("HTTP error: #{error}, Reply: #{body}")
    :error
  end

  def extract!(%{"data" => %{"resource" => %{"body" => body, "number" => number, "state" => state, "title" => title, "id" => id}}}) do
    %{"body" => body, "number" => number, "state" => state, "title" => title, "id" => id}
  end

  def extract!(invalid_body) do
    raise("invalid_body: #{inspect(invalid_body)}")
  end
end
