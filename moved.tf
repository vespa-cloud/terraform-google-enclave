# Moved resources
# Remove when all enclave projects are on >= 1.0.6 of this module

moved {
  from = module.provision.google_compute_health_check.tenant
  to   = google_compute_health_check.tenant
}
moved {
  from = module.provision.google_project_iam_binding.vespa_ssh
  to   = google_project_iam_binding.vespa_ssh
}
moved {
  from = module.provision.google_project_iam_custom_role.archive_object_delete
  to   = google_project_iam_custom_role.archive_object_delete
}
moved {
  from = module.provision.google_project_iam_custom_role.archive_object_write
  to   = google_project_iam_custom_role.archive_object_write
}
moved {
  from = module.provision.google_project_iam_custom_role.vespa_cloud_provisioner_role
  to   = google_project_iam_custom_role.vespa_cloud_provisioner_role
}
moved {
  from = module.provision.google_project_iam_custom_role.vespa_ssh
  to   = google_project_iam_custom_role.vespa_ssh
}
moved {
  from = module.provision.google_project_iam_member.compute_project
  to   = google_project_iam_member.compute_project
}
moved {
  from = module.provision.google_project_iam_member.vespa_cloud_provisioner
  to   = google_project_iam_member.vespa_cloud_provisioner
}
moved {
  from = module.provision.google_project_service.main_project_services
  to   = google_project_service.main_project_services
}
moved {
  from = module.provision.google_service_account.tenant_host
  to   = google_service_account.tenant_host
}
moved {
  from = module.provision.google_service_account.vespa_ssh
  to   = google_service_account.vespa_ssh
}
moved {
  from = module.provision.google_service_account_iam_member.vespa_ssh
  to   = google_service_account_iam_member.vespa_ssh
}
