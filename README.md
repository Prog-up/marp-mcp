# marp-mcp Containerized

This repository provides a containerized version of the [marp-mcp](https://github.com/masaki39/marp-mcp) MCP server, wrapped behind an [mcpo](https://pypi.org/project/mcpo/) OpenAPI bridge.

## Usage

You can run the container standalone using Docker. The OpenAPI bridge runs on port **8090**.

```bash
docker run -d \
  --name marp-mcp \
  -e MCPO_API_KEY=your_secret_key \
  -p 8090:8090 \
  ghcr.io/prog-up/marp-mcp:latest
```

- **`MCPO_API_KEY`**: This environment variable is required to authenticate your requests against the `mcpo` proxy.
- **Port 8090**: The OpenAPI bridge is exposed on this port. You can visit `http://localhost:8090/docs` to see the Swagger UI for the MCP tools once running.

## PPTX and PDF Export (Chromium)

The `marp-mcp` server delegates slide export to `marp-cli`. While HTML export works out of the box without a browser, generating PDFs and images (including pre-rendered PPTX slides) requires Chromium. 

This Docker image comes with **headless Chromium pre-installed**. It automatically configures `marp-cli` and `puppeteer` to use the built-in Chromium binary (via `CHROME_PATH` and `PUPPETEER_EXECUTABLE_PATH`), so PPTX and PDF export will work out of the box without any additional configuration.
