resource "kubectl_manifest" "eck-namespace" {
  depends_on = [kubectl_manifest.eck-stackconfigpolicies_stackconfigpolicy_k8s_elastic_co]
  yaml_body = <<YAML
# Source: eck-operator/templates/operator-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.eck_namespace}
  labels:
    name: ${var.eck_namespace}
    deployment: terraform
YAML
}

resource "kubectl_manifest" "eck-service_account" {
  depends_on = [kubectl_manifest.eck-namespace]
  yaml_body = <<YAML
# Source: eck-operator/templates/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elastic-operator
  namespace: ${var.eck_namespace}
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
YAML
}

resource "kubectl_manifest" "eck-webhook" {
  depends_on = [kubectl_manifest.eck-service_account]
  yaml_body = <<YAML
# Source: eck-operator/templates/webhook.yaml
apiVersion: v1
kind: Secret
metadata:
  name: elastic-webhook-server-cert
  namespace:  ${var.eck_namespace}
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
YAML
}

resource "kubectl_manifest" "eck-configmap" {
  depends_on = [kubectl_manifest.eck-webhook]
  yaml_body = <<YAML
# Source: eck-operator/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: elastic-operator
  namespace:  ${var.eck_namespace}
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
data:
  eck.yaml: |-
    log-verbosity: 0
    metrics-port: 0
    container-registry: ${var.eck_operator_container_registry}
    max-concurrent-reconciles: 3
    ca-cert-validity: 8760h
    ca-cert-rotate-before: 24h
    cert-validity: 8760h
    cert-rotate-before: 24h
    disable-config-watch: false
    exposed-node-labels: [topology.kubernetes.io/.*,failure-domain.beta.kubernetes.io/.*]
    set-default-security-context: auto-detect
    kube-client-timeout: 60s
    elasticsearch-client-timeout: 180s
    disable-telemetry: false
    distribution-channel: all-in-one
    validate-storage-class: true
    enable-webhook: true
    webhook-name: elastic-webhook.k8s.elastic.co
    webhook-port: 9443
    operator-namespace:  ${var.eck_namespace}
    enable-leader-election: true
    elasticsearch-observation-interval: 10s
    ubi-only: false
YAML
}

resource "kubectl_manifest" "eck-cluster_roles_operator" {
  depends_on = [kubectl_manifest.eck-configmap]
  yaml_body = <<YAML
# Source: eck-operator/templates/cluster-roles.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: elastic-operator
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
rules:
- apiGroups:
  - "authorization.k8s.io"
  resources:
  - subjectaccessreviews
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  resourceNames:
  - elastic-operator-leader
  verbs:
  - get
  - watch
  - update
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - pods
  - events
  - persistentvolumeclaims
  - secrets
  - services
  - configmaps
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - apps
  resources:
  - deployments
  - statefulsets
  - daemonsets
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - elasticsearch.k8s.elastic.co
  resources:
  - elasticsearches
  - elasticsearches/status
  - elasticsearches/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - autoscaling.k8s.elastic.co
  resources:
  - elasticsearchautoscalers
  - elasticsearchautoscalers/status
  - elasticsearchautoscalers/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - kibana.k8s.elastic.co
  resources:
  - kibanas
  - kibanas/status
  - kibanas/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - apm.k8s.elastic.co
  resources:
  - apmservers
  - apmservers/status
  - apmservers/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - enterprisesearch.k8s.elastic.co
  resources:
  - enterprisesearches
  - enterprisesearches/status
  - enterprisesearches/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - beat.k8s.elastic.co
  resources:
  - beats
  - beats/status
  - beats/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - agent.k8s.elastic.co
  resources:
  - agents
  - agents/status
  - agents/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - maps.k8s.elastic.co
  resources:
  - elasticmapsservers
  - elasticmapsservers/status
  - elasticmapsservers/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - stackconfigpolicy.k8s.elastic.co
  resources:
  - stackconfigpolicies
  - stackconfigpolicies/status
  - stackconfigpolicies/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - logstash.k8s.elastic.co
  resources:
  - logstashes
  - logstashes/status
  - logstashes/finalizers # needed for ownerReferences with blockOwnerDeletion on OCP
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
- apiGroups:
  - storage.k8s.io
  resources:
  - storageclasses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - validatingwebhookconfigurations
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
  - list
  - watch
YAML
}

