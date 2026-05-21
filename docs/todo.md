# Grafana + CloudWatch TODO

## Scope
- Build a starter Grafana dashboard for EKS managed node groups.
- Start with `managed-nodegroup-1`, then replicate for `managed-nodegroup-2` and `managed-nodegroup-3`.

## Cluster and Node Group Context
- Cluster name (default): `retail-store`
- Node groups:
  - `managed-nodegroup-1`
  - `managed-nodegroup-2`
  - `managed-nodegroup-3`

## TODO: CloudWatch Metrics (AWS/EKS)
- [x] Add panel: Node CPU utilization
- [x] Add panel: Node memory utilization
- [x] Add panel: Node filesystem utilization
- [x] Add panel: Node network bytes in/out (combined panel)
- [x] Add panel: Node count / healthy node count (starter node count view)

Suggested dimensions:
- `ClusterName = retail-store` (or your overridden environment name)
- `NodegroupName = managed-nodegroup-1` (repeat for other node groups)

## TODO: Fallback Metrics (if AWS/EKS namespace is sparse)
Use AWS/EC2 and AWS/AutoScaling to ensure baseline visibility.

- [ ] AWS/EC2: `CPUUtilization`
- [ ] AWS/EC2: `NetworkIn`
- [ ] AWS/EC2: `NetworkOut`
- [ ] AWS/EC2: `StatusCheckFailed` (and instance/system variants)
- [ ] AWS/EC2: `DiskReadBytes`, `DiskWriteBytes` (if available)

- [x] AWS/AutoScaling: `GroupDesiredCapacity`
- [x] AWS/AutoScaling: `GroupInServiceInstances`
- [x] AWS/AutoScaling: `GroupPendingInstances`
- [ ] AWS/AutoScaling: `GroupTerminatingInstances`

## TODO: Validate Available Metrics in Your Region
- [ ] Run and verify EKS metrics are present:

```bash
aws cloudwatch list-metrics --namespace AWS/EKS --region <region> \
  --dimensions Name=ClusterName,Value=retail-store

aws cloudwatch list-metrics --namespace AWS/EKS --region <region> \
  --dimensions Name=NodegroupName,Value=managed-nodegroup-1
```

## TODO: Dashboard Build Order
- [x] Create dashboard JSON: `grafana/dashboards/eks-managed-nodegroup-starter.json`
- [x] Add all `managed-nodegroup-1` panels first
- [ ] Duplicate panels for nodegroup-2 and nodegroup-3
- [x] Set default time range to last 6h
- [x] Use 5m period for node-level trend panels
- [x] Add thresholds (warning/critical) for CPU, memory, and filesystem utilization

## Current Status
- [x] Starter dashboard file generated and JSON-validated.
- [x] Dashboard ConfigMap created for sidecar auto-discovery.
- [x] Auto-import wiring added for Helmfile and Terraform deployment paths.
- [ ] Dashboard imported into Grafana and datasource selected.
- [ ] EKS metrics confirmed in your AWS region/account.

## TODO: Security/Operations Follow-up
- [ ] Store Grafana admin password via Kubernetes Secret pattern (avoid plain text in docs/values)
- [x] Add preloaded dashboard ConfigMap under `grafana/` and auto-import it

## Recommended Next Step
- Import `grafana/dashboards/eks-managed-nodegroup-starter.json` into Grafana, set the `Datasource`, `AWS Region`, `cluster`, and `nodegroup` variables, then verify whether AWS/EKS panels return data.
- If AWS/EKS panels are empty, set `asg` and use fallback EC2/AutoScaling panels while enabling EKS/Container Insights metrics.
