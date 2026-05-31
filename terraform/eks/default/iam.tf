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

# IAM Policy Document for Trust Relationship
data "aws_iam_policy_document" "cloudwatch_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_id}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

# Create the IAM Role
resource "aws_iam_role" "cloudwatch_agent" {
  name               = "${var.environment_name}-cloudwatch-agent-irsa"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_agent_assume_role.json
}

# Attach the CloudWatchAgentServerPolicy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# In locals block
locals {
  oidc_provider_id = replace(module.retail_app_eks.eks_oidc_issuer_url, "https://", "")
}

