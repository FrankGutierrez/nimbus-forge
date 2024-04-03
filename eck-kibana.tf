resource "kubectl_manifest" "kibana" {
  depends_on = [kubectl_manifest.elasticsearch_cluster, kubectl_manifest.elastic-package-registry_service]
  yaml_body = <<YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: ${var.kibana_name}
  namespace: ${var.eck_namespace}
  labels:
    deployment: terraform
spec:
  version: ${var.elastic_version}
  image: ${var.kibana_image}
  count: ${var.kibana_node_count}
  elasticsearchRef:
    name: ${var.elasticsearch_name}
  config:
    server.publicBaseUrl: https://${var.kibana_ingress_hostname}
    
    xpack.fleet.registryUrl: "http://elastic-package-registry.${var.registry_namespace}.svc:8080"
    # xpack.fleet.registryUrl: "http://${var.elastic_package_registry_ingress_hostname}"

    xpack.fleet.agents.fleet_server.hosts: ["https://${var.fleet_server_ingress_hostname}"]

    xpack.fleet.outputs:
    - id: external-elasticsearch-output
      name: default
      type: elasticsearch
      hosts: ["https://${var.elasticsearch_ingress_hostname}"]
      is_default: true
      is_default_monitoring: true
    - id: internal-elasticsearch-output
      name: Internal Output
      type: elasticsearch
      hosts: ["https://${var.elasticsearch_name}-es-http.${var.eck_namespace}.svc:9200"]
    xpack.fleet.packages:
    - name: system
      version: latest
    - name: elastic_agent
      version: latest
    - name: fleet_server
      version: latest
    - name: kubernetes
      version: latest

    xpack.fleet.agentPolicies:
    - name: Fleet Server on ECK policy
      id: eck-fleet-server
      namespace: default
      monitoring_enabled:
        - logs
        - metrics
      unenroll_timeout: 900
      package_policies:
      - name: fleet_server-1
        id: fleet_server-1
        package:
          name: fleet_server
  
    - name: Elastic Agent on ECK policy
      id: eck-agent
      namespace: default
      monitoring_enabled:
      - logs
      - metrics
      unenroll_timeout: 900
      package_policies:
      # - name: kubernetes-1
      #   id: kubernetes-1
      #   package:
      #     name: kubernetes
      # - name: system-1
      #   id: system-1
      #   package:
      #     name: system
      - package:
          name: system
        name: system-1
      - package:
          name: kubernetes
        name: kubernetes-1
  http:
    # service:
    #   spec:
    #     type: LoadBalancer
    tls:
      selfSignedCertificate:
        subjectAltNames:
        - ip: 127.0.0.1
        - dns: "${var.kibana_ingress_hostname}"
        - dns: "${var.kibana_name}-kb-http.${var.eck_namespace}.svc"
        - dns: localhost

  # this shows how to customize the Kibana pod
  # with labels and resource limits
  podTemplate:
    metadata:
      labels:
        deployment: terraform
    spec:
      containers:
      - name: kibana
        resources:
          limits:
            memory: 1Gi
            cpu: 1
YAML
}

resource "kubectl_manifest" "elastic-kibana_ingress" {
  depends_on = [kubectl_manifest.kibana]
  yaml_body = <<YAML
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: elastic-kibana-ingress
  namespace: ${var.eck_namespace}
  labels:
    deployment: terraform
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.org/ssl-services: "${var.kibana_name}-kb-http"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "https"

    # nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    # nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # cert-manager.io/issuer: selfsigned
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ${var.kibana_ingress_hostname} 
    secretName: ${var.kibana_name}-kb-http-certs-internal
  rules:
    - host: ${var.kibana_ingress_hostname}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${var.kibana_name}-kb-http
                port:
                  number: 5601
YAML
}

resource "kubectl_manifest" "elasticsearch_default_user_password" {
  depends_on = [kubectl_manifest.kibana]
  yaml_body = <<YAML
kind: Secret
apiVersion: v1
metadata:
  name: ${var.elasticsearch_name}-es-elastic-user
  namespace: ${var.eck_namespace}
  labels:
    common.k8s.elastic.co/type: elasticsearch
    eck.k8s.elastic.co/credentials: 'true'
    eck.k8s.elastic.co/owner-kind: Elasticsearch
    eck.k8s.elastic.co/owner-name: ${var.elasticsearch_name}
    eck.k8s.elastic.co/owner-namespace: ${var.eck_namespace}
    elasticsearch.k8s.elastic.co/cluster-name: ${var.elasticsearch_name}
    deployment: terraform
  managedFields:
    - manager: elastic-operator
      operation: Update
      apiVersion: v1
      fieldsType: FieldsV1
data:
  elastic: ${base64encode(var.elasticsearch_elastic_user_password)}
type: Opaque
YAML
}