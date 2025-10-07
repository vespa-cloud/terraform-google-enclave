# Handles upgrade to >= 1.3.0
moved {
  from = "google_compute_router_nat.nat"
  to   = "google_compute_router_nat.nat_static[0]"
}
