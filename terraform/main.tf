provider "google" {
  project = "dbos-2b63"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_instance" "foundationdb" {
  count        = 4
  name         = "fdb-${count.index + 1}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    }
    auto_delete = true
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    exec > >(tee /foundationdb-startup.log) 2>&1

    set -x
    # Update packages and install FoundationDB
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get upgrade -y
    wget https://github.com/apple/foundationdb/releases/download/7.1.31/foundationdb-clients_7.1.31-1_amd64.deb
    wget https://github.com/apple/foundationdb/releases/download/7.1.31/foundationdb-server_7.1.31-1_amd64.deb
    dpkg -i foundationdb-clients_7.1.31-1_amd64.deb
    dpkg -i foundationdb-server_7.1.31-1_amd64.deb

    # Configure FoundationDB
    sudo python3 /usr/lib/foundationdb/make_public.py
  EOT

  tags = ["foundationdb-node"]
}


resource "google_compute_firewall" "foundationdb" {
  name = "allow-foundationdb"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["4500"]
  }

  source_tags = ["foundationdb-node"]
  target_tags = ["foundationdb-node"]
}

resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh"

  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["foundationdb-node"]
}

output "instances" {
  value = [
    for instance in google_compute_instance.foundationdb :
    {
      name              = instance.name
      zone              = instance.zone
      network_interface = instance.network_interface[0].network_ip
    }
  ]
}
