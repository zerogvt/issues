defmodule GraphQL do
  def query!(qstring) do
    token = System.get_env("GH_TOKEN")
    Neuron.Config.set(url: "https://api.github.com/graphql")
    Neuron.Config.set(headers: [Authorization: "Bearer #{token}"])

    Neuron.query(qstring)
    |> handle_response!()
  end

  def handle_response!({:ok, resp}) do
    %{:status_code => status_code, :body => body, :headers => headers} = resp
  end

  def handle_response!({_, resp}) do
    raise("[ERROR]: #{inspect(resp)}")
  end

  def body(%{:body => body, :headers => _, :status_code => _}), do: body
  def headers(%{:body => _, :headers => headers, :status_code => _}), do: headers
  def status_code(%{:body => _, :headers => _, :status_code => status_code}), do: status_code

end