resource "kubectl_manifest" "eck-cluster_roles_operator_view" {
  depends_on = [kubectl_manifest.eck-cluster_roles_operator]
  yaml_body = <<YAML
# Source: eck-operator/templates/cluster-roles.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: "elastic-operator-view"
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
rules:
- apiGroups: ["elasticsearch.k8s.elastic.co"]
  resources: ["elasticsearches"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["autoscaling.k8s.elastic.co"]
  resources: ["elasticsearchautoscalers"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apm.k8s.elastic.co"]
  resources: ["apmservers"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["kibana.k8s.elastic.co"]
  resources: ["kibanas"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["enterprisesearch.k8s.elastic.co"]
  resources: ["enterprisesearches"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["beat.k8s.elastic.co"]
  resources: ["beats"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["agent.k8s.elastic.co"]
  resources: ["agents"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["maps.k8s.elastic.co"]
  resources: ["elasticmapsservers"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["stackconfigpolicy.k8s.elastic.co"]
  resources: ["stackconfigpolicies"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["logstash.k8s.elastic.co"]
  resources: ["logstashes"]
  verbs: ["get", "list", "watch"]
YAML
}

resource "kubectl_manifest" "eck-cluster_roles_operator_edit" {
  depends_on = [kubectl_manifest.eck-cluster_roles_operator_view]
  yaml_body = <<YAML
# Source: eck-operator/templates/cluster-roles.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: "elastic-operator-edit"
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
rules:
- apiGroups: ["elasticsearch.k8s.elastic.co"]
  resources: ["elasticsearches"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["autoscaling.k8s.elastic.co"]
  resources: ["elasticsearchautoscalers"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["apm.k8s.elastic.co"]
  resources: ["apmservers"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["kibana.k8s.elastic.co"]
  resources: ["kibanas"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["enterprisesearch.k8s.elastic.co"]
  resources: ["enterprisesearches"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["beat.k8s.elastic.co"]
  resources: ["beats"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["agent.k8s.elastic.co"]
  resources: ["agents"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["maps.k8s.elastic.co"]
  resources: ["elasticmapsservers"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["stackconfigpolicy.k8s.elastic.co"]
  resources: ["stackconfigpolicies"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
- apiGroups: ["logstash.k8s.elastic.co"]
  resources: ["logstashes"]
  verbs: ["create", "delete", "deletecollection", "patch", "update"]
YAML
}

resource "kubectl_manifest" "eck-role_binding" {
  depends_on = [kubectl_manifest.eck-cluster_roles_operator_edit]
  yaml_body = <<YAML
# Source: eck-operator/templates/role-bindings.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elastic-operator
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: elastic-operator
subjects:
- kind: ServiceAccount
  name: elastic-operator
  namespace:  ${var.eck_namespace}
YAML
}

resource "kubectl_manifest" "eck-webhook_server" {
  depends_on = [kubectl_manifest.eck-role_binding]
  yaml_body = <<YAML
# Source: eck-operator/templates/webhook.yaml
apiVersion: v1
kind: Service
metadata:
  name: elastic-webhook-server
  namespace:  ${var.eck_namespace}
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
spec:
  ports:
  - name: https
    port: 443
    targetPort: 9443
  selector:
    control-plane: elastic-operator
YAML
}

resource "kubectl_manifest" "eck-statefulSet" {
  depends_on = [kubectl_manifest.eck-webhook_server]
  yaml_body = <<YAML
# Source: eck-operator/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elastic-operator
  namespace:  ${var.eck_namespace}
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
spec:
  selector:
    matchLabels:
      control-plane: elastic-operator
  serviceName: elastic-operator
  replicas: 1
  template:
    metadata:
      annotations:
        # Rename the fields "error" to "error.message" and "source" to "event.source"
        # This is to avoid a conflict with the ECS "error" and "source" documents.
        "co.elastic.logs/raw": "[{\"type\":\"container\",\"json.keys_under_root\":true,\"paths\":[\"/var/log/containers/*$${data.kubernetes.container.id}.log\"],\"processors\":[{\"convert\":{\"mode\":\"rename\",\"ignore_missing\":true,\"fields\":[{\"from\":\"error\",\"to\":\"_error\"}]}},{\"convert\":{\"mode\":\"rename\",\"ignore_missing\":true,\"fields\":[{\"from\":\"_error\",\"to\":\"error.message\"}]}},{\"convert\":{\"mode\":\"rename\",\"ignore_missing\":true,\"fields\":[{\"from\":\"source\",\"to\":\"_source\"}]}},{\"convert\":{\"mode\":\"rename\",\"ignore_missing\":true,\"fields\":[{\"from\":\"_source\",\"to\":\"event.source\"}]}}]}]"
        "checksum/config": 052ce1ebc5f534ea096535035722ec268fcdc842b4dd6f2ac502dff91510aaff
      labels:
        control-plane: elastic-operator
    spec:
      terminationGracePeriodSeconds: 10
      serviceAccountName: elastic-operator
      securityContext:
        runAsNonRoot: true
      containers:
      - image: ${var.eck_operator_image}
        imagePullPolicy: ${var.eck_operator_pull_policy}
        name: manager
        args:
        - "manager"
        - "--config=/conf/eck.yaml"
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
        env:
        - name: OPERATOR_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: WEBHOOK_SECRET
          value: elastic-webhook-server-cert
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 150Mi
        ports:
        - containerPort: 9443
          name: https-webhook
          protocol: TCP
        volumeMounts:
        - mountPath: "/conf"
          name: conf
          readOnly: true
        - mountPath: /tmp/k8s-webhook-server/serving-certs
          name: cert
          readOnly: true
      volumes:
      - name: conf
        configMap:
          name: elastic-operator
      - name: cert
        secret:
          defaultMode: 420
          secretName: elastic-webhook-server-cert
YAML
}

resource "kubectl_manifest" "eck-validating_webhook_configuration" {
  depends_on = [kubectl_manifest.eck-statefulSet]
  yaml_body = <<YAML
# Source: eck-operator/templates/webhook.yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: elastic-webhook.k8s.elastic.co
  labels:
    control-plane: elastic-operator
    app.kubernetes.io/version: ${var.eck_version}
    deployment: terraform
webhooks:
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-agent-k8s-elastic-co-v1alpha1-agent
  failurePolicy: Ignore
  name: elastic-agent-validation-v1alpha1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - agent.k8s.elastic.co
    apiVersions:
    - v1alpha1
    operations:
    - CREATE
    - UPDATE
    resources:
    - agents
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-apm-k8s-elastic-co-v1-apmserver
  failurePolicy: Ignore
  name: elastic-apm-validation-v1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - apm.k8s.elastic.co
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - apmservers
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-apm-k8s-elastic-co-v1beta1-apmserver
  failurePolicy: Ignore
  name: elastic-apm-validation-v1beta1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - apm.k8s.elastic.co
    apiVersions:
    - v1beta1
    operations:
    - CREATE
    - UPDATE
    resources:
    - apmservers
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-beat-k8s-elastic-co-v1beta1-beat
  failurePolicy: Ignore
  name: elastic-beat-validation-v1beta1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - beat.k8s.elastic.co
    apiVersions:
    - v1beta1
    operations:
    - CREATE
    - UPDATE
    resources:
    - beats
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-enterprisesearch-k8s-elastic-co-v1-enterprisesearch
  failurePolicy: Ignore
  name: elastic-ent-validation-v1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - enterprisesearch.k8s.elastic.co
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - enterprisesearches
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-enterprisesearch-k8s-elastic-co-v1beta1-enterprisesearch
  failurePolicy: Ignore
  name: elastic-ent-validation-v1beta1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - enterprisesearch.k8s.elastic.co
    apiVersions:
    - v1beta1
    operations:
    - CREATE
    - UPDATE
    resources:
    - enterprisesearches
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-elasticsearch-k8s-elastic-co-v1-elasticsearch
  failurePolicy: Ignore
  name: elastic-es-validation-v1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - elasticsearch.k8s.elastic.co
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - elasticsearches
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-elasticsearch-k8s-elastic-co-v1beta1-elasticsearch
  failurePolicy: Ignore
  name: elastic-es-validation-v1beta1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - elasticsearch.k8s.elastic.co
    apiVersions:
    - v1beta1
    operations:
    - CREATE
    - UPDATE
    resources:
    - elasticsearches
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-ems-k8s-elastic-co-v1alpha1-mapsservers
  failurePolicy: Ignore
  name: elastic-ems-validation-v1alpha1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - maps.k8s.elastic.co
    apiVersions:
    - v1alpha1
    operations:
    - CREATE
    - UPDATE
    resources:
    - mapsservers
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-kibana-k8s-elastic-co-v1-kibana
  failurePolicy: Ignore
  name: elastic-kb-validation-v1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - kibana.k8s.elastic.co
    apiVersions:
    - v1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kibanas
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-kibana-k8s-elastic-co-v1beta1-kibana
  failurePolicy: Ignore
  name: elastic-kb-validation-v1beta1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - kibana.k8s.elastic.co
    apiVersions:
    - v1beta1
    operations:
    - CREATE
    - UPDATE
    resources:
    - kibanas
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-autoscaling-k8s-elastic-co-v1alpha1-elasticsearchautoscaler
  failurePolicy: Ignore
  name: elastic-esa-validation-v1alpha1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - autoscaling.k8s.elastic.co
    apiVersions:
    - v1alpha1
    operations:
    - CREATE
    - UPDATE
    resources:
    - elasticsearchautoscalers
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-scp-k8s-elastic-co-v1alpha1-stackconfigpolicies
  failurePolicy: Ignore
  name: elastic-scp-validation-v1alpha1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - stackconfigpolicy.k8s.elastic.co
    apiVersions:
    - v1alpha1
    operations:
    - CREATE
    - UPDATE
    resources:
    - stackconfigpolicies
- clientConfig:
    service:
      name: elastic-webhook-server
      namespace:  ${var.eck_namespace}
      path: /validate-logstash-k8s-elastic-co-v1alpha1-logstash
  failurePolicy: Ignore
  name: elastic-logstash-validation-v1alpha1.k8s.elastic.co
  matchPolicy: Exact
  admissionReviewVersions: [v1, v1beta1]
  sideEffects: None
  rules:
  - apiGroups:
    - logstash.k8s.elastic.co
    apiVersions:
    - v1alpha1
    operations:
    - CREATE
    - UPDATE
    resources:
    - logstashes
YAML
}
