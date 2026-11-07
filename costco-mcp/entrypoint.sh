#!/usr/bin/env bash

python3 mcp-wrapper-http/http_wrapper.py --host 0.0.0.0 bash -c "pushd src; "

CMD ["python3", "mcp-wrapper-http/http_wrapper.py", "--host", "0.0.0.0", "python3", "src/costco_mcp_server/server.py", "--save-token", "personal", "${REFRESH_TOKEN}"]
