resource "kubectl_manifest" "fleet-server-agent" {
    depends_on = [kubectl_manifest.kibana]
    yaml_body = <<YAML
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: ${var.fleet_server_name}
  namespace: ${var.eck_namespace}
  labels:
    deployment: terraform
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
      metadata:
        labels:
          deployment: terraform
      spec:
        serviceAccountName: elastic-agent
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0 
  http:
    tls:
      selfSignedCertificate:
        subjectAltNames:
        - ip: 127.0.0.1
        - dns: "${var.fleet_server_ingress_hostname}"
        - dns: "${var.fleet_server_name}-agent-http.${var.eck_namespace}.svc"
        - dns: localhost
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
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0 
        volumes:
        - name: agent-data
          emptyDir: {}
YAML
}

resource "kubectl_manifest" "fleet-server-cluster-role" {
    depends_on = [kubectl_manifest.elastic-agent]
    yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: elastic-agent
  labels:
    deployment: terraform
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
  labels:
    deployment: terraform
YAML
}

resource "kubectl_manifest" "fleet-server-clusterRoleBinding" {
    depends_on = [kubectl_manifest.fleet-server-serviceAccount]
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
roleRef:
  kind: ClusterRole
  name: elastic-agent
  apiGroup: rbac.authorization.k8s.io
YAML
}

resource "kubectl_manifest" "elastic-fleet_server_ingress" {
  depends_on = [kubectl_manifest.fleet-server-clusterRoleBinding]
  yaml_body = <<YAML
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: elastic-fleet-server-ingress
  namespace: ${var.eck_namespace}
  labels:
    deployment: terraform
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.org/ssl-services: "${var.fleet_server_name}-agent-http"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "https"
    # nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    # nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # cert-manager.io/issuer: selfsigned
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ${var.fleet_server_ingress_hostname} 
    secretName: ${var.fleet_server_name}-agent-http-certs-internal  
  rules:
    - host: ${var.fleet_server_ingress_hostname}
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: ${var.fleet_server_name}-agent-http
              port:
                number: 8220
YAML
}