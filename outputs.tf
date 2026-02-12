locals {
  zones_by_env = {
    for zone in var.all_zones :
    zone.environment => merge({
      name             = "${zone.environment}.${zone.gcp_zone}",
      region           = "gcp-${zone.gcp_zone}",
      globals          = local.globals,
      template_version = local.template_version_gcp,
    }, zone)...
  }

  # Extract unique GCP regions from all zones
  unique_regions = toset([for zone in var.all_zones : zone.gcp_region])

  # Group zones by GCP region
  zones_by_region = {
    for region in local.unique_regions :
    region => [
      for zone in var.all_zones :
      zone if zone.gcp_region == region
    ]
  }

  # Create region objects with gcp_region, globals, and zones in that region
  regions_map = {
    for region in local.unique_regions :
    replace(region, "-", "_") => {
      gcp_region       = region
      globals          = local.globals
      template_version = local.template_version_gcp
      zones = {
        for env in distinct([for z in local.zones_by_region[region] : z.environment]) :
        env => {
          for zone_data in local.zones_by_region[region] :
          replace("gcp-${zone_data.gcp_zone}", "-", "_") => merge({
            name             = "${zone_data.environment}.${zone_data.gcp_zone}",
            region           = "gcp-${zone_data.gcp_zone}",
            globals          = local.globals,
            template_version = local.template_version_gcp,
          }, zone_data)
          if zone_data.environment == env
        }
      }
    }
  }
}

output "zones" {
  description = "Available zones are listed at https://cloud.vespa.ai/en/reference/zones.html . You reference a zone with `[environment].[region with - replaced by _]` (e.g `prod.gcp-us-central-1f`)."
  value = {
    for environment, zones in local.zones_by_env :
    environment => { for zone in zones : replace(zone.region, "-", "_") => zone }
  }
}

output "regions" {
  description = "Map of GCP regions with global resource references. Reference a region with hyphens replaced by underscores (e.g. `us_central1`, `europe_west3`)."
  value       = local.regions_map
}

output "vespa_cloud_project" {
  description = "The Vespa Cloud GCP project used to manage enclave accounts"
  value       = var.vespa_cloud_project
}

output "tenant_host_service_account" {
  description = "Tenant host service account"
  value       = google_service_account.tenant_host
}
