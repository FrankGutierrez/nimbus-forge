resource "kubectl_manifest" "elastic_agent" {
  depends_on = [kubectl_manifest.fleet_server_agent]
  yaml_body = <<YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: ${var.elastic_agent_name}
  namespace: ${var.eck_namespace}
  # namespace: kube-system
  labels:
    deployment: terraform
spec:
  version: ${var.elastic_version}
  kibanaRef:
    name: ${var.kibana_name}
  fleetServerRef:
    name: ${var.fleet_server_name}
  mode: fleet
  policyID: eck-agent
  daemonSet:
    podTemplate:
      metadata:
        labels:
          deployment: terraform
      spec:
        serviceAccountName: elastic-agent
        hostNetwork: true
        dnsPolicy: ClusterFirstWithHostNet
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0
        volumes:
        - name: agent-data
          emptyDir: {}
YAML
}

resource "kubectl_manifest" "elastic_agent_cluster_role" {
  depends_on = [kubectl_manifest.elastic_agent]
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: elastic-agent
  labels:
    deployment: terraform
rules:
- apiGroups: [""]
  resources:
  - pods
  - nodes
  - namespaces
  - events
  - services
  - configmaps
  verbs:
  - get
  - watch
  - list
- apiGroups: ["coordination.k8s.io"]
  resources:
  - leases
  verbs:
  - get
  - create
  - update
- nonResourceURLs:
  - "/metrics"
  verbs:
  - get
- apiGroups: ["extensions"]
  resources:
    - replicasets
  verbs: 
  - "get"
  - "list"
  - "watch"
- apiGroups:
  - "apps"
  resources:
  - statefulsets
  - deployments
  - replicasets
  verbs:
  - "get"
  - "list"
  - "watch"
- apiGroups:
  - ""
  resources:
  - nodes/stats
  verbs:
  - get
- apiGroups:
  - "batch"
  resources:
  - jobs
  verbs:
  - "get"
  - "list"
  - "watch"
YAML
}

resource "kubectl_manifest" "elastic_agent_serviceAccount" {
  depends_on = [kubectl_manifest.elastic_agent_cluster_role]
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elastic-agent
  namespace: ${var.eck_namespace}
  # namespace: kube-system
  labels:
    deployment: terraform
YAML
}

resource "kubectl_manifest" "elastic_agent_clusterRoleBinding" {
  depends_on = [kubectl_manifest.elastic_agent_serviceAccount]
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elastic-agent
  labels:
    deployment: terraform
subjects:
- kind: ServiceAccount
  name: elastic-agent
  namespace: ${var.eck_namespace}
  # namespace: kube-system
roleRef:
  kind: ClusterRole
  name: elastic-agent
  apiGroup: rbac.authorization.k8s.io
YAML
}

# #### Test
# resource "kubectl_manifest" "elastic_agent_rolebinding" {
#   depends_on = [kubectl_manifest.elastic_agent_clusterRoleBinding]
#   yaml_body = <<YAML
# apiVersion: rbac.authorization.k8s.io/v1
# kind: RoleBinding
# metadata:
#   namespace: kube-system
#   name: elastic-agent
#   labels:
#     deployment: terraform
# subjects:
#   - kind: ServiceAccount
#     name: elastic-agent
#     namespace: kube-system
# roleRef:
#   kind: Role
#   name: elastic-agent
#   apiGroup: rbac.authorization.k8s.io
# YAML
# }

# resource "kubectl_manifest" "elastic_agent_kubeadm_rolebinding" {
#   depends_on = [kubectl_manifest.elastic_agent_rolebinding]
#   yaml_body = <<YAML
# apiVersion: rbac.authorization.k8s.io/v1
# kind: RoleBinding
# metadata:
#   name: elastic-agent-kubeadm-config
#   namespace: kube-system
#   labels:
#     deployment: terraform
# subjects:
#   - kind: ServiceAccount
#     name: elastic-agent
#     namespace: kube-system
# roleRef:
#   kind: Role
#   name: elastic-agent-kubeadm-config
#   apiGroup: rbac.authorization.k8s.io
# YAML
# }

# resource "kubectl_manifest" "elastic_agent_role" {
#   depends_on = [kubectl_manifest.elastic_agent_kubeadm_rolebinding]
#   yaml_body = <<YAML
# apiVersion: rbac.authorization.k8s.io/v1
# kind: Role
# metadata:
#   name: elastic-agent
#   # Should be the namespace where elastic-agent is running
#   namespace: kube-system
#   labels:
#     k8s-app: elastic-agent
#     deployment: terraform
# rules:
#   - apiGroups:
#       - coordination.k8s.io
#     resources:
#       - leases
#     verbs: ["get", "create", "update"]
# YAML
# }

# resource "kubectl_manifest" "elastic_agent_kubeadm_role" {
#   depends_on = [kubectl_manifest.elastic_agent_role]
#   yaml_body = <<YAML
# apiVersion: rbac.authorization.k8s.io/v1
# kind: Role
# metadata:
#   name: elastic-agent-kubeadm-config
#   namespace: kube-system
#   labels:
#     k8s-app: elastic-agent
#     deployment: terraform
# rules:
#   - apiGroups: [""]
#     resources:
#       - configmaps
#     resourceNames:
#       - kubeadm-config
#     verbs: ["get"]
# YAML
# }
# #### End Test
