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
├── .gitignore
├── docker-compose.yml            # Orchestrates all services
├── LICENSE
├── README.md
├── alertmanager/
│   └── config.yml                # Alertmanager config
├── grafana/
│   └── provisioning/
│       ├── dashboards/           # Grafana dashboard JSON files
│       │   ├── container-monitoring.json
│       │   ├── dashboard.yml     # Dashboard provisioning config
│       │   ├── node-exporter-dashboard.json
│       │   └── stack-health.json
│       └── datasources/
│           └── datasource.yml    # Grafana datasource provisioning config
├── loki/
│   └── config.yaml               # Loki config
├── prometheus/
│   ├── alert_rules.yml           # Prometheus alerting rules
│   └── prometheus.yml            # Prometheus scrape configs
├── promtail/
│   └── promtail-config.yaml      # Promtail config (for the main host)
```

---

## Included Dashboards

This stack comes with pre-provisioned Grafana dashboards:

- **Node Information:** (UID: `NodeExpt`) Provides detailed host metrics (CPU, memory, disk, network) from Node Exporter. Tagged with `Node Health`.
- **Container Monitoring:** (UID: `devops-monitoring`) Focuses on Docker container metrics (CPU, memory, network) from cAdvisor and host metrics. Includes log panel integration with Loki. Tagged with `Containers`, `Prometheus`, `cAdvisor`.
- **Monitoring Stack Health:** (UID: `stack-health`) Monitors the health of the monitoring stack itself (Prometheus targets, Loki, Promtail, Alertmanager). Tagged with `Monitor Stack`, `Prometheus`, `Node Jobs`.

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

If you want to collect logs from remote hosts, run Promtail there and configure it to push to your Loki instance. See the SSH Tunneling section below if direct access is not possible.

### 5. Monitoring Remote Hosts via SSH Tunnel

If your remote hosts are not directly reachable from the machine running this monitoring stack (e.g., they are in a different private network or behind a firewall), you can use SSH tunnels to forward the necessary ports.

**Scenario 1: Scraping Remote Exporters (Prometheus -> Remote Host)**

If Prometheus (running on the local Docker host) needs to scrape Node Exporter (port 9100) or cAdvisor (port 8081) on a remote host (`<remote-host-ip>`), you can run the following SSH command **on the local Docker host**:

```bash
# Forward local port 9101 to remote host's port 9100 (Node Exporter)
# Forward local port 8081 to remote host's port 8081 (cAdvisor)
ssh -N -L <local-bind-ip>:9101:localhost:9100 -L <local-bind-ip>:8081:localhost:8081 <user>@<remote-host-ip>
```

- Replace `<local-bind-ip>` with the IP Prometheus should connect to (e.g., `10.10.0.34` in your setup, or `localhost`).
- Replace `<user>@<remote-host-ip>` with your SSH credentials for the remote host.
- In `prometheus.yml`, configure Prometheus to scrape the **local** forwarded ports (e.g., `<local-bind-ip>:9101`, `<local-bind-ip>:8081`).

**Scenario 2: Receiving Remote Logs (Remote Promtail -> Loki)**

If Promtail running on a remote host needs to push logs to Loki (running on the local Docker host, port 3100), but the remote host cannot directly reach the Loki host, you can run the following SSH command **on the local Docker host**:

```bash
# Forward remote host's port 3100 to local host's port 3100 (Loki)
ssh -N -R 3100:localhost:3100 <user>@<remote-host-ip>
```

- Replace `<user>@<remote-host-ip>` with your SSH credentials for the remote host.
- Configure Promtail on the remote host to push logs to `http://localhost:3100/loki/api/v1/push`. The SSH tunnel will forward this traffic back to Loki on the local Docker host.
- **Important:** Ensure `GatewayPorts yes` is set in the remote host's `/etc/ssh/sshd_config` if you need to bind the remote port to `0.0.0.0` instead of just `localhost`.

**Note:** Keep SSH tunnels running reliably, potentially using tools like `autossh` or systemd services.

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
MIT
