resource "google_project_service" "main_project_services" {
  for_each           = toset(["cloudkms", "cloudresourcemanager", "compute"])
  service            = "${each.key}.googleapis.com"
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
    "compute.disks.setLabels",
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
    "compute.forwardingRules.get",
    "compute.forwardingRules.use",
    "compute.globalAddresses.create",
    "compute.globalAddresses.get",
    "compute.globalAddresses.use",
    "compute.globalForwardingRules.create",
    "compute.globalForwardingRules.get",
    "compute.globalForwardingRules.setLabels",
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
    "compute.globalAddresses.delete",
    "compute.globalForwardingRules.delete",
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

resource "google_project_iam_custom_role" "service_connector" {
  role_id     = "service_connect_dns_updater"
  title       = "ServiceConnect maintainer role"
  description = "Role for reading and updating ServiceConnect data"
  permissions = [
    "compute.forwardingRules.use",
    "compute.regionOperations.get",
    "compute.serviceAttachments.create",
    "compute.serviceAttachments.delete",
    "compute.serviceAttachments.get",
    "compute.subnetworks.use",
  ]
}
resource "google_project_iam_member" "service_connector" {
  project = google_project_iam_custom_role.service_connector.project
  role    = google_project_iam_custom_role.service_connector.id
  member  = "serviceAccount:service-connector@${var.vespa_cloud_project}.iam.gserviceaccount.com"
}

resource "google_service_account" "tenant_host" {
  depends_on = [google_project_service.main_project_services["cloudresourcemanager"]]
  account_id = "tenant-host"
}

# https://cloud.google.com/compute/docs/disks/customer-managed-encryption#before_you_begin
data "google_project" "project" {}
resource "google_project_iam_member" "compute_project" {
  project = data.google_project.project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"

  depends_on = [google_project_service.main_project_services["compute"]]
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

  depends_on = [google_project_service.main_project_services["compute"]]
}

# Vespa operator SSH access
resource "google_project_iam_custom_role" "vespa_ssh" {
  role_id     = "vespa_cloud_enclave_ssh"
  title       = "Vespa Cloud Enclave SSH"
  description = "Grant the Vespa Cloud operations team SSH access"
  permissions = [
    "compute.instances.get",
    "compute.instances.osAdminLogin",
    "compute.instances.osLogin",
    "compute.instances.use",
    "compute.projects.get",
    "compute.regions.get",
    "compute.zones.list",
    "iam.serviceAccounts.actAs",
    "iap.tunnelInstances.accessViaIAP",
    "resourcemanager.projects.get",
  ]
}

resource "google_service_account" "vespa_ssh" {
  account_id = "vespa-cloud-enclave-ssh"
}

resource "google_project_iam_binding" "vespa_ssh" {
  project = google_project_iam_custom_role.vespa_ssh.project
  role    = google_project_iam_custom_role.vespa_ssh.id
  members = ["serviceAccount:${google_service_account.vespa_ssh.email}"]
}

resource "google_service_account_iam_member" "vespa_ssh" {
  count              = var.enable_ssh ? 1 : 0
  service_account_id = google_service_account.vespa_ssh.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:vespa-cloud-enclave-ssh@${var.vespa_cloud_project}.iam.gserviceaccount.com"
}

resource "google_project_iam_custom_role" "archive_object_write" {
  role_id     = "archive_object_write"
  title       = "Archive object write role"
  description = "Allows writing objects to the archive bucket"
  permissions = [
    "storage.objects.create",
    "storage.multipartUploads.create",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.listParts",
  ]
}

resource "google_project_iam_custom_role" "archive_object_delete" {
  role_id     = "archive_object_delete"
  title       = "Archive object delete role"
  description = "Allow deleting from the archive bucket"
  permissions = [
    "storage.objects.delete"
  ]
}

locals {
  resource_ids = {
    archive_role_write  = google_project_iam_custom_role.archive_object_write.id,
    archive_role_delete = google_project_iam_custom_role.archive_object_delete.id
  }
}
