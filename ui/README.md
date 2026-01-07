# @book/ui

Formal UI library for the working examples book.

## Local Use

To publish locally (increments version and creates a package):
```bash
./publish_local.sh --bump
```

To use in another project:
```bash
npm install ../path/to/libraries/ui
```

## Public Publication

1. Copy `.env.example` to `.env` and add your `NPM_TOKEN`.
2. Run the publication script:
```bash
./publish_public.sh
```
