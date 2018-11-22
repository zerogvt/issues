defmodule Main do

  def main(argv) do
    [org | repo] = argv
    Issues.start_link
    Issues.issues(org, repo)
  end

end
