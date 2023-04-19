provider "google" {
  project = "dbos-2b63"
  region =  "us-central1"
  zone  = "us-central1-c"
}

resource "google_compute_instance_template" "foundationdb" {
  name_prefix = "foundationdb-node-"
  machine_type = "n1-standard-2"

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    exec > >(tee /var/log/foundationdb-startup.log) 2>&1

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

resource "google_compute_instance_group_manager" "foundationdb" {
  name = "foundationdb-cluster"

  base_instance_name = "foundationdb-node"
  version {
    instance_template = google_compute_instance_template.foundationdb.self_link
  }
  target_size = 4
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

output "instance_group_manager" {
  value = google_compute_instance_group_manager.foundationdb.name
}
