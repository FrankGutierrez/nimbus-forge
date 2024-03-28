resource "kubectl_manifest" "elastic-package-registry-namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.registry_namespace}
  labels:
    name: ${var.registry_namespace}
YAML
}

resource "kubectl_manifest" "elastic-package-registry_deployment" {
  depends_on = [kubectl_manifest.elastic-package-registry-namespace]
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elastic-package-registry
  namespace: ${var.registry_namespace}
  labels:
    app: elastic-package-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elastic-package-registry
  template:
    metadata:
      name: elastic-package-registry
      labels:
        app: elastic-package-registry
    spec:
      containers:
        - name: epr
          image: ${var.elastic_package_registry_image}
          imagePullPolicy: ${var.elastic_package_registry_image_pull_policy}
          ports:
            - containerPort: 8080
              name: http
          livenessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 20
            periodSeconds: 30
          resources:
            requests:
              cpu: 125m
              memory: 1Gi
            limits:
              cpu: 1000m
              memory: 1Gi
          env:
            - name: EPR_ADDRESS
              value: "0.0.0.0:8080"
YAML
}
resource "kubectl_manifest" "elastic-package-registry_service" {
  depends_on = [kubectl_manifest.elastic-package-registry_deployment]
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  labels:
    app: elastic-package-registry
  name: elastic-package-registry
  namespace: ${var.registry_namespace}
spec:
  ports:
  - port: 8080
    name: http
    protocol: TCP
    targetPort: http
  selector:
    app: elastic-package-registry
YAML
}

resource "kubectl_manifest" "elastic-package-registry_ingress" {
  depends_on = [kubectl_manifest.elastic-package-registry_service]
  yaml_body = <<YAML
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: elastic-package-registry-ingress
  namespace: ${var.registry_namespace}
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "http"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: ${var.elastic_package_registry_ingress_hostname}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: elastic-package-registry
                port:
                  number: 8080
YAML
}