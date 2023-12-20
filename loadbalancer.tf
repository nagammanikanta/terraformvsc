resource "google_compute_network" "net" {
    name     = "my-network"
}

resource "google_compute_subnetwork" "subnet" {
  

  name          = "my-subnetwork"
  network       = google_compute_network.net.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  purpose       = "PRIVATE_NAT"
}

resource "google_compute_router" "router" {


  name     = "my-router"
  region   = google_compute_subnetwork.subnet.region
  network  = google_compute_network.net.id
}

resource "google_network_connectivity_hub" "hub" {
  

  name        = "my-hub"
  description = "vpc hub for inter vpc nat"
}

resource "google_network_connectivity_spoke" "spoke" {
  

  name        = "my-spoke"
  location    = "global"
  description = "vpc spoke for inter vpc nat"
  hub         =  google_network_connectivity_hub.hub.id
  linked_vpc_network {
    exclude_export_ranges = [
      "198.51.100.0/24",
      "10.10.0.0/16"
    ]
    uri = google_compute_network.net.self_link
  }
}

resource "google_compute_router_nat" "nat_type" {
  provider                            = google-beta

  name                                = "my-router-nat"
  router                              = google_compute_router.router.name
  region                              = google_compute_router.router.region
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
  enable_dynamic_port_allocation      = false
  enable_endpoint_independent_mapping = false
  min_ports_per_vm                    = 32
  type                                = "PRIVATE"
  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  rules {
    rule_number = 100
    description = "rule for private nat"
    match       = "nexthop.hub == \"//networkconnectivity.googleapis.com/projects/acm-test-proj-123/locations/global/hubs/my-hub\""
    action {
      source_nat_active_ranges = [
        google_compute_subnetwork.subnet.self_link
      ]
    }
  }
}