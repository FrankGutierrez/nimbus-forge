resource "kubectl_manifest" "fleet-server-agent" {
    depends_on = [kubectl_manifest.kibana]
    yaml_body = <<YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: ${var.fleet_server_name}
  namespace: ${var.eck_namespace}
spec:
  version: ${var.elastic_version}
  kibanaRef:
    name: ${var.kibana_name}
  elasticsearchRefs:
  - name: ${var.elasticsearch_name}
  mode: fleet
  fleetServerEnabled: true
  policyID: eck-fleet-server
  deployment:
    replicas: 1
    podTemplate:
      spec:
        serviceAccountName: elastic-agent
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0 
YAML
}

resource "kubectl_manifest" "elastic-agent" {
    depends_on = [kubectl_manifest.fleet-server-agent]
    yaml_body = <<YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: ${var.elastic_agent_name}
  namespace: ${var.eck_namespace}
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
      spec:
        serviceAccountName: elastic-agent
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0 
        volumes:
        - name: agent-data
          emptyDir: {}
YAML
}

# resource "kubectl_manifest" "fleet-server-kibana" {
#     yaml_body = <<YAML
# apiVersion: kibana.k8s.elastic.co/v1
# kind: Kibana
# metadata:
#   name: ${var.kibana_name}
#   namespace: ${var.eck_namespace}
# spec:
#   version: ${var.elastic_version}
#   count: ${var.kibana_node_count}
#   elasticsearchRef:
#     name: ${var.elasticsearch_name}
#   config:
#     xpack.fleet.agents.elasticsearch.hosts: ["https://${var.elasticsearch_name}-es-http.${var.eck_namespace}.svc:9200"]
#     xpack.fleet.agents.fleet_server.hosts: ["https://${var.fleet_server_name}-agent-http.${var.eck_namespace}.svc:8220"]
#     xpack.fleet.packages:
#       - name: system
#         version: latest
#       - name: elastic_agent
#         version: latest
#       - name: fleet_server
#         version: latest
#     xpack.fleet.agentPolicies:
#       - name: Fleet Server on ECK policy
#         id: eck-fleet-server
#         namespace: ${var.eck_namespace}
#         monitoring_enabled:
#           - logs
#           - metrics
#         unenroll_timeout: 900
#         package_policies:
#         - name: fleet_server-1
#           id: fleet_server-1
#           package:
#             name: fleet_server
#       - name: Elastic Agent on ECK policy
#         id: eck-agent
#         namespace: ${var.eck_namespace}
#         monitoring_enabled:
#           - logs
#           - metrics
#         unenroll_timeout: 900
#         package_policies:
#           - name: system-1
#             id: system-1
#             package:
#               name: system
# YAML
# }

# resource "kubectl_manifest" "fleet-server-elasticsearch" {
#     yaml_body = <<YAML
# apiVersion: elasticsearch.k8s.elastic.co/v1
# kind: Elasticsearch
# metadata:
#   name: ${var.elasticsearch_name}
#   namespace: ${var.eck_namespace}
# spec:
#   version: ${var.elastic_version}
#   image: ${var.elasticsearch_image}
#   nodeSets:
#   - name: default
#     count: ${var.elasticsearch_node_count}
#     config:
#       node.store.allow_mmap: ${var.elasticsearch_node_store_allow_mmap}
# YAML
# }

resource "kubectl_manifest" "fleet-server-cluster-role" {
    depends_on = [kubectl_manifest.elastic-agent]
    yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: elastic-agent
rules:
- apiGroups: [""] # "" indicates the core API group
  resources:
  - pods
  - nodes
  - namespaces
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
- apiGroups: ["apps"]
  resources:
  - replicasets
  verbs:
  - list
  - watch
- apiGroups: ["batch"]
  resources:
  - jobs
  verbs:
  - list
  - watch
YAML
}

resource "kubectl_manifest" "fleet-server-serviceAccount" {
    depends_on = [kubectl_manifest.fleet-server-cluster-role]
    yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elastic-agent
  namespace: ${var.eck_namespace}
YAML
}

resource "kubectl_manifest" "fleet-server-clusterRoleBinding" {
    depends_on = [kubectl_manifest.fleet-server-serviceAccount]
    yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elastic-agent
subjects:
- kind: ServiceAccount
  name: elastic-agent
  namespace: ${var.eck_namespace}
roleRef:
  kind: ClusterRole
  name: elastic-agent
  apiGroup: rbac.authorization.k8s.io
YAML
}