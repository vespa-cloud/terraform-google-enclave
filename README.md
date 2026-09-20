# Vespa Cloud Enclave on GCP

This Terraform module bootstraps a Google Cloud Platform project with the identities, roles,
permissions and global network required to run Vespa Cloud Enclaves on GCP. It also exposes the set
of supported GCP regions and Vespa Cloud zones so you can create regional and zonal resources using
the provided `modules/region` and `modules/zone` submodules.

See Vespa Cloud documentation: https://cloud.vespa.ai/

## Module registries

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-vespa--cloud%2Fenclave%2Fgoogle-623CE4?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/vespa-cloud/enclave/google)
[![OpenTofu Registry](https://img.shields.io/badge/OpenTofu%20Registry-vespa--cloud%2Fenclave%2Fgoogle-FFDA18?logo=opentofu&logoColor=white)](https://search.opentofu.org/module/vespa-cloud/enclave/google)

This module is published on both the Terraform and OpenTofu registries.

- Module address (both): `vespa-cloud/enclave/google`
- Terraform Registry: https://registry.terraform.io/modules/vespa-cloud/enclave/google
- OpenTofu Registry: https://search.opentofu.org/module/vespa-cloud/enclave/google


## What this module sets up

The root module creates the project-wide resources:
- Service accounts for tenant hosts and Vespa Cloud operator SSH access
- Custom IAM roles for the Vespa Cloud provisioner to manage VMs, disks, load balancers, and networking
- Custom IAM roles for archive storage (write, delete), backup storage (expiry) and ServiceConnect
- IAM bindings granting the Vespa Cloud provisioner and service connector the necessary permissions
- KMS encryption permissions for the Compute Engine service agent
- A single global VPC network (`vespa`) shared by all regions and zones, with firewall rules allowing
  health checks and, optionally, SSH via IAP
- A global health check for tenant load balancers
- Required GCP APIs enabled (Cloud KMS, Cloud Resource Manager, Compute Engine)

The `modules/region` submodule creates the resources shared by all zones in one GCP region:
- A Cloud Router and Cloud NAT gateway with dynamic IP allocation
- A proxy-only subnet for the regional Envoy-based load balancers used by private endpoints

The `modules/zone` submodule creates the resources for one Vespa Cloud zone:
- Subnets for tenant hosts (with a secondary range for nodes) and for private endpoint forwarding rules
- Firewall rules allowing internal IPv4 and IPv6 traffic within the zone
- A regional health check for tenant load balancers
- KMS key rings and keys for disk and backup encryption
- Cloud Storage buckets for archives and backups

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

# Bootstrap your project for Vespa Cloud.
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 2.0.0, < 3.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
}

# Create regional resources (one per GCP region).
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26"
}

