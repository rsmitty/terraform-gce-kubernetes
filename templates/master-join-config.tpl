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
      kind: JoinConfiguration
      controlPlane:
        apiEndpoint:
          advertiseAddress: ${kubeadm_advertise_address}
          bindPort: 6443
      discovery:
        bootstrapToken:
          token: '${kubeadm_token}'
          unsafeSkipCAVerification: true
          apiServerEndpoint: ${kubeadm_control_plane_address}:443
      nodeRegistration:
        taints: ${taints}
        kubeletExtraArgs:
          node-labels: ${labels}
  trustd:
    username: '${trustd_user}'
    password: '${trustd_pass}'
    endpoints: ${trustd_endpoints}
debug: true