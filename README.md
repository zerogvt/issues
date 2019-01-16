# Issues

Just a toy application I wrote while I'm learning Elixir and experiment with github graphQL API.
The application will scan a github repo and pick up all the open issues on it.
Then it will execute the body of each issue and write up the result as a commend
in that issue.

## WARNING
**The application is inherently unsafe. If you point it to a
malicious repository with say malicious commands in its issues bodies then you will
cause harm to the machine where you run this code.**

I have been testing it on this sample [repo](https://github.com/zerogvt/test_issues/issues).
Use a repo that you own/control if you play around with it.

## How to build/run:
1. Install elixir
2. clone locally
3. `mix escript.build`
4. `export GH_TOKEN=YOUR_GITHUB_API_TOKEN`
5. `./issues zerogvt test_issues`

<s>
## Installation
If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `issues` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:issues, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/issues](https://hexdocs.pm/issues).
</s>
