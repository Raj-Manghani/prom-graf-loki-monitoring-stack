#!/bin/bash
set -e

echo "Preparing configuration files with environment variables..."

# Export all env vars from .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Substitute in Grafana datasources
envsubst < grafana/provisioning/datasources/datasource.yml > grafana/provisioning/datasources/datasource.generated.yml
mv grafana/provisioning/datasources/datasource.generated.yml grafana/provisioning/datasources/datasource.yml

# Substitute in Promtail config
envsubst < promtail/promtail-config.yaml > promtail/promtail-config.generated.yaml
mv promtail/promtail-config.generated.yaml promtail/promtail-config.yaml

# Substitute in Prometheus config
envsubst < prometheus/prometheus.yml > prometheus/prometheus.generated.yml
mv prometheus/prometheus.generated.yml prometheus/prometheus.yml

echo "Configuration files prepared."
