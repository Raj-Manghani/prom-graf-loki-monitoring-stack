# Prometheus, Grafana, Loki Monitoring Stack

## Overview
This repository provides a **containerized monitoring and logging stack** using:

- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Loki** for log aggregation
- **Promtail** for log shipping
- **Alertmanager** for alert handling
- **Node Exporter** and **cAdvisor** for host and container metrics

All components are orchestrated via **Docker Compose**.

---

## Features
- **Infrastructure monitoring** with Prometheus scraping multiple hosts and containers
- **Centralized log aggregation** with Loki and Promtail
- **Pre-configured Grafana dashboards** for DevOps observability
- **Alert routing** with Alertmanager (customize as needed)
- **Multi-environment support** via environment variables and templated configs
- **Secrets management** using `.env` files and a config preparation script

---

## Repository Structure
```
.
├── docker-compose.yml            # Orchestrates all services
├── prepare-configs.sh            # Injects secrets into configs
├── .env.example                  # Template for your secrets (copy to .env)
├── alertmanager/                 # Alertmanager config
├── grafana/
│   └── provisioning/             # Grafana datasources and dashboards
├── loki/
│   └── config.yaml               # Loki config
├── prometheus/
│   └── prometheus.yml            # Prometheus scrape configs
├── promtail/
│   └── promtail-config.yaml      # Promtail config
└── .gitignore                    # Ignores secrets and local data
```

---

## Setup Instructions

### 1. Clone the repository
```bash
git clone git@github.com:Raj-Manghani/prom-graf-loki-monitoring-stack.git
cd prom-graf-loki-monitoring-stack
```

### 2. Create your secrets file
Copy the example and fill in your real secrets and URLs:
```bash
cp .env.example .env
nano .env
```

### 3. Prepare configuration files
Inject your secrets into the configs:
```bash
chmod +x prepare-configs.sh
./prepare-configs.sh
```

### 4. Start the monitoring stack
```bash
docker compose up -d
```

### 5. Access Grafana
- URL: `http://localhost:3000`
- Username: as set in `.env`
- Password: as set in `.env`

---

## Customization

- **Prometheus targets:** Edit `.env` to add/remove scrape targets.
- **Grafana dashboards:** Add JSON files under `grafana/provisioning/dashboards/`.
- **Alertmanager:** Customize `alertmanager/config.yml` for your alert routing.
- **Loki retention:** Adjust `loki/config.yaml` as needed.

---

## Security Notes
- **Never commit your `.env` file** — it contains sensitive secrets.
- Only commit `.env.example` with placeholders.
- The `prepare-configs.sh` script injects secrets locally before deployment.

---

## License
Specify your license here (e.g., MIT, Apache 2.0).
