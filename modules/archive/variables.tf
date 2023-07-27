
variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    environment = string,
    region      = string,
    gcp_region  = string,
    gcp_zone    = string,
    name        = string,
    is_cd       = bool,
  })
}
