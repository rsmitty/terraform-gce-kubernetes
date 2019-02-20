version: ""
security:
  os:
    ca:
      crt: ${talos_os_crt}
services:
  init:
    cni: flannel
  kubeadm:
    configuration: |
      apiVersion: kubeadm.k8s.io/v1beta1
      kind: JoinConfiguration
      discovery:
        bootstrapToken:
          token: '${kubeadm_token}'
          unsafeSkipCAVerification: true
          apiServerEndpoint: ${kubeadm_control_plane_address}:443
      nodeRegistration:
        taints: ${taints}
        kubeletExtraArgs:
          node-labels: ${labels}
      token: '${kubeadm_token}'
  trustd:
    username: '${trustd_user}'
    password: '${trustd_pass}'
    endpoints: ${trustd_endpoints}