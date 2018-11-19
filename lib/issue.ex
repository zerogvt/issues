defmodule Issue.Server do
  use GenServer

  def init(url) do
    { :ok, url }
  end

  def handle_call(:get, _from, _url), do: { :reply, _url, _url }
end
