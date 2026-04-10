---
name: Home Monitoring Stack
description: Home lab monitoring stack with Grafana, Loki, Mimir, Prometheus, Tempo, Home Assistant, Alloy
type: reference
---

# Home Monitoring Stack

A self-hosted monitoring and observability stack for a Synology NAS environment.

## Overview

This repository contains docker-compose configurations for a complete observability stack:
- **Grafana** - Visualization dashboards (port 30000)
- **Loki/Mimir** - Log aggregation and long-term storage (ports 30002, 30909)
- **Prometheus** - Metrics collection (port 30001)
- **Tempo** - Distributed tracing (port 3200)
- **Alloy** - Log shipping agent (port 12345/32317/1514)
- **Fail2ban** - Security monitoring (port 9191)
- **NTFY** - Push notifications (ports 30005/30025)
- **MinIO** - Object storage backend for Mimir, Grafana, Prometheus (port 30900)
- **Home Assistant** - Home automation integration (port 8123)

## Environment

- **Storage**: Synology NAS at 192.168.1.28
- **Network**: 192.168.1.0/24 subnet
- **Other targets**: 192.168.1.1 (gateway), 192.168.1.3 (secondary router), 192.168.1.80-104 (K8s nodes)
- **Alertmanager**: 192.168.1.28:30093
- **Timezone**: America/New_York (fail2ban), America/Los_Angeles (ntfy)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Home Network                         │
├─────────────────────────────────────────────────────────┤
│  192.168.1.1 (Gateway)  →  Prometheus SNMP probes       │
│  192.168.1.28 (Synology) → All services + Mimir backend │
│  192.168.1.3 (Router)   →  Prometheus SNMP probes       │
│  192.168.1.80-104      →  K8s nodes (Prometheus target)│
└─────────────────────────────────────────────────────────┘

Prometheus Scrape Targets:
├── router (192.168.1.1:9100) - Router metrics
├── syno_node (192.168.1.28:30091) - Synology metrics
├── prometheus (192.168.1.28:30001) - Self-monitoring
├── k8s_node (192.168.1.80-104:9100) - Kubernetes nodes
├── hass (192.168.1.28:8123) - Home Assistant
├── fail2ban (192.168.1.28:9191) - Fail2ban metrics
├── loki (192.168.1.28:30002) - Loki metrics
├── immich_server (192.168.1.28:8081) - Immich API
├── immich_backend (192.168.1.28:8082) - Immich backend
├── cadvisor (192.168.1.28:30080) - Container stats
├── dockerd (192.168.1.28:9323) - Docker daemon
└── local/remote_dns, http_ping, snmp - External targets
```

## Key Configuration Patterns

### Alloy Config Location
`/etc/alloy/config.alloy` and subdirectories
- Supports hot-reload configuration
- Used for log shipping to Loki

### Metric Relabeling
Common reconfiguration in Prometheus:
- Drop NFS/scrape_collector metrics
- Drop tmpfs/nfs/cifs/vfat filesystems
- Drop pod mountpoints
- Drop Graphite/Alertmanager favicon routes

### Loki Configuration
- **Retention**: 14 days
- **Replication**: 1 (single-node setup)
- **Ring**: In-memory KV store
- **Chunks**: `/loki/chunks`
- **Index**: `/loki/rules`

### Mimir Configuration
- **Storage Backend**: MinIO S3 at 192.168.1.28:30900
- **Blocks Storage**: mimir-blocks bucket
- **Alertmanager**: mimir-alertmanager bucket
- **Ruler**: mimir-ruler bucket
- **Active Series Tracker**: `{prometheus="prom_main"}`

### Grafana Configuration
- **Port**: 30000
- **Database**: PostgreSQL 17.9 on grafana_db container
- **Volumes**: `/volume1/docker/grafana/` paths

### Home Assistant Integration
- **Port**: 8123
- **Prometheus Path**: /api/prometheus
- **Token**: `/var/run/secrets/hass_token_2.txt`
- **Scrape Interval**: 60s

## Secrets Management

Tokens stored in:
- `/home-k8s-docker/prometheus/email_token.txt`
- `/home-k8s-docker/prometheus/hass_token.txt`
- `/home-k8s-docker/prometheus/hass_token_2.txt`
- `/home-k8s-docker/prometheus/minio_token.txt`
- `/home-k8s-docker/prometheus/discord_webhook.txt`
- `/home-k8s-docker/hass/config/secrets.yaml`
- Grafana `.grafana.env` file
- Renovate uses `{{ secrets.QUAY_TOKEN }}`

## Renovate Configuration

- **Schedule**: Friday (* * * * 5)
- **Extended**: `config:recommended`
- **Host Rules**: Quay.io with `secrets.QUAY_TOKEN`
- **Package Rules**: Postgres uses `semver-coerced` for docker datasource

## File Exclusions (from .gitignore)

### Always Excluded
- `archived_containers`, `@eaDir`
- `hass/config/custom_components/`
- `immich/library/`, `immich/postgres/`
- `loki/loki/**`
- `minio/data/**`
- `ntfy/cache`
- `*.env`

### Always Included (explicit negation)
- `tempo/tempo-data/.gitkeep`
- `mimir/data/.gitkeep`

### Excluded Files (not directories)
- `mimir/email_token.txt`, `mimir/discord_webhook.txt`
- `prometheus/*_token.txt`, `prometheus/email_token.txt`, `prometheus/discord_webhook.txt`
- `fail2ban.sqlite3`

## Common Operations

### View/Manage Services
```bash
docker compose ps                # View running containers
docker compose logs -f <service> # View logs
docker compose restart <service> # Restart service
```

### Prometheus Operations
- Add scrape targets: Edit `/home-k8s-docker/prometheus/prometheus.yaml`
- View alerting rules: Check `/prom/mixins/` directories
- Mimir endpoint: `http://192.168.1.28:30909/api/v1/push`

### Alertmanager Configuration
- URL: `http://192.168.1.28:30093/alertmanager`
- Runtime config: `/etc/runtime.yaml` (Mimir)

### Home Assistant
- Automations: `/home-k8s-docker/hass/config/automations.yaml`
- Devices: `/home-k8s-docker/hass/config/device_tracker/`
- Sensors: WeatherDot API integration
- TTS: Google Translate

### Fail2ban Integration
- Config: `/volume1/docker/fail2ban/config/`
- Exporter port: 9191 (metrics)
- Log directory: `/volume1/docker/fail2ban/config/log/fail2ban/`

## External Integrations

### Home Assistant Components
- **Synology SRM**: Device tracker for IP cameras
- **WeatherDot**: Travel time sensor for commute routes
- **Sonos**: Media player discovery
- **Immich**: Self-hosted photo backup service

### DNS Monitoring
- **Local DNS**: Query `certs.home.lan` (CNAME)
- **Remote DNS**: Query `www.google.com` (A record)
- SLO: 5 seconds for both

### SNMP Monitoring
- Modules: `if_mib`, `synology`
- Target: All network devices (gateway, routers, NAS, K8s nodes)
- Port: 30096

## Notes

- All services use `restart: always/unless-stopped`
- Fail2ban uses `network_mode: host` for proper ban functionality
- Loki uses in-memory ring (single-node setup)
- MinIO used as S3-compatible backend for all block storages
- Alloy mounts root filesystem as read-only for system metrics
- Grafana uses PostgreSQL for database persistence
- Tempo stores traces locally with local backend