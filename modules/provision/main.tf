terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_project_service" "main_project_services" {
  for_each = toset(["cloudkms", "cloudresourcemanager", "compute"])
  service  = "${each.key}.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_iam_custom_role" "vespa_cloud_provisioner_role" {
  role_id     = "vespa.cloud.provisioner"
  title       = "Allow config servers to provision resources"
  description = "Gives config server the needed permissions to create and delete instances and load balancers"
  permissions = [
    # General: List operation status
    "compute.globalOperations.get",
    "compute.regionOperations.get",
    "compute.zoneOperations.get",

    # Misc
    "storage.buckets.list",
    "resourcemanager.projects.get",

    # Provision instance
    "compute.disks.create",
    "compute.forwardingRules.setLabels",
    "compute.instances.attachDisk",
    "compute.instances.create",
    "compute.instances.get",
    "compute.instances.setLabels",
    "compute.instances.setMachineType",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.instances.setTags",
    "compute.instances.updateNetworkInterface",
    "compute.subnetworks.use",
    "iam.serviceAccounts.actAs",

    # Delete instance
    "compute.instances.delete",

    # Manage DNS resource records
    # Details in https://cloud.google.com/dns/docs/access-control
    "dns.changes.get",
    "dns.changes.list",
    "dns.changes.create",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.update",
    "dns.resourceRecordSets.create",

    # Provision load balancer
    "compute.addresses.create",
    "compute.addresses.createInternal",
    "compute.addresses.get",
    "compute.addresses.use",
    "compute.addresses.useInternal",
    "compute.backendServices.create",
    "compute.backendServices.use",
    "compute.forwardingRules.create",
    "compute.forwardingRules.use",
    "compute.healthChecks.useReadOnly",
    "compute.instances.use",
    "compute.networkEndpointGroups.attachNetworkEndpoints",
    "compute.networkEndpointGroups.create",
    "compute.networkEndpointGroups.detachNetworkEndpoints",
    "compute.networkEndpointGroups.get",
    "compute.networkEndpointGroups.use",
    "compute.networks.updatePolicy",
    "compute.regionBackendServices.create",
    "compute.regionBackendServices.use",
    "compute.regionHealthChecks.useReadOnly",
    "compute.regionTargetTcpProxies.create",
    "compute.regionTargetTcpProxies.use",
    "compute.serviceAttachments.create",
    "compute.serviceAttachments.get",
    "compute.serviceAttachments.update",
    "compute.subnetworks.create",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.use",
    "compute.targetTcpProxies.create",
    "compute.targetTcpProxies.use",

    # Delete load balancer
    "compute.addresses.delete",
    "compute.addresses.deleteInternal",
    "compute.backendServices.delete",
    "compute.forwardingRules.delete",
    "compute.networkEndpointGroups.delete",
    "compute.regionBackendServices.delete",
    "compute.regionTargetTcpProxies.delete",
    "compute.serviceAttachments.delete",
    "compute.subnetworks.delete",
    "compute.targetTcpProxies.delete",

    # List and use images
    "compute.images.get",
    "compute.images.getFromFamily",
    "compute.images.list",
    "compute.images.useReadOnly",
  ]
}

resource "google_project_iam_member" "vespa_cloud_provisioner" {
  project = google_project_iam_custom_role.vespa_cloud_provisioner_role.project
  role    = google_project_iam_custom_role.vespa_cloud_provisioner_role.id
  member  = "serviceAccount:vespa-cloud-provisioner@${var.vespa_cloud_project}.iam.gserviceaccount.com"
}

resource "google_service_account" "tenant_host" {
  depends_on = [google_project_service.main_project_services["cloudresourcemanager"]]
  account_id = "tenant-host"
}

# https://cloud.google.com/compute/docs/disks/customer-managed-encryption#before_you_begin
data "google_project" "project" {}
resource "google_project_iam_member" "compute_project" {
  project  = data.google_project.project.project_id
  role     = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member   = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}

# Health check for all tenant LBs
resource "google_compute_health_check" "tenant" {
  name = "tenant"

  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 2

  https_health_check {
    port         = 4443
    request_path = "/status.html"
    proxy_header = "PROXY_V1"
  }
}
