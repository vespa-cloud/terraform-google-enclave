# SSH

An optional module to grant the Vespa Cloud operations team low-level
SSH access to the hosts inside the Enclave through [GCP OS Login](https://cloud.google.com/compute/docs/oslogin).

Only use this module if you explicitly wish to grant this access.

```terraform
module "enclave" {
    source      = "vespa-cloud/enclave/gcp"
    tenant_name = "<vespa cloud tenant>"
}

module "ssh" {
    source              = "vespa-cloud/enclave/gcp//modules/ssh"
    vespa_cloud_project = module.enclave.vespa_cloud_project
}
```