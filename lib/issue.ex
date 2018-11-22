defmodule Issue.Server do
  use GenServer

  def init(url) do
    {:ok, url}
  end

  def handle_cast(:calculate, url) do
    issue = get(url)
    |> issue_to_map!
    |> IO.inspect()
    body = Map.fetch!(issue, "body")
    id = Map.fetch!(issue, "id")
    # res = body |> Code.eval_string
    res = "Done"
    commend(id, inspect(res))
    Issues.delete(url)
    {:noreply, url}
  end

  def handle_call(:get, _from, url) do
    get(url)
    |> issue_to_map!
    |> IO.inspect()
    {:reply, url, url}
  end

  def handle_call({:commend, comment}, _from, url) do
    get(url)
      |> issue_to_map!
      |> Map.fetch!("id")
      |> commend(comment)
    {:reply, url, url}
  end

  def get(url) when is_bitstring(url) do
    IO.inspect(url)

    resp =
      GraphQL.query!("""
      query {
        resource(url : "#{url}") {
          ... on Issue {
                body,
                number,
                state,
                title,
                id
              }
        }
      }
      """)
  end

  defp issue_to_map!(%{:body => body, :headers => headers, :status_code => 200}) do
    body
    |> IO.inspect()
    |> extract!()
  end

  defp issue_to_map!(%{:body => body, :headers => headers, :status_code => error}) do
    raise("[ERROR] HTTP error: #{error}, Reply: #{body}")
    :error
  end

  defp issue_to_map!(inp) do
    raise("[ERROR] Invalid input #{inp}")
    :error
  end

  def extract!(%{
        "data" => %{
          "resource" => %{
            "body" => body,
            "number" => number,
            "state" => state,
            "title" => title,
            "id" => id
          }
        }
      }) do
    %{"body" => body, "number" => number, "state" => state, "title" => title, "id" => id}
  end

  def extract!(invalid_body) do
    raise("[ERROR] invalid_body: #{inspect(invalid_body)}")
  end

  def commend(issue_id, comment_text) do
    GraphQL.query!("""
      mutation {
        addComment(input: {body: "#{comment_text}", subjectId: "#{issue_id}"}) {
          subject { id }
        }
      }
    """)
  end
end
