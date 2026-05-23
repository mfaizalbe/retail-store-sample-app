# Create a Kubernetes ConfigMap for the CloudWatch Data Source
resource "kubernetes_config_map" "grafana_datasource_cloudwatch" {
  metadata {
    name      = "grafana-datasource-cloudwatch"
    namespace = "monitoring"
    labels = {
      "grafana_datasource" = "1"
    }
  }

  data = {
    "cloudwatch.yaml" = file("${path.module}/../../../grafana/datasources/cloudwatch.yaml")
  }

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]
}

resource "kubernetes_config_map" "grafana_dashboard_cloudwatch_logs" {
  metadata {
    name      = "grafana-dashboard-cloudwatch-logs"
    namespace = "monitoring"
    labels = {
      "grafana_dashboard" = "1"
    }
  }

  data = {
    "cloudwatch-logs-dashboard.json" = file("${path.module}/../../../grafana/dashboards/cloudwatch-logs-dashboard.json")
  }

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]
}