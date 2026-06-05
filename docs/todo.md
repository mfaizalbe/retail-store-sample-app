# Demostration Option - 🚨 SRE Engineering Brief: The "Silent Dropped Traffic" Incident & Microservice Tuning

## 1. Executive Summary
During our recent load-testing phase (5 load-generator replicas), our front-end ui microservice experienced intermittent traffic degradation.
The core paradox: kubectl get pods reported the Pod as completely healthy (STATUS: Running, RESTARTS: 0). However, behind the scenes, the Kubelet was logging thousands of Readiness probe failed: context deadline exceeded warnings. This caused Kubernetes to violently cycle the pod in and out of the active routing pool, causing intermittent HTTP 502/504 errors for users while masking the issue at the cluster level.

## 2. The Core SRE Concepts Behind the Issue
### The "Flapping Endpoints" Phenomenon
When a microservice becomes overwhelmed, its response time degrades. Because our Kubernetes readiness probe had a strict 1-second timeout (timeoutSeconds: 1s), any health check taking 1.01 seconds or longer was treated as a total node failure.

The Loop: High load \(\rightarrow \) Latency spikes past 1s \(\rightarrow \) Kubelet drops Pod from the Service endpoint \(\rightarrow \) Traffic stops \(\rightarrow \) Pod cools down \(\rightarrow \) Health check passes \(\rightarrow \) Traffic floods back in \(\rightarrow \) Loop repeats

### .Netty Thread Starvation vs. CPU Throttling
Our UI service uses Spring Boot on Netty (a reactive, non-blocking network framework). Netty allocates a tiny, fixed pool of event-loop threads based on available CPU cores.
- Our configuration allocated a minimal 128m CPU request.
- When the load generators flooded the server, the few available Netty threads were completely choked processing user requests.
- When the Kubelet attempted to check /actuator/health/readiness, the request sat stranded in an internal network queue.
- Our Diagnostic Proof: Internal network profiling showed that connecting to the port took only 0.0005s (network stack was healthy), but processing the payload took 5.54s (application threads were starved).

## 3. SRE Dashboard Architecture (What We Must Monitor)To ensure this silent degradation never happens unnoticed again, we need to implement a dedicated SRE Dashboard capturing the Four Golden Signals. We should map the following metrics and logs into our Prometheus/Grafana stack:

### A. Infrastructure Metrics (Prometheus / cAdvisor)
- CPU Throttling (container_cpu_cfs_throttled_seconds_total): This is our primary leading indicator. It tells us if the Linux kernel is actively slowing down our container because it exceeded its 128m quota.
- Endpoint Churn (kube_endpoint_address_available): Tracks the number of healthy pods in the service pool. If this number dips or fluctuates while pod counts stay constant, it indicates readiness probe flapping.

### B. Application Metrics (Spring Boot Actuator / Micrometer)
- Netty Event Loop Utilization: Monitor thread utilization states.
- HTTP Request Latency Percentiles (p95, p99): Do not look at average latency. We need to track the tail-end latency to see exactly when the 1-second threshold is breached.

### C. Log-Based Alerts (Elasticsearch / Loki)
- Kubelet Probe Failures: Set up an anomaly alert on cluster events filtering for:"Readiness probe failed: context deadline exceeded"
- HTTP 5xx Spikes at Ingress: Monitor the API Gateway or Ingress controller logs for downstream routing drops.

## 4. Implementation & Remediation Action Items
To stabilize the system and fortify our architecture for the capstone review, we are executing the following remediation steps:
- Horizontal Pod Autoscaling (HPA): We cannot rely on a static number of replicas under variable load. We must implement an HPA based on CPU utilization.
- Resource Tuning: Right-size the UI microservice resources to handle reactive thread pools cleanly.- Probe Optimization: Adjust the Kubelet probe tolerance to handle transient spikes without cutting user traffic.

### Applied Configuration Patch:yamlspec:
```yaml
  containers:
  - name: ui
    resources:
      requests:
        cpu: "500m"      # Gives Netty room to breathe
        memory: "512Mi"
      limits:
        cpu: "1000m"     # Allows bursting during traffic spikes
        memory: "512Mi"
    readinessProbe:
      httpGet:
        path: /actuator/health/readiness
        port: 8080
      timeoutSeconds: 5  # Increased from 1s to prevent premature traffic cutting
      periodSeconds: 10
      failureThreshold: 3
```


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
