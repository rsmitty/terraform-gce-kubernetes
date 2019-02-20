provider "google" {
  credentials = "${file("${var.gce_cred_path}")}"
  project     = "${var.gce_project}"
  region      = "${var.gce_region}"
  zone        = "${var.gce_zone}"
}

# Super special init master
resource "google_compute_instance" "master_init_create" {
  depends_on = ["data.template_file.master_init_userdata"]
  name         = "${var.talos_cluster_name}-master-0"
  machine_type = "${var.gce_talos_flavor}"

  boot_disk {
    initialize_params{
      image = "${var.gce_talos_img}"
      size = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${var.gce_talos_master_ips["0"]}"
    }
  }

  metadata{
    "user-data" = "${data.template_file.master_init_userdata.rendered}"
  }

  ##So resize of machine flavor is possible
  allow_stopping_for_update = true
}

# Rest of the masters
resource "google_compute_instance" "master_join_create" {
  depends_on = ["data.template_file.master_join_userdata", "google_compute_instance.master_init_create"]
  name         = "${var.talos_cluster_name}-master-${count.index + 1}"
  machine_type = "${var.gce_talos_flavor}"
  count = "${var.talos_master_count - 1}"

  boot_disk {
    initialize_params{
      image = "${var.gce_talos_img}"
      size = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${var.gce_talos_master_ips[count.index + 1]}"
    }
  }

  metadata{
    "user-data" = "${element(data.template_file.master_join_userdata.*.rendered, count.index + 1)}"
  }

  ##So resize of machine flavor is possible
  allow_stopping_for_update = true
}

# Workers
resource "google_compute_instance" "worker_create" {
  depends_on = ["data.template_file.worker_userdata", "google_compute_instance.master_init_create"]
  name         = "${var.talos_cluster_name}-worker-${count.index}"
  machine_type = "${var.gce_talos_flavor}"
  count = "${var.talos_worker_count}"

  boot_disk {
    initialize_params{
      image = "${var.gce_talos_img}"
      size = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata{
    "user-data" = "${data.template_file.worker_userdata.rendered}"
  }

  ##So resize of machine flavor is possible
  allow_stopping_for_update = true
}