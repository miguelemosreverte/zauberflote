# Shared

Core utilities and DSL for the working examples book.

## Local Use

To publish locally (increments version and compiles):
```bash
./publish_local.sh --bump
```

To use in another project, add this to your `mix.exs`:
```elixir
defp deps do
  [{:shared, path: "../path/to/libraries/shared"}]
end
```

## Public Publication

1. Copy `.env.example` to `.env` and add your `HEX_API_KEY`.
2. Run the publication script:
```bash
./publish_public.sh
```