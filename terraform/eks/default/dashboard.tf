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

# Create a Kubernetes ConfigMap for the Loki Data Source
resource "kubernetes_config_map" "grafana_datasource_loki" {
  metadata {
    name      = "grafana-datasource-loki"
    namespace = "monitoring"
    labels = {
      "grafana_datasource" = "1"
    }
  }

  data = {
    "loki.yaml" = file("${path.module}/../../../grafana/datasources/loki.yaml")
  }

  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.loki
  ]
}

locals {
  grafana_dashboard_dir = "${path.module}/../../../grafana/dashboards"

  grafana_dashboard_shards = {
    a = [
      "dynamodb-cloudwatch.json",
      "eks-cloudwatch.json",
      "k8s_prom_15661_.json",
      "node_exporter_1860_rev45.json",
    ]
    b = [
      "classical-lb-cloudwatch.json",
      "ec2-cloudwatch.json",
      "elb-cloudwatch.json",
      "eks-managed-nodegroup-starter-configmap.yaml",
      "eks-managed-nodegroup-starter.json",
      "k8-clustering-prometheus.json",
      "logs-cloudwatch.json",
      "loki_14055_rev5.json",
      "mq-cloudwatch.json",
      "rds-cloudwatch.json",
    ]
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboards" {
  for_each = local.grafana_dashboard_shards

  depends_on = [
    kubernetes_namespace_v1.monitoring
  ]

  metadata {
    name      = "monitoring-grafana-dashboards-${each.key}"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    for f in each.value :
    f => file("${local.grafana_dashboard_dir}/${f}")
  }
}
