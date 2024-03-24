resource "kubectl_manifest" "kibana" {
  depends_on = [kubectl_manifest.elasticsearch_cluster]
  yaml_body = <<YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: ${var.kibana_name}
  namespace: ${var.eck_namespace}
spec:
  version: ${var.elastic_version}
  image: ${var.kibana_image}
  count: ${var.kibana_node_count}
  elasticsearchRef:
    name: ${var.elasticsearch_name}
  config:
    xpack.fleet.registryUrl: "http://elastic-package-registry.${var.registry_namespace}.svc:8080"
    xpack.fleet.agents.elasticsearch.hosts: ["https://${var.elasticsearch_name}-es-http.${var.eck_namespace}.svc:9200"]
    xpack.fleet.agents.fleet_server.hosts: ["https://${var.fleet_server_name}-agent-http.${var.eck_namespace}.svc:8220"]
    xpack.fleet.packages:
      - name: system
        version: latest
      - name: elastic_agent
        version: latest
      - name: fleet_server
        version: latest
    xpack.fleet.agentPolicies:
      - name: Fleet Server on ECK policy
        id: eck-fleet-server
        namespace: ${var.eck_namespace}
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
        namespace: ${var.eck_namespace}
        monitoring_enabled:
          - logs
          - metrics
        unenroll_timeout: 900
        package_policies:
          - name: system-1
            id: system-1
            package:
              name: system
  #http:
  #  service:
  #    spec:
  #      type: LoadBalancer
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
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/issuer: selfsigned
spec:
  ingressClassName: nginx
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
# Enable for Air-Gapped EPR
#   tls:
#    - secretName: ${var.kibana_name}-kb-http-certs-public
#      hosts:
#         - kb.localhost       
YAML
}