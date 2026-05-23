module "iam_assumable_role_carts" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.58.0"
  create_role                   = true
  role_name                     = "${local.environment_name}-carts-dynamo"
  provider_url                  = module.retail_app_eks.eks_oidc_issuer_url
  role_policy_arns              = [module.dependencies.carts_dynamodb_policy_arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:carts:carts"]

  tags = module.tags.result
}

module "iam_assumable_role_grafana" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.58.0"
  create_role = true
  role_name   = "grp5-grafana"

  # Hooks into your existing EKS module output smoothly
  provider_url = module.retail_app_eks.eks_oidc_issuer_url

  # Attaches the AWS managed CloudWatch read-only policy
  role_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"]

  # Maps perfectly to your monitoring namespace
  oidc_fully_qualified_subjects = ["system:serviceaccount:monitoring:monitoring-grafana"]

  tags = {
    Blueprint = "terraform/eks/default"
    Component = "Monitoring-Grafana"
  }
}

resource "kubernetes_annotations" "grafana_service_account" {
  api_version = "v1"
  kind        = "ServiceAccount"

  metadata {
    name      = "monitoring-grafana"
    namespace = "monitoring"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.iam_assumable_role_grafana.iam_role_arn
  }

  depends_on = [
    module.iam_assumable_role_grafana,
    helm_release.monitoring
  ]

}
