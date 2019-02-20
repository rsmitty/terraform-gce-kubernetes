version: ""
security:
  os:
    ca:
      crt: ${talos_os_crt}
      key: ${talos_os_key}
    identity:
      crt: ${talos_id_crt}
      key: ${talos_id_key}
  kubernetes:
    ca:
      crt: ${talos_kube_crt}
      key: ${talos_kube_key}
services:
  init:
    cni: flannel
  kubeadm:
    configuration: |
      apiVersion: kubeadm.k8s.io/v1beta1
      kind: InitConfiguration
      apiEndpoint:
        advertiseAddress: ${kubeadm_advertise_address}
        bindPort: 6443
      bootstrapTokens:
      - token: '${kubeadm_token}'
        ttl: 0s
      nodeRegistration:
        taints: ${taints}
        kubeletExtraArgs:
          node-labels: ${labels}
      ---
      apiVersion: kubeadm.k8s.io/v1beta1
      kind: ClusterConfiguration
      clusterName: ${cluster_name}
      controlPlaneEndpoint: ${kubeadm_control_plane_address}:443
      apiServerCertSANs: [ ${kubeadm_api_server_cert_sans} ]
      networking:
        dnsDomain: cluster.local
        podSubnet: 10.244.0.0/16
        serviceSubnet: 10.96.0.0/12
  trustd:
    username: '${trustd_user}'
    password: '${trustd_pass}'
    endpoints: ${trustd_endpoints}
debug: true