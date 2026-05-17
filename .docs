# Terraform Workspace How-To

This project uses the Terraform S3 backend with workspace isolation for parallel deployments.

## Why workspaces matter

A workspace gives each Terraform run its own state path in the shared S3 bucket. That lets a CI run and a manual `terraform apply` coexist without writing to the same state file.

For this repository, the EKS default stack uses:

- bucket: `sctp-ce12-tfstate-bucket`
- base key: `eks/default/terraform.tfstate`
- workspace prefix: `workspaces`

So the effective state path is:

- `default` workspace: `eks/default/terraform.tfstate`
- named workspace `run-123`: `workspaces/run-123/eks/default/terraform.tfstate`

Terraform also writes a matching lockfile object when `use_lockfile = true` is enabled:

- `default` workspace lock: `eks/default/terraform.tfstate.tflock`
- named workspace `run-123` lock: `workspaces/run-123/eks/default/terraform.tfstate.tflock`

## Set a workspace in workflow

Use a unique workspace name per run. A common pattern in GitHub Actions is to derive it from the run ID and run attempt:

```yaml
env:
  TF_WORKSPACE: run-${{ github.run_id }}-${{ github.run_attempt }}
```

Then select or create that workspace before planning or applying:

```yaml
- name: Choose workspace
  working-directory: terraform/eks/default
  run: |
    terraform init -input=false
    terraform workspace select "$TF_WORKSPACE" || terraform workspace new "$TF_WORKSPACE"
```

What this does:

- `terraform workspace select "$TF_WORKSPACE"` switches to the workspace if it already exists.
- `terraform workspace new "$TF_WORKSPACE"` creates it when it does not exist.
- The `||` means the second command only runs if the first one fails.

## Retrieve the active workspace

Use `terraform workspace show` to print the workspace currently selected by Terraform:

```yaml
- name: Show workspace
  working-directory: terraform/eks/default
  run: terraform workspace show
```

This is useful for debugging CI runs and confirming the job is writing to the expected state path.

## Recommended workflow pattern

A safe pattern is:

1. Use the `default` workspace for manual local applies when you want the shared environment.
2. Use a unique workspace per CI run for parallel or ephemeral deployments.
3. Run `terraform init` first, then `terraform workspace select ... || terraform workspace new ...`, then `terraform plan` and `terraform apply`.

Example:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      TF_WORKSPACE: run-${{ github.run_id }}-${{ github.run_attempt }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Env
        uses: ./.github/actions/setup-env
      - name: Select workspace
        working-directory: terraform/eks/default
        run: |
          terraform init -input=false
          terraform workspace select "$TF_WORKSPACE" || terraform workspace new "$TF_WORKSPACE"
      - name: Confirm workspace
        working-directory: terraform/eks/default
        run: terraform workspace show
      - name: Plan
        working-directory: terraform/eks/default
        run: terraform plan -input=false
      - name: Apply
        working-directory: terraform/eks/default
        run: terraform apply -auto-approve
```

## Running Terraform CLI locally

When running Terraform commands on your own machine, the workspace is not set automatically. You must set it explicitly before running `terraform apply`.

### Option 1 — environment variable

Export `TF_WORKSPACE` in your shell before running any Terraform command. Terraform reads this variable at startup and selects the workspace for you without needing a separate `terraform workspace select` call.

```sh
cd terraform/eks/default

export TF_WORKSPACE=my-name   # or leave unset to use the default workspace
terraform init
terraform plan
terraform apply
```

Check which workspace is active at any time:

```sh
terraform workspace show
```

### Option 2 — explicit workspace commands

Switch workspace manually, then run apply. The workspace stays selected for all subsequent commands in that shell session.

```sh
cd terraform/eks/default

terraform init

# switch to an existing workspace
terraform workspace select my-name

# or create a new one and switch to it in one step
terraform workspace new my-name

terraform plan
terraform apply
```

### Which workspace should I use locally?

| Scenario | Workspace to use |
|---|---|
| You are the only person applying and want the shared environment | `default` |
| Someone else is also applying at the same time | A unique name like your username or branch name |
| You want a completely isolated environment for testing | A unique name; destroy it when done |

### What state file key will be written?

The S3 key Terraform writes to depends on the active workspace:

| Active workspace | S3 key |
|---|---|
| `default` | `eks/default/terraform.tfstate` |
| `my-name` | `workspaces/my-name/eks/default/terraform.tfstate` |

You can confirm this by running `terraform workspace show` before applying.

## Notes

- Do not reuse the same workspace name for two concurrent runs.
- If two jobs target the same workspace, the S3 lockfile will serialize access, but both jobs still operate on the same state and the same AWS resource names.
- If you need true parallel deployments, use different workspace names.

## What is NOT de-conflicted

The workspace suffix only applies to `eks/default`. The other stacks (`eks/minimal`, `ecs/default`, `apprunner/default`) do not have `workspace_key_prefix` or a workspace-aware `environment_name` today. If those are also run in parallel, they would need the same pattern applied to their `main.tf`.
