# Zone Module (Vespa Zones)

This module creates zonal resources for Vespa Cloud Enclave.

In Vespa Cloud each deployment of a Vespa application goes into a (Vespa Cloud)
[zone](https://cloud.vespa.ai/en/reference/zones). A zone hosted on Google Cloud Platform is
always contained within one
[GCP zone](https://docs.cloud.google.com/compute/docs/regions-zones).

For each Vespa Cloud zone you want to deploy to, you must configure a module of this type.

For this module to work, both the top-level (enclave) module and the regional module must be configured first.


Example use:
```terraform
provider "google" {
    project = "my-gcp-project"
}

module "enclave" {
    source = "vespa-cloud/enclave/google"
    version = ">= 2.0.0, < 3.0.0"
    tenant_name = "vespa"
}

# Create regional resources (required).
module "region_us_central1" {
    source          = "vespa-cloud/enclave/google//modules/region"
    version         = ">= 2.0.0, < 3.0.0"
    region          = module.enclave.regions.us_central1
    proxy_only_cidr = "10.0.0.0/26"
}

# Create zone-specific resources (reference zone from region module).
module "zone_prod_us_central1_f" {
    source                  = "vespa-cloud/enclave/google//modules/zone"
    version                 = ">= 2.0.0, < 3.0.0"
    zone                    = module.region_us_central1.zones.prod.gcp_us_central1_f
    host_cidr               = "10.0.8.0/23"
    lb_cidr                 = "10.0.10.0/24"
    node_cidr               = "10.0.12.0/23"
    service_attachment_cidr = "10.0.14.0/23"
}
```

## IP range layout

Each zone requires four non-overlapping CIDR blocks.  The recommended layout fits a zone into a
`/21` supernet (8 consecutive `/24` blocks).  Given a zone base address `B.0/21`:

| Variable                 | CIDR        | Size  | Purpose                                              |
|--------------------------|-------------|-------|------------------------------------------------------|
| `host_cidr`              | `B.0.0/23`  | /23   | VM subnet — one IP per host, ~508 hosts max.         |
| `lb_cidr`                | `B.2.0/24`  | /24   | LB IPv4 subnet — one IP per private endpoint.        |
| `node_cidr`              | `B.4.0/23`  | /23   | Secondary IP range for containers on VMs.            |
| `service_attachment_cidr`| `B.6.0/23`  | /23   | IP pool for PSC NAT `/29` subnets.                   |

The `node_cidr` prefix length must be within 5 bits of `host_cidr` (i.e. 0–5 bits larger).
Setting them equal (`/23` each) gives exclusive allocation — exactly one container per VM — which
is the current default for GCP Enclave.

Avoid the `10.128.0.0/9` block; GCP discourages its use for subnet primary/secondary ranges.

## Inputs

- `zone` (object, required): Zone object from the region module's `zones` output.
- `host_cidr` (string, required): Private IPv4 CIDR for the VM subnetwork.  Must be `/29` or
  shorter prefix.
- `node_cidr` (string, required): Private IPv4 CIDR for the secondary IP range used by containers
  on VMs.  Must be `/29` or shorter prefix, and within 0–5 bits of `host_cidr` prefix length.
- `lb_cidr` (string, required): Private IPv4 CIDR for the forwarding-rule subnet of private
  endpoints.  Must be `/29` or shorter prefix.
- `service_attachment_cidr` (string, required): Private IPv4 CIDR from which PSC NAT `/29`
  subnets are allocated.  Must be `/29` or shorter prefix.
- `archive_reader_members` (list of strings, optional): IAM members allowed to read the archive
  bucket.  Format: `type:principal`.
