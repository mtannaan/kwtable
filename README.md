# KWTable

Manipulates keyword list-based tables.

A table like:

| a  | b |
| ------------- | ------------- |
| 1  | 2  |
| 3  | 4  |

is represented by:

```elixir
[
  [a: 1, b: 2],
  [a: 3, b: 4]
]
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kwtable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kwtable, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kwtable](https://hexdocs.pm/kwtable).

