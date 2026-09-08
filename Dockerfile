# ---- Build Stage ----
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get upgrade -y && apt-get install -y python3 python3-venv && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -U pip setuptools wheel msgpack
RUN pip install --no-cache-dir "mcpo==0.0.20" "mcp<2.0.0"
RUN pip uninstall -y pip setuptools wheel

# ---- Final Stage ----
FROM node:22-bookworm-slim

# Upgrade packages to fix OS vulnerabilities and install runtime deps
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    python3 \
    chromium \
    curl \
    fonts-liberation \
    fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install @marp-team/marp-cli and @masaki39/marp-mcp globally, update, and completely remove npm cache in ONE layer
RUN npm install -g npm@latest && \
    npm install -g @marp-team/marp-cli @masaki39/marp-mcp@latest && \
    npm update -g && \
    npm cache clean --force && \
    rm -rf /root/.npm

# Log the resolved versions at build time
RUN echo "Installed packages:" && npm list -g --depth=0 || true

# Create and switch to non-root user
RUN useradd -m -s /bin/bash marpuser
USER marpuser
WORKDIR /home/marpuser

# Set HOME explicitly so npm/npx writes cache to the writable user home (fixes EACCES)
ENV HOME=/home/marpuser

# Set environment variables for Chromium/Puppeteer
ENV CHROME_PATH=/usr/bin/chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Expose the API port
EXPOSE 8090

# Healthcheck hitting the mcpo /docs endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8090/docs || exit 1

# Entrypoint using shell form to expand environment variable
ENTRYPOINT ["sh", "-c", "exec mcpo --host 0.0.0.0 --port 8090 --api-key \"${MCPO_API_KEY}\" -- npx -y @masaki39/marp-mcp@latest"]
