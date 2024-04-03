######################## Terraform Variables ###################################

##### Provider Settings #####
kube_config_path = "~/.kube/config"
kube_config_context_cluster = "docker-desktop"
kube_config_host = "https://kubernetes.docker.internal:6443"

##### Elastic Registry Settings #####

# registry_namespace = "elastic-registry"

# elastic_package_registry_image = "docker.elastic.co/package-registry/distribution:8.12.2"
elastic_package_registry_image_pull_policy = "Never"  # Set to Never for Air-Gapped Environments (Pre download the image locally)
elastic_package_registry_ingress_hostname = "epr.k8s.internal"

# elastic_artifact_registry_image = "elastic-artifact-registry"
elastic_artifact_registry_image_pull_policy = "Never"  # Set to Never for Air-Gapped Environments (Pre download the image locally)
elastic_artifact_registry_ingress_hostname = "ear.k8s.internal"


##### ECK Settings #####
# eck_namespace = "elasticsystem" #dashes in namespace cause fleet configurations to fail

# eck_operator_image = "docker.elastic.co/eck/eck-operator:2.11.1"
eck_operator_pull_policy = "Never"

##### Elasticsearch Settings #####
elasticsearch_elastic_user_password = "ChangeMeElastic123"
# elasticsearch_name = "elasticsearch-sample"
# elasticsearch_image = "docker.elastic.co/elasticsearch/elasticsearch:8.12.2"
elasticsearch_ingress_hostname = "es.k8s.internal"
elasticsearch_node_count = 1

##### Kibana Settings #####
# kibana_name = "kibana-sample"
# kibana_image = "docker.elastic.co/kibana/kibana:8.12.2"
kibana_ingress_hostname = "kb.k8s.internal"
kibana_node_count = 1

##### Fleet Server Settings #####
# fleet_server_name = "eck-fleet-server"
# elastic_agent_name = "eck-elastic-agent"
fleet_server_ingress_hostname = "fleet-server.k8s.internal"
# elastic_agent_image = "docker.elastic.co/beats/elastic-agent:8.12.2"