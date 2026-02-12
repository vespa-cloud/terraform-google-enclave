variable "region" {
  description = "GCP region configuration with global resource references and zones in this region"
  type = object({
    gcp_region       = string,
    globals          = map(any),
    template_version = string,
    zones            = map(any),
  })
}
