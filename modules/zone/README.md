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
  source      = "vespa-cloud/enclave/google"
  version     = ">= 2.0.0, < 3.0.0"
  tenant_name = "vespa"
}

# Create regional resources (required)
module "region_us_central1" {
  source          = "vespa-cloud/enclave/google//modules/region"
  version         = ">= 2.0.0, < 3.0.0"
  region          = module.enclave.regions.us_central1
  proxy_only_cidr = "10.0.0.0/26"
}

# Create zone-specific resources (reference zone from region module)
module "zone_prod_us_central1_f" {
  source                       = "vespa-cloud/enclave/google//modules/zone"
  version                      = ">= 2.0.0, < 3.0.0"
  zone                         = module.region_us_central1.zones.prod.gcp_us_central1_f
  host_cidr                    = "10.0.4.0/22"
  node_cidr                    = "10.0.8.0/22"
  lb_cidr                      = "10.0.12.0/25"
  private_service_connect_cidr = "10.0.12.128/25"
}
```

See the root module README for CIDR planning guidance.

## Inputs

- `zone` (object, required): Zone object from the region module's `zones` output, e.g.
  `module.region_us_central1.zones.prod.gcp_us_central1_f`.
- `host_cidr` (string, required): Private IPv4 CIDR for the tenant host subnet. Must be `/29` or
  shorter. Recommended: `/22` (1024 IPs).
- `node_cidr` (string, required): Private IPv4 CIDR for the containers on the hosts, added as a
  secondary range on the host subnet. Must be the same size or up to 5 bits larger than
  `host_cidr`. Recommended: `/22` (1024 IPs).
- `lb_cidr` (string, required): Private IPv4 CIDR for the subnet holding forwarding rules of private
  endpoints. Recommended: `/25` (128 IPs).
- `private_service_connect_cidr` (string, required): Private IPv4 CIDR for Private Service Connect
  NAT subnets on service attachments. Recommended: `/25` (128 IPs), packed with `lb_cidr` in the
  same `/24`.
- `archive_reader_members` (list of string, optional, default `[]`): Members allowed to read the
  archive bucket, in the format `type:principal`.
- `vespa_cloud_project` (string, optional, default `vespa-external`): The project the Vespa Cloud
  provisioner resides in. Leave at the default unless instructed otherwise by Vespa Cloud.

## Outputs

- `hosts_cidr_block` (string): The IPv4 CIDR of the tenant host subnet (same as `host_cidr`).
- `hosts_ipv6_cidr_block` (string): The IPv6 CIDR assigned to the tenant host subnet.
- `hosts_subnet_id` (string): ID of the tenant host subnet.
- `archive_bucket` (string): Name of the archive bucket.
- `backup_bucket` (string): Name of the backup bucket.
