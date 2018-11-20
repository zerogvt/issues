defmodule Issue.Server do
  use GenServer

  def init(url) do
    { :ok, url }
  end

  def handle_call(:get, _from, _url) do
    get_issue(_url) |> IO.inspect
    {:reply, _url, _url }
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
              title
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
end
