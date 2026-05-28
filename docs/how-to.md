# Provisioning with workspace

## create workshop (execute once only)
```bash
cd terraform/eks/default
terraform workspace new my-name
```

## subsequent activation of workspace
```bash
terraform workspace new my-name
terraform init
terraform plan
terraform apply
```

# Accessing Grafana

## retrieve Grafana endpoint
```bash
cd /home/szekong/projects/capstone-project/terraform/eks/default
terraform output
```
endpoint is output as grafana_url

## configure kubectl (if not already done so)
```bash
aws eks --region ap-southeast-1 update-kubeconfig --name retail-store-szekong
```

## getting credential with kubectl
```bash
kubectl get secret -n monitoring monitoring-grafana -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl get secret -n monitoring monitoring-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

## access grafana 
access granfa via the browser with info collected in the previous steps


# configure load generator
load generator is loaded by kubectl_manifest in main.tf

## increase load
the load generator manifest is src/load-generator/deployment.yaml

update the arrival rate
```
containers:
      - name: artillery
        image: artilleryio/artillery:2.0.22
        args:
        - "run"
        - "-t"
        - "http://ui.svc"
        - "--overrides"
        # Update arrivalRate to your desired value (e.g., 20 users per second)
        - '{"config":{"phases":[{"duration":300,"arrivalRate":20}]}}'
        - "/scripts/scenario.yml"
```

```bash
terraform plan
terraform apply
```

## verify the rolling update
```bash
kubectl get pods -n ui -w
```

## check logs
```bash
kubectl logs deployment/load-generator -n ui -c artillery
```
