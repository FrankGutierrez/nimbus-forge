resource "kubectl_manifest" "elasticsearch_cluster" {
  depends_on = [kubectl_manifest.eck-validating_webhook_configuration]
  yaml_body = <<YAML
# This sample sets up an Elasticsearch cluster with 3 nodes.
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  # uncomment the lines below to copy the specified node labels as pod annotations and use it as an environment variable in the Pods
  #annotations:
  #  eck.k8s.elastic.co/downward-node-labels: "topology.kubernetes.io/zone"
  name: ${var.elasticsearch_name}
  namespace: ${var.eck_namespace}
spec:
  version: ${var.elastic_version}
  image: ${var.elasticsearch_image}
  nodeSets:
  - name: default
    count: ${var.elasticsearch_node_count}
    config:
      # most Elasticsearch configuration parameters are possible to set, e.g: node.attr.attr_name: attr_value
      node.roles: ["master", "data", "ingest", "ml", "remote_cluster_client"]
      # this allows ES to run on nodes even if their vm.max_map_count has not been increased, at a performance cost
      node.store.allow_mmap: ${var.elasticsearch_node_store_allow_mmap}
      # uncomment the lines below to use the zone attribute from the node labels
      #cluster.routing.allocation.awareness.attributes: k8s_node_name,zone
      #node.attr.zone: $${ZONE}
    podTemplate:
      metadata:
        labels:
          # additional labels for pods
          deployment: terraform
      spec:
        # this changes the kernel setting on the node to allow ES to use mmap
        # if you uncomment this init container you will likely also want to remove the
        # "node.store.allow_mmap: false" setting above
        # initContainers:
        # - name: sysctl
        #   securityContext:
        #     privileged: true
        #     runAsUser: 0
        #   command: ['sh', '-c', 'sysctl -w vm.max_map_count=262144']
        ###
        # uncomment the line below if you are using a service mesh such as linkerd2 that uses service account tokens for pod identification.
        # automountServiceAccountToken: true
        containers:
        - name: elasticsearch
          # specify resource limits and requests
          resources:
            limits:
              memory: 4Gi
              cpu: 1
          env:
          # uncomment the lines below to make the topology.kubernetes.io/zone annotation available as an environment variable and
          # use it as a cluster routing allocation attribute.
          #- name: ZONE
          #  valueFrom:
          #    fieldRef:
          #      fieldPath: metadata.annotations['topology.kubernetes.io/zone']
          - name: ES_JAVA_OPTS
            value: "-Xms2g -Xmx2g"
        #topologySpreadConstraints:
        #  - maxSkew: 1
        #    topologyKey: topology.kubernetes.io/zone
        #    whenUnsatisfiable: DoNotSchedule
        #    labelSelector:
        #      matchLabels:
        #        elasticsearch.k8s.elastic.co/cluster-name: ${var.elasticsearch_name}
        #        elasticsearch.k8s.elastic.co/statefulset-name: ${var.elasticsearch_name}-es-default
  #   # request 2Gi of persistent data storage for pods in this topology element
  #   volumeClaimTemplates:
  #   - metadata:
  #       name: elasticsearch-data # Do not change this name unless you set up a volume mount for the data path.
  #     spec:
  #       accessModes:
  #       - ReadWriteOnce
  #       resources:
  #         requests:
  #           storage: 2Gi
  #       storageClassName: standard
  # # inject secure settings into Elasticsearch nodes from k8s secrets references
  # secureSettings:
  # - secretName: ref-to-secret
  # - secretName: another-ref-to-secret
  #   # expose only a subset of the secret keys (optional)
  #   entries:
  #   - key: value1
  #     path: newkey # project a key to a specific path (optional)
  # http:
  #   service:
  #     spec:
  #       # expose this cluster Service with a LoadBalancer
  #       type: LoadBalancer
  #   tls:
  #     selfSignedCertificate:
  #       # add a list of SANs into the self-signed HTTP certificate
  #       subjectAltNames:
  #       - ip: 192.168.1.2
  #       - ip: 192.168.1.3
  #       - dns: ${var.elasticsearch_name}.example.com
  #     certificate:
  #       # provide your own certificate
  #       secretName: my-cert
YAML
}

resource "kubectl_manifest" "elasticsearch_ingress" {
  depends_on = [kubectl_manifest.elasticsearch_cluster]
  yaml_body = <<YAML
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: elasticsearch-ingress
  namespace: ${var.eck_namespace}
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/issuer: selfsigned
spec:
  ingressClassName: nginx
  rules:
    - host: ${var.elasticsearch_ingress_hostname}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${var.elasticsearch_name}-es-http
                port:
                  number: 9200
  # Enable for Air-Gapped EPR
  tls:
   - secretName: ${var.elasticsearch_name}-es-http-certs-public
     hosts:
        - ${var.elasticsearch_ingress_hostname}       
YAML
}