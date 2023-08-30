
terraform {
  required_providers {
    aws = {
      source = "hashicorp/google"
    }
  }
}

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
resource "google_project_iam_binding" "vespa_ssh" {
  project = google_project_iam_custom_role.vespa_ssh.project
  role    = google_project_iam_custom_role.vespa_ssh.id
  members = ["serviceAccount:vespa-cloud-enclave-ssh@${var.vespa_cloud_project}.iam.gserviceaccount.com"]
}
