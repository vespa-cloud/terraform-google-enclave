# Global network resources

resource "google_compute_network" "vespa" {
  name                    = "vespa"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "allow_ssh" {
  count         = var.enable_ssh ? 1 : 0
  name          = "vespa-firewall-allow-ssh"
  network       = google_compute_network.vespa.name
  priority      = 10000
  source_ranges = ["35.235.240.0/20"] # https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule

  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_health_check" {
  name          = "vespa-firewall-allow-health-check"
  network       = google_compute_network.vespa.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # https://cloud.google.com/load-balancing/docs/https#health-checks

  allow {
    protocol = "tcp"
    ports    = [4443]
  }
}
