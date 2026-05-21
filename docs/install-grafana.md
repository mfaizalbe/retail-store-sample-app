# Install Grafana

## How to deploy:

1. If you are using the Terraform EKS default stack, run:

```bash
cd /home/szekong/projects/capstone-project/terraform/eks/default
terraform apply
```

2. If you are using the standalone app Helmfile instead, apply the full stack:

```bash
cd /home/szekong/projects/capstone-project/src/app
helmfile -f helmfile.yaml apply
```

3. Or apply the slim app stack:

```bash
cd /home/szekong/projects/capstone-project/src/app
helmfile -f helmfile.slim.yaml apply
```

## How to run:
1. Get Grafana endpoint:

```bash
kubectl get svc -n monitoring
```

2. If external LB is not available, use port-forward:

```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

3. For the Terraform EKS default stack, store and use a password from AWS Secrets Manager (recommended):

```bash
terraform apply -var='grafana_admin_secret_arn=arn:aws:secretsmanager:ap-southeast-1:255945442255:secret:group5/grafana-6NROX0'
```

4. login with username "admin" and the password from your secret value
If you use the standalone app Helmfile path, change the admin password in `/home/szekong/projects/capstone-project/src/app/monitoring-values.yaml` before deploying.

getting credential with kubectl
'''
Get the actual username from the Grafana secret
kubectl get secret -n monitoring monitoring-grafana -o jsonpath='{.data.admin-user}' | base64 -d; echo

kubectl get secret -n monitoring monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
'''


Helmfile render could not be run locally because `helmfile` is not installed in this terminal environment, but VS Code diagnostics show no YAML errors in the edited files.

## Natural next steps:

1. Add this password to a Kubernetes secret pattern instead of plain text.
2. Add a preloaded dashboard ConfigMap under the existing `/home/szekong/projects/capstone-project/grafana` folder and auto-import it.
