data "aws_eks_cluster_auth" "this" {
  name = module.retail_app_eks.eks_cluster_id

  depends_on = [
    null_resource.cluster_blocker
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.retail_app_eks.eks_cluster_id
}

data "kubernetes_service" "ui_service" {
  depends_on = [helm_release.ui]

  metadata {
    name      = "ui"
    namespace = "ui"
  }
}

data "kubernetes_service" "grafana_service" {
  depends_on = [helm_release.monitoring]

  metadata {
    name      = "monitoring-grafana"
    namespace = "monitoring"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
