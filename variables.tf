# DO NOT MODIFIY
# Put any changes or customizations in terraform.tfvars


###################### Registry Configuration Variables ######################
variable "registry_namespace" {
  description   = "Namespace for Elastic Registries"
  type          = string
  default       = "elastic-registry"
}

variable "elastic_package_registry_image" {
  description   = "Docker image URL for Elastic Package Registry"
  type          = string
  default       = "docker.elastic.co/package-registry/distribution:8.12.2"
}

variable "elastic_package_registry_image_pull_policy" {
  description   = "EPR Docker image download policy"
  type          = string
  default       = "IfNotPresent"
}

variable "elastic_package_registry_ingress_hostname" {
  description   = "EPR ingress Hostname"
  type          = string
  default       = "epr.localhost"
}

variable "elastic_artifact_registry_image" {
  description   = "Docker image URL for Elastic Artifact Registry"
  type          = string
  default       = "elastic-artifact-registry"
}

variable "elastic_artifact_registry_image_pull_policy" {
  description   = "EAR Docker image download policy"
  type          = string
  default       = "IfNotPresent"
}

variable "elastic_artifact_registry_ingress_hostname" {
  description   = "EAR ingress Hostname"
  type          = string
  default       = "ear.localhost"
}


###################### ECK Variables ######################
variable "eck_version" {
  description   = "ECK Version"
  type          = string
  default       = "2.11.1"
}

variable "elastic_version" {
  description   = "Elastic Version"
  type          = string
  default       = "8.12.2"
}

variable "eck_namespace" {
  description   = "Namespace for ECK Components"
  type          = string
  default       = "elasticsystem"  #dashes in namespace cause fleet configurations to fail
}

variable "eck_operator_container_registry" {
  description   = "Setting in the eck operator for container registry"
  type          = string
  default       = "docker.elastic.co"
}

variable "eck_operator_image" {
  description   = "Docker image URL for ECK Operator"
  type          = string
  default       = "docker.elastic.co/eck/eck-operator:2.11.1"
}

variable "eck_operator_pull_policy" {
  description   = "ECK Operator Docker image download policy"
  type          = string
  default       = "IfNotPresent"
}


###################### Elasticsearch Variables ######################
variable "elasticsearch_name" {
  description   = "Name of Elasticsearch deployment"
  type          = string
  default       = "eck-elasticsearch"
}

variable "elasticsearch_image" {
  description   = "Docker image URL for Elasticsearch"
  type          = string
  default       = "docker.elastic.co/elasticsearch/elasticsearch:8.12.2"
}

variable "elasticsearch_node_count" {
  description   = "Number of Elasticsearch Nodes"
  type          = number
  default       = 1
}

variable "elasticsearch_node_store_allow_mmap" {
  description   = "Setting for node.store.allow_mmap"
  type          = bool
  default       = false
}

###################### Kibana Variables ######################
variable "kibana_name" {
  description   = "Name of Kibana deployment"
  type          = string
  default       = "eck-kibana"
}

variable "kibana_image" {
  description   = "Docker image URL for Kibana"
  type          = string
  default       = "docker.elastic.co/kibana/kibana:8.12.2"
}

variable "kibana_node_count" {
  description   = "Number of Elasticsearch Nodes"
  type          = number
  default       = 1
}

variable "kibana_ingress_hostname" {
  description   = "Kibana ingress Hostname"
  type          = string
  default       = "kb.localhost"
}

###################### Fleet Server Variables ######################
variable "fleet_server_name" {
  description   = "Name of Fleet Server deployment"
  type          = string
  default       = "eck-fleet-server"
}

variable "elastic_agent_name" {
  description   = "Name of Elastic Agent deployment"
  type          = string
  default       = "eck-elastic-agent"
}