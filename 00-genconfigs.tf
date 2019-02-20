module "security" {
  source = "git::https://github.com/autonomy/terraform-talos-security"

  talos_identity_ip_addresses = "${values(var.gce_talos_master_ips)}"
  talos_context               = "${var.talos_cluster_name}"
}

resource "local_file" "admin_config" {
    depends_on = ["module.security"]
    content     = "${module.security.talos_admin_config}"
    filename = "configs/admin.conf"
}

data "template_file" "master_init_userdata" {
  depends_on = ["module.security"]
  template = "${file("templates/master-init-config.tpl")}"

  vars {
    talos_os_crt = "${base64encode(module.security.talos_ca_crt)}"
    talos_os_key = "${base64encode(module.security.talos_ca_key)}"

    talos_id_crt = "${base64encode(module.security.talos_identity_cert_pem)}"
    talos_id_key = "${base64encode(module.security.talos_identity_private_key_pem)}"

    talos_kube_crt = "${base64encode(module.security.kubernetes_ca_crt)}"
    talos_kube_key = "${base64encode(module.security.kubernetes_ca_key)}"

    cluster_name = "${var.talos_cluster_name}"

    kubeadm_token = "${module.security.kubeadm_token}"
    kubeadm_advertise_address = "${var.gce_talos_master_ips["0"]}"
    kubeadm_api_server_cert_sans = "${join(",",values(var.gce_talos_master_ips))}" 
    kubeadm_control_plane_address = "${var.gce_talos_master_ips["0"]}"

    taints = "[]"
    labels = "node-role.kubernetes.io/master="

    trustd_user = "${module.security.trustd_username}"
    trustd_pass = "${module.security.trustd_password}"
    ## Kind of hacky b/c of https://github.com/hashicorp/hil/issues/50
    trustd_endpoints = "${jsonencode(compact(list(lookup(var.gce_talos_master_ips, "1" ,"") != "" ?  lookup(var.gce_talos_master_ips,"1","") : "")))}"
  }
}
data "template_file" "master_join_userdata" {
  depends_on = ["module.security", "data.template_file.master_init_userdata"]
  count = "${var.talos_master_count - 1}"
  template = "${file("templates/master-join-config.tpl")}"

  vars {
    talos_os_crt = "${base64encode(module.security.talos_ca_crt)}"
    talos_os_key = "${base64encode(module.security.talos_ca_key)}"

    talos_id_crt = "${base64encode(module.security.talos_identity_cert_pem)}"
    talos_id_key = "${base64encode(module.security.talos_identity_private_key_pem)}"

    talos_kube_crt = "${base64encode(module.security.kubernetes_ca_crt)}"
    talos_kube_key = "${base64encode(module.security.kubernetes_ca_key)}"

    kubeadm_token = "${module.security.kubeadm_token}"
    kubeadm_advertise_address = "${var.gce_talos_master_ips["${count.index + 1}"]}"
    kubeadm_control_plane_address = "${var.gce_talos_master_ips["0"]}"

    taints = "[]"
    labels = "node-role.kubernetes.io/master="

    trustd_user = "${module.security.trustd_username}"
    trustd_pass = "${module.security.trustd_password}"
    ## Kind of hacky b/c of https://github.com/hashicorp/hil/issues/50
    trustd_endpoints = "${jsonencode(compact(list(lookup(var.gce_talos_master_ips, count.index + 2 ,"") != "" ? lookup(var.gce_talos_master_ips,count.index + 2,"") : "")))}"

  }
}

data "template_file" "worker_userdata" {
  depends_on = ["module.security"]
  template = "${file("templates/worker-config.tpl")}"

  vars {
    talos_os_crt = "${base64encode(module.security.talos_ca_crt)}"

    kubeadm_token = "${module.security.kubeadm_token}"
    kubeadm_control_plane_address = "${var.gce_talos_master_ips["0"]}"
    
    taints = "[]"
    labels = "node-role.kubernetes.io/worker="

    trustd_user = "${module.security.trustd_username}"
    trustd_pass = "${module.security.trustd_password}"
    trustd_endpoints = "${jsonencode(values(var.gce_talos_master_ips))}"

  }
}
resource "local_file" "master_init_config" {
    depends_on = ["data.template_file.master_init_userdata"]
    count = "${var.talos_master_count}"
    content = "${data.template_file.master_init_userdata.rendered}"
    filename = "configs/master-0.userdata"
}

resource "local_file" "master_join_config" {
    depends_on = ["data.template_file.master_join_userdata"]
    count = "${var.talos_master_count - 1}"
    content = "${element(data.template_file.master_join_userdata.*.rendered, count.index)}"
    filename = "configs/master-${count.index + 1}.userdata"
}

resource "local_file" "worker_config" {
    depends_on = ["data.template_file.worker_userdata"]
    content = "${data.template_file.worker_userdata.rendered}"
    filename = "configs/worker.userdata"
}