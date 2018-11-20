defmodule Issues do
  @moduledoc """
  """
  use Agent
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add(url) do
    Agent.update(__MODULE__, fn list -> [url|list] end)
  end

  def urls do
    Agent.get(__MODULE__, fn list -> list end)
  end

  #####################################################
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

  def issues(cursor \\ nil, pagenum \\ 0)
  def issues(:finished, _), do: :finished
  def issues(_, pagenum) when pagenum > 100, do: :max_pages_reached
  def issues(cursor, pagenum) do
    resp = get_issues("octocat", "Hello-World", cursor)
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
  defp handle_response({error, body}) do
    raise("HTTP error: #{error}, Reply: #{body}")
    :error
  end

  defp last_cursor([]), do: :finished
  defp last_cursor(edges) when is_list(edges) do
    edges
    |> Enum.at(-1)
    |> Map.get("cursor")
  end
  defp last_cursor(_), do: :finished


  def extract_edges!(%{"data" => %{"repository" => %{"issues" => %{"edges" => edges}}}}) do
    edges
  end

  def extract_edges!(invalid_body) do
    raise("invalid_body: #{inspect(invalid_body)}")
  end

  defp handle_edges([]), do: :ok
  defp handle_edges(edges) when is_list(edges) do
    urls = edges |> Enum.map(&( &1 |> Map.get("node") |> Map.get("url")))
    urls |> Enum.map(&(launch(&1, :genserv)))
    urls |> Enum.map(&(add(&1)))
    IO.inspect(urls())
    Process.sleep(1000)
    #urls |> Enum.map(&(talk(&1, :genserv)))
    #urls |> Enum.map(&(stop(&1, :genserv)))
    edges
  end

  def launch(url, :tasks) do
    Task.start( fn ->
      Process.sleep(1000);
      IO.puts "Task: #{inspect(self())} - #{inspect(url)}"
    end)
  end

  def launch(url, :agents) do
    name = url |> String.split("/") |> List.last
    Agent.start_link( fn ->
                          IO.puts "Agent: #{name} - #{inspect(url)}"
                      end,
                      name: String.to_atom(name) )
    Agent.stop(String.to_atom(name))
  end

  def launch(url, :genserv) do
    name = url |> String.split("/") |> List.last |> String.to_atom
    GenServer.start_link(Issue.Server, url, name: name)
  end

  def talk(url, :genserv) do
    name = url |> String.split("/") |> List.last |> String.to_atom
    GenServer.call(name, :get) |> IO.inspect()
  end

  def stop(url, :genserv) do
    name = url |> String.split("/") |> List.last |> String.to_atom
    GenServer.stop(name)
  end

end
