# dericbourg.dev

Professional website, built with [Hugo](https://gohugo.io/).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Make (optional, but recommended)

## Local development

### With Make (recommended)

```bash
# Start the development server (http://localhost:1313)
make serve

# Get an interactive shell with Hugo
make shell

# Rebuild the Docker image
make build

# Clean up Docker images
make clean
```

### Without Make

```bash
# Generate the .env file (needed once)
echo "HUGO_VERSION=$(cat .hugo-version)" > .env
echo "GO_VERSION=$(cat .go-version)" >> .env

# Start the development server
docker compose up hugo

# Get an interactive shell
docker compose run --rm shell
```

### Useful Hugo commands

Once in the shell (`make shell`), you can use Hugo directly:

```bash
# Create new content
hugo new content/posts/my-article.md

# Build the site (generates in /public)
hugo

# Build with minification
hugo --minify
```

## Version management

The Hugo and Go versions are centralized in dedicated files:

| File | Description |
|------|-------------|
| `.hugo-version` | Hugo version (used by Makefile and GitHub Actions) |
| `.go-version` | Go version (required for Hugo Modules) |

To update versions:

```bash
echo "0.150.0" > .hugo-version
echo "1.24.5" > .go-version
make build  # Rebuild the Docker image
```

## Deployment

The site is automatically deployed to GitHub Pages on push to the `main` branch.

### GitHub Actions workflow

The `.github/workflows/hugo.yaml` file defines the deployment pipeline:

1. **Checkout**: Retrieves the source code with submodules (theme)
2. **Read Hugo version**: Reads `.hugo-version` to ensure consistency with local development
3. **Install Hugo**: Downloads and installs Hugo Extended
4. **Build**: Generates the static site with `hugo --gc --minify`
5. **Deploy**: Publishes to GitHub Pages

## Project structure

```
.
├── .hugo-version        # Hugo version (single source of truth)
├── .go-version          # Go version (for Hugo Modules)
├── hugo.toml            # Hugo configuration
├── go.mod               # Hugo Modules dependencies
├── content/             # Site content (Markdown)
├── static/              # Static files (images, etc.)
├── Dockerfile           # Docker image for Hugo + Go
├── docker-compose.yaml  # Docker services (hugo, shell)
└── Makefile             # Development commands
```
