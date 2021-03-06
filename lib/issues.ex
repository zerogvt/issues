defmodule Issues do
  @moduledoc """
  """
  use GenServer

  # CLIENT API #
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add(url) do
    GenServer.call(__MODULE__, {:push, url})
  end

  def urls do
    GenServer.call(__MODULE__, :get)
  end

  def delete(url) do
    GenServer.call(__MODULE__, {:delete, url})
  end

  # SERVER #
  def init(stack) do
    {:ok, stack}
  end
  def handle_call({:push, item}, _from, state) do
    {:reply, state, [item | state]}
  end
  def handle_call({:delete, item}, _from, state) do
    {:reply, state, state -- [item]}
  end
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  # SERVER internals #
  def pagination(cursor) when is_bitstring(cursor) do
    """
    , after: "#{cursor}"
    """
  end

  def pagination(_) do
    ""
  end
  def get_issues(org, repo, cursor \\ nil) do
    q = """
    query {
      repository(owner:"#{org}", name:"#{repo}") {
        issues(first:20 #{pagination(cursor)}, states:OPEN) {
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
    }
    """
    |> GraphQL.query!
    |> GraphQL.body
  end

  def issues(org, repo, cursor \\ nil, pagenum \\ 0)
  def issues(_, _, :finished, _), do: :finished
  def issues(_, _, _, pagenum) when pagenum > 100, do: :max_pages_reached

  def issues(org, repo, cursor, pagenum) do
    cursor =
      get_issues(org, repo, cursor)
      |> handle_response
    issues(org, repo, cursor, pagenum + 1)
  end

  defp handle_response(body) do
    body
    |> extract_edges!()
    |> handle_edges()
    |> last_cursor()
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
    urls = edges |> Enum.map(&(&1 |> Map.get("node") |> Map.get("url")))
    urls |> Enum.map(&launch(&1, :genserv))
    urls |> Enum.map(&add(&1))
    IO.inspect(urls())
    # urls |> Enum.map(&(talk(&1, :genserv)))
    # urls |> Enum.map(&(stop(&1, :genserv)))
    wait
  end

  def wait do
    Process.sleep(1000)
    urls |> IO.inspect
    case length(urls) do
      0 -> :ok
      _ -> wait
    end
  end

  def launch(url, :tasks) do
    Task.start(fn ->
      Process.sleep(1000)
      IO.puts("Task: #{inspect(self())} - #{inspect(url)}")
    end)
  end

  def launch(url, :agents) do
    name = url |> String.split("/") |> List.last()

    Agent.start_link(
      fn ->
        IO.puts("Agent: #{name} - #{inspect(url)}")
      end,
      name: String.to_atom(name)
    )

    Agent.stop(String.to_atom(name))
  end

  def launch(url, :genserv) do
    name = url |> String.split("/") |> List.last() |> String.to_atom()
    case GenServer.start_link(Issue.Server, url, name: name) do
      {:ok, pid} -> GenServer.cast(pid, :calculate)
      {ret, pid} -> {ret, pid}
    end
  end

  def talk(url, :genserv) do
    name = url |> String.split("/") |> List.last() |> String.to_atom()
    GenServer.call(name, :get) |> IO.inspect()
  end

  def stop(url, :genserv) do
    name = url |> String.split("/") |> List.last() |> String.to_atom()
    GenServer.stop(name)
  end
end
