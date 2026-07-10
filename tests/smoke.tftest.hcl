# Plan-only smoke test with a mocked Google provider. Runs without credentials.
#
# Catches plan-time regressions: broken variable wiring, for_each/count
# errors, type mismatches, invalid references between the root module and
# the customer-facing submodules.

mock_provider "google" {
  # project_id on google_project is a non-computed (input) field and cannot
  # be mocked; it is null here. The modules derive the project id from the
  # computed `id` attribute ("projects/<project_id>") instead.
  mock_data "google_project" {
    defaults = {
      id     = "projects/smoke-test-project"
      number = "123456789012"
    }
  }
  mock_data "google_storage_project_service_account" {
    defaults = {
      email_address = "service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
    }
  }

  # Computed attributes that are parsed/validated at plan time need
  # plausible fake values instead of the auto-generated random strings.
  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/smoke-test-project/serviceAccounts/smoke-test@smoke-test-project.iam.gserviceaccount.com"
      email = "smoke-test@smoke-test-project.iam.gserviceaccount.com"
    }
  }
  mock_resource "google_compute_subnetwork" {
    defaults = {
      external_ipv6_prefix = "2600:1900:4000::/64"
    }
  }
}

# Plan the root module on its own, with only the required variable set.
run "root_module" {
  command = plan

  variables {
    tenant_name = "smoke"
  }

  assert {
    condition     = output.vespa_cloud_project == "vespa-external"
    error_message = "unexpected default vespa_cloud_project"
  }

  assert {
    condition     = output.zones.prod.gcp_us_central1_f.gcp_zone == "us-central1-f"
    error_message = "prod.gcp-us-central1-f should map to GCP zone us-central1-f"
  }

  assert {
    condition     = output.regions.us_central1.gcp_region == "us-central1"
    error_message = "regions output should carry the us-central1 region"
  }
}

# Plan the full customer-shaped composition (root + region + zone) against
# the local code.
run "full_composition" {
  command = plan

  module {
    source = "./tests/full"
  }

  assert {
    condition     = output.router_name == "vespa-us-central1-router-nat-gw"
    error_message = "router name not derived from VPC name and region as expected"
  }
}
