locals {
  # major_minor_patch: major incremented on breaking changes, while patches are risk-free or important security fixes.
  template_version = "1_0_5"
  zones_by_env = {
    for zone in var.all_zones :
    zone.environment => merge({
      name             = "${zone.environment}.${zone.gcp_zone}",
      region           = "gcp-${zone.gcp_zone}",
      resource_ids     = local.resource_ids,
      template_version = local.template_version,
    }, zone)...
  }
}

output "zones" {
  value = {
    for environment, zones in local.zones_by_env :
    environment => { for zone in zones : replace(zone.region, "-", "_") => zone }
  }

  # Zone creation depends on these resources
  depends_on = [
    google_service_account.tenant_host,
    google_project_iam_custom_role.archive_object_write,
    google_project_iam_custom_role.archive_object_delete
  ]
}

output "vespa_cloud_project" {
  value = var.vespa_cloud_project
}