# Create zone-specific networking (one per Vespa zone).
module "zone_dev_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.dev.gcp_us_central1_f
  host_cidr                    = "10.0.4.0/22"
  node_cidr                    = "10.0.8.0/22"
  lb_cidr                      = "10.0.12.0/25"
  private_service_connect_cidr = "10.0.12.128/25"
}
```

### Optional: enable SSH access
Set `enable_ssh = true` on the root module to grant Vespa Cloud operators SSH access to hosts
via [GCP OS Login](https://cloud.google.com/compute/docs/oslogin). Only enable this if you
explicitly wish to grant this access.

```hcl
module "enclave" {
  source      = "vespa-cloud/enclave/google"
  version     = ">= 2.0.0, < 3.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
  enable_ssh  = true
}
```

See complete working examples in `examples/`.

## Inputs

### Root module
- `tenant_name` (string, required): The Vespa Cloud tenant name that will operate in this project.
- `enable_ssh` (bool, optional, default `false`): Grant Vespa operators SSH access to instances running in the Enclave project.

### modules/region
- `region` (object, required): Region object from `module.enclave.regions.<region>`.
- `proxy_only_cidr` (string, required): CIDR for the regional Envoy-based load balancer proxy-only subnet. Must be `/26` or shorter. Recommended: `/26` (64 IPs) per region.

### modules/zone
- `zone` (object, required): Zone object from `module.region_<region>.zones.<env>.<gcp_zone>`.
- `host_cidr` (string, required): CIDR for the VM subnetwork. Recommended: `/22` (1024 IPs).
- `node_cidr` (string, required): CIDR for containers on VMs. Must be same size or up to 5 bits larger than `host_cidr`. Recommended: `/22` (1024 IPs).
- `lb_cidr` (string, required): CIDR for load balancer forwarding rules on private endpoints. Recommended: `/25` (128 IPs).
- `private_service_connect_cidr` (string, required): CIDR for Private Service Connect NAT subnets. Recommended: `/25` (128 IPs), packed with `lb_cidr` in the same `/24`.
- `archive_reader_members` (list, optional): Members allowed to read the Cloud Storage archive bucket.

### CIDR planning

Use a unique `/16` block within `10.0.0.0/8` per region. Within each region, allocate zones
sequentially. `host_cidr` and `node_cidr` must start on `/22`-aligned boundaries (third octet
divisible by 4), which leaves a small gap of ~768 IPs between zones.

Recommended per-region layout (3 zones):
```
10.x.0.0/26    proxy-only (regional)
10.x.4.0/22    hosts  (zone 1),  10.x.8.0/22   nodes (zone 1),  10.x.12.0/25 lb, 10.x.12.128/25 psc
10.x.16.0/22   hosts  (zone 2),  10.x.20.0/22  nodes (zone 2),  10.x.24.0/25 lb, 10.x.24.128/25 psc
10.x.28.0/22   hosts  (zone 3),  10.x.32.0/22  nodes (zone 3),  10.x.36.0/25 lb, 10.x.36.128/25 psc
```

## Outputs

### Root module
- `regions` (map): Map of GCP regions that host Vespa Cloud zones, keyed by the GCP region name with
  `-` replaced by `_`, for example `us_central1` or `europe_west3`. Pass a region object to the
  `region` input of `modules/region`. Each region object contains the following public members:
  - `gcp_region`: GCP region (e.g. `us-central1`)
  - `template_version`: Module template version
  - `zones`: The Vespa Cloud zones in this region, grouped by environment. Use the `zones` output
    of `modules/region` rather than this member when configuring zone submodules.

- `vespa_cloud_project` (string): The Vespa Cloud GCP project used to manage enclave accounts.

- `tenant_host_service_account` (object): The tenant host service account details.

### modules/region
- `zones` (map): Map of available Vespa Cloud zones in this region, grouped by environment. Keys are referenced as
  `[Vespa Cloud zone with - replaced by _]`, for example `prod.gcp_us_central1_f` or `dev.gcp_us_central1_f`.
  Each zone object contains the following public members:
  - `name`: Full Vespa Cloud zone name (e.g. `prod.us-central1-f`)
  - `region`: Vespa region id (e.g. `gcp-us-central1-f`)
  - `gcp_region`: GCP region (e.g. `us-central1`)
  - `gcp_zone`: GCP zone (e.g. `us-central1-f`)
  - `template_version`: Module template version

### modules/zone
- `hosts_cidr_block` (string): The IPv4 CIDR of the tenant host subnet (same as `host_cidr`).
- `hosts_ipv6_cidr_block` (string): The IPv6 CIDR assigned to the tenant host subnet.
- `hosts_subnet_id` (string): ID of the tenant host subnet.
- `archive_bucket` (string): Name of the Cloud Storage archive bucket.
- `backup_bucket` (string): Name of the Cloud Storage backup bucket.

## Providers
- hashicorp/google
- hashicorp/random (`modules/zone` only)

## Resources created

### Root module
- `google_project_service`: Enables required APIs (Cloud KMS, Cloud Resource Manager, Compute Engine)
- `google_project_iam_custom_role`: Custom roles for provisioner, SSH, archive write/delete, backup expiry, service connector
- `google_project_iam_member` / `google_project_iam_binding`: Role assignments for Vespa Cloud service accounts
- `google_service_account`: `tenant-host`, `vespa-cloud-enclave-ssh`
- `google_compute_network`: The global VPC network `vespa`
- `google_compute_firewall`: Allow health checks from Google ranges, and optionally SSH via IAP
- `google_compute_health_check`: Global health check for tenant load balancers

### modules/region
- `google_compute_router` / `google_compute_router_nat`: Cloud Router and Cloud NAT gateway
- `google_compute_subnetwork`: Proxy-only subnet for regional Envoy-based load balancers

### modules/zone
- `google_compute_subnetwork`: Tenant host subnet (with secondary node range) and private endpoint forwarding rule subnet
- `google_compute_firewall`: Allow internal IPv4 and IPv6 traffic
- `google_compute_region_health_check`: Regional health check for tenant load balancers
- `google_kms_key_ring` / `google_kms_crypto_key`: Disk and backup encryption keys
- `google_storage_bucket` and IAM members: Archive and backup buckets

## Permissions needed by the Terraform runner
The principal running Terraform must be able to create custom IAM role definitions and bindings,
service accounts, networking resources, KMS keys and Cloud Storage buckets, and enable APIs in the
GCP project.

Option A (simplest for bootstrap):
- `roles/owner` on the GCP project

Option B (least-privilege):
- `roles/iam.roleAdmin` (create custom roles)
- `roles/iam.serviceAccountAdmin` (create service accounts)
- `roles/resourcemanager.projectIamAdmin` (manage IAM bindings)
- `roles/serviceusage.serviceUsageAdmin` (enable APIs)
- `roles/compute.networkAdmin` (VPC, subnets, firewall rules, Cloud Router and NAT)
- `roles/compute.loadBalancerAdmin` (health checks)
- `roles/cloudkms.admin` (key rings and keys)
- `roles/storage.admin` (archive and backup buckets)

## Versioning
This module follows semantic versioning. Pin a compatible version range when consuming the module, for example:
`>= 2.0.0, < 3.0.0`.

**Note:** Version 2.x introduces breaking changes — the `modules/region` submodule is now required
between the root module and zone submodules, and all CIDR ranges must be explicitly specified on
each submodule. See `examples/` for updated usage.

## Examples
- Basic: `./examples/basic`
- Multi-region: `./examples/multi-region`

## License
Apache-2.0. See LICENSE.
