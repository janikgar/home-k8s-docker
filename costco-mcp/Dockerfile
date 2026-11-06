FROM python:3.15 AS dev

FROM dev AS build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_NO_DEV=1
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/app/.venv/bin:$PATH"

WORKDIR /app

RUN apt-get install gcc

COPY costco-mcp/uv.lock costco-mcp/pyproject.toml costco-mcp/README.md .python-version /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv python install

RUN --mount=type=cache,target=/root/.cache/uv \
    uv add 'Flask>=2.0.0'

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync

COPY costco-mcp .python-version /app

COPY mcp-wrapper-http/http_wrapper.py /app/src/mcp-wrapper-http/

RUN touch /app/src/mcp-wrapper-http/__init__.py

FROM dev AS final

WORKDIR /app
ENV PATH="/app/.venv/bin:$PATH"
ENV STAGE="PRODUCTION"

COPY --from=build /app /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    uv python install

ENV PATH="/app/.venv/bin:$PATH"

CMD ["python3", "src/mcp-wrapper-http/http_wrapper.py", "--host", "0.0.0.0", "costco-mcp-server", "--save-token", "personal", "${REFRESH_TOKEN}"]
