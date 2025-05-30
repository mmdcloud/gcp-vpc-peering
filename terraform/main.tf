# VPC1 
module "vpc1" {
  source                          = "./modules/vpc"
  vpc_name                        = "vpc1"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  ip_cidr_ranges                  = var.ip_cidr_range1
  region                          = var.region
  private_ip_google_access        = false
  firewall_data = [
    {
      name          = "vpc1-firewall"
      source_ranges = [module.instance2.network_ip]
      allow_list = [
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    },
    {
      name          = "vpc1-firewall-ssh"
      source_ranges = ["0.0.0.0/0"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}

# VPC2 
module "vpc2" {
  source                          = "./modules/vpc"
  vpc_name                        = "vpc2"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  ip_cidr_ranges                  = var.ip_cidr_range2
  region                          = var.region
  private_ip_google_access        = false
  firewall_data = [
    {
      name          = "vpc2-firewall"
      source_ranges = [module.instance1.network_ip]
      allow_list = [
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    },
    {
      name          = "vpc2-firewall-ssh"
      source_ranges = ["0.0.0.0/0"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}

resource "google_compute_address" "instance1_ip" {
  name = "instance1-address"
}

# Instance 1
module "instance1" {
  source                    = "./modules/compute"
  name                      = "instance1"
  machine_type              = "e2-micro"
  zone                      = "us-central1-a"
  metadata_startup_script   = "sudo apt-get update; sudo apt-get install nginx -y"
  deletion_protection       = false
  allow_stopping_for_update = true
  image                     = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
  network_interfaces = [
    {
      network    = module.vpc1.vpc_id
      subnetwork = module.vpc1.subnets[0].id
      access_configs = [
        {
          nat_ip = google_compute_address.instance1_ip.address
        }
      ]
    }
  ]
}

resource "google_compute_address" "instance2_ip" {
  name = "instance2-address"
}

# Instance 2
module "instance2" {
  source                    = "./modules/compute"
  name                      = "instance2"
  machine_type              = "e2-micro"
  zone                      = "us-central1-a"
  metadata_startup_script   = "sudo apt-get update; sudo apt-get install nginx -y"
  deletion_protection       = false
  allow_stopping_for_update = true
  image                     = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
  network_interfaces = [
    {
      network    = module.vpc2.vpc_id
      subnetwork = module.vpc2.subnets[0].id
      access_configs = [
        {
          nat_ip = google_compute_address.instance2_ip.address
        }
      ]
    }
  ]
}

resource "google_compute_network_peering" "peering1" {
  name         = "peering1"
  network      = module.vpc1.self_link
  peer_network = module.vpc2.self_link
}

resource "google_compute_network_peering" "peering2" {
  name         = "peering2"
  network      = module.vpc2.self_link
  peer_network = module.vpc1.self_link
}