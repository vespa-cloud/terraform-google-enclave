# Vespa Cloud Enclave on GCP

This Terraform module bootstraps a Google Cloud Platform project with the identities, roles and
permissions required to run Vespa Cloud Enclaves on GCP. It also exposes the set of supported
Vespa Cloud zones so you can create one or more Enclave networks using the provided zone submodule.

See Vespa Cloud documentation: https://cloud.vespa.ai/

## Module registries

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-vespa--cloud%2Fenclave%2Fgoogle-623CE4?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/vespa-cloud/enclave/google)
[![OpenTofu Registry](https://img.shields.io/badge/OpenTofu%20Registry-vespa--cloud%2Fenclave%2Fgoogle-FFDA18?logo=opentofu&logoColor=white)](https://search.opentofu.org/module/vespa-cloud/enclave/google)

This module is published on both the Terraform and OpenTofu registries.

- Module address (both): `vespa-cloud/enclave/google`
- Terraform Registry: https://registry.terraform.io/modules/vespa-cloud/enclave/google
- OpenTofu Registry: https://search.opentofu.org/module/vespa-cloud/enclave/google


## What this module sets up
- Service accounts for tenant hosts and Vespa Cloud operator SSH access
- Custom IAM roles for the Vespa Cloud provisioner to manage VMs, disks, load balancers, DNS, and networking
- Custom IAM roles for archive storage (write, delete) and ServiceConnect
- IAM bindings granting the Vespa Cloud provisioner and service connector the necessary permissions
- KMS encryption permissions for the Compute Engine service agent
- A global health check for tenant load balancers
- Required GCP APIs enabled (Cloud KMS, Cloud Resource Manager, Compute Engine)

Networking (VPC, subnets, firewall rules, KMS keys, Cloud Storage for archives) is created per-zone via
the `modules/zone` submodule after the root module has been applied.

## Requirements
- Terraform >= 1.3 or OpenTofu >= 1.6
- Google provider (hashicorp/google)
- GCP project where you have sufficient permissions to:
  - Enable APIs
  - Create service accounts
  - Create custom IAM role definitions
  - Create IAM bindings at the project scope

Authentication: configure the Google provider using any supported auth method (CLI, Service Account,
Workload Identity). See https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started

## Usage
Minimal example:

```hcl
provider "google" {
  project = "<YOUR-GCP-PROJECT>"
}

# Bootstrap your project for Vespa Cloud
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
}

# Create regional Cloud NAT (required for each GCP region)
module "region_us_central1" {
  source  = "vespa-cloud/enclave/google//modules/region"
  version = ">= 1.0.0, < 2.0.0"
  region  = module.enclave.regions.us_central1
}

# Create zone-specific networking (one per Vespa zone)
module "zone_dev_us_central1_f" {
  source  = "vespa-cloud/enclave/google//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.region_us_central1.zones.dev.gcp_us_central1_f

  archive_reader_members = [
    # Members allowed to read objects in the Cloud Storage archive.
    # Format: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam#member/members
  ]
}
```

### Optional: enable SSH access
Set `enable_ssh = true` on the root module to grant Vespa Cloud operators SSH access to hosts
via [GCP OS Login](https://cloud.google.com/compute/docs/oslogin). Only enable this if you
explicitly wish to grant this access.

```hcl
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
  enable_ssh  = true
}
```

See complete working examples in `examples/`.

## Inputs
- `tenant_name` (string, required): The Vespa Cloud tenant name that will operate in this project.
- `enable_ssh` (bool, optional, default `false`): Grant Vespa operators SSH access to instances running in the Enclave project.

## Outputs
- `zones` (map): Map of available Vespa Cloud zones grouped by environment. Keys are referenced as
  `[environment].[region with - replaced by _]`, for example: `prod.gcp_us_central1_f` or `dev.gcp_us_central1_f`.
  Each zone object contains the following public members:
  - `name`: Full Vespa Cloud zone name (e.g. `prod.us-central1-f`)
  - `region`: Vespa region id (e.g. `gcp-us-central1-f`)
  - `gcp_region`: GCP region (e.g. `us-central1`)
  - `gcp_zone`: GCP zone (e.g. `us-central1-f`)
  - `template_version`: Module template version

- `vespa_cloud_project` (string): The Vespa Cloud GCP project used to manage enclave accounts.

- `tenant_host_service_account` (object): The tenant host service account details.

## Providers
- hashicorp/google

## Resources created
- `google_project_service`: Enables required APIs (Cloud KMS, Cloud Resource Manager, Compute Engine)
- `google_project_iam_custom_role`: Custom roles for provisioner, SSH, archive write/delete, service connector
- `google_project_iam_member` / `google_project_iam_binding`: Role assignments for Vespa Cloud service accounts
- `google_service_account`: `tenant-host`, `vespa-cloud-enclave-ssh`
- `google_compute_health_check`: Global health check for tenant load balancers

## Permissions needed by the Terraform runner
The principal running Terraform must be able to create custom IAM role definitions and bindings,
service accounts, and enable APIs in the GCP project.

Option A (simplest for bootstrap):
- `roles/owner` on the GCP project

Option B (least-privilege):
- `roles/iam.roleAdmin` (create custom roles)
- `roles/iam.serviceAccountAdmin` (create service accounts)
- `roles/resourcemanager.projectIamAdmin` (manage IAM bindings)
- `roles/serviceusage.serviceUsageAdmin` (enable APIs)

## Versioning
This module follows semantic versioning. Pin a compatible version range when consuming the module, for example:
`>= 1.0.0, < 2.0.0`.

## Examples
- Basic: `./examples/basic`
- Multi-region: `./examples/multi-region`

## License
Apache-2.0. See LICENSE.
