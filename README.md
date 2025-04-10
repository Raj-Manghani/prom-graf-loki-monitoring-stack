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

## Important Limitations

- **Podman container monitoring is NOT supported.**
- Due to cAdvisor limitations, **only host-level metrics** are available on Podman hosts.
- Container metrics and alerts work **only with Docker**.

---

## Repository Structure
```
.
├── docker-compose.yml            # Orchestrates all services
├── alertmanager/                 # Alertmanager config
├── grafana/
│   └── provisioning/             # Grafana datasources and dashboards
├── loki/
│   └── config.yaml               # Loki config
├── prometheus/
│   ├── prometheus.yml            # Prometheus scrape configs and alert rules
│   └── alert_rules.yml           # Prometheus alerting rules
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

### 2. Configure your environment

**Edit the following files directly to customize:**

- **`docker-compose.yml`**
  - Set Grafana admin credentials:
    ```yaml
    environment:
      - GF_SECURITY_ADMIN_USER=your_admin_user
      - GF_SECURITY_ADMIN_PASSWORD=your_admin_password
    ```
- **`prometheus/prometheus.yml`**
  - Add or update your node-exporter and cAdvisor targets:
    ```yaml
    - targets: ['node-exporter:9100', '10.10.0.151:9100', '10.10.0.152:9100']
    - targets: ['cadvisor:8080', '10.10.0.151:8081', '10.10.0.152:8081']
    ```
- **`promtail/promtail-config.yaml`**
  - Set your Loki push API endpoints:
    ```yaml
    clients:
      - url: http://localhost:3100/loki/api/v1/push
      - url: http://your-remote-loki:3100/loki/api/v1/push
    ```
- **`grafana/provisioning/datasources/datasource.yml`**
  - Set your Prometheus and Loki datasource URLs:
    ```yaml
    url: http://prometheus:9090
    url: http://loki:3100
    url: http://your-remote-loki:3100
    ```

### 3. Start the monitoring stack
```bash
docker compose up -d
```

### 4. Access Grafana
- URL: `http://localhost:3000`
- **Default credentials:**  
  Username: `admin`  
  Password: `admin`  
- Change these in `docker-compose.yml` before deployment if desired.

---

## Monitoring Remote Hosts

To monitor additional remote hosts, you need to run **Node Exporter** and **cAdvisor** on each host.

### 1. Run Node Exporter on remote host

**Using Docker:**

```bash
docker run -d --name node-exporter -p 9100:9100 --pid=host --net=host \
  --restart unless-stopped \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  prom/node-exporter:latest \
  --path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs
```

**Using Podman:**

```bash
podman run -d --name node-exporter -p 9100:9100 --pid=host --net=host \
  --privileged \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/rootfs:ro \
  docker.io/prom/node-exporter:latest \
  --path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs
```

### 2. Run cAdvisor on remote host (Docker only)

> **Note:** Podman container monitoring is **not supported** due to cAdvisor limitations.  
> You will only get host-level metrics on Podman hosts.

**Using Docker:**

```bash
docker run -d --name cadvisor --privileged -p 8081:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:latest
```

### 3. Update Prometheus scrape configs

In `prometheus/prometheus.yml`, add your remote hosts:

```yaml
- job_name: 'node-exporter'
  static_configs:
    - targets: ['node-exporter:9100', '10.10.0.151:9100', '10.10.0.152:9100']

- job_name: 'cadvisor'
  static_configs:
    - targets: ['cadvisor:8080', '10.10.0.151:8081', '10.10.0.152:8081']
```

Replace IPs with your remote hosts' IP addresses.

### 4. (Optional) Run Promtail on remote host

If you want to collect logs from remote hosts, run Promtail there and configure it to push to your Loki instance.

---


## Customization

- **Prometheus targets:** Edit `prometheus/prometheus.yml`.
- **Grafana dashboards:** Add JSON files under `grafana/provisioning/dashboards/`.
- **Alertmanager:** Customize `alertmanager/config.yml`.
- **Loki retention:** Adjust `loki/config.yaml`.

---

## Security Notes
- This stack is designed for **private/internal networks**.
- IP addresses and credentials should be customized before deployment.
- No sensitive secrets are included by default.

---

## License
Specify your license here (e.g., MIT, Apache 2.0).
