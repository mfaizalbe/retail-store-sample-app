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

resource "kubernetes_config_map_v1" "grafana_dashboards" {
  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  metadata {
    name      = "monitoring-grafana-dashboards"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    for f in fileset("${path.module}/../../../grafana/dashboards", "*.json") :
    f => file("${path.module}/../../../grafana/dashboards/${f}")
  }
}
