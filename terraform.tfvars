######################## Terraform Variables ###################################

##### Elastic Registry Settings #####

# registry_namespace = "elastic-registry"

# elastic_package_registry_image = "docker.elastic.co/package-registry/distribution:8.12.2"
elastic_package_registry_image_pull_policy = "Never"  # Set to Never for Air-Gapped Environments (Pre download the image locally)
# elastic_package_registry_ingress_hostname = "epr.localhost"

# elastic_artifact_registry_image = "elastic-artifact-registry"
elastic_artifact_registry_image_pull_policy = "Never"  # Set to Never for Air-Gapped Environments (Pre download the image locally)
# elastic_artifact_registry_ingress_hostname = "ear.localhost"


##### ECK Settings #####
# eck_namespace = "elasticsystem" #dashes in namespace cause fleet configurations to fail

# eck_operator_image = "docker.elastic.co/eck/eck-operator:2.11.1"
eck_operator_pull_policy = "Never"

##### Elasticsearch Settings #####
# elasticsearch_name = "elasticsearch-sample"
# elasticsearch_image = "docker.elastic.co/elasticsearch/elasticsearch:8.12.2"

##### Kibana Settings #####
# kibana_name = "kibana-sample"
# kibana_image = "docker.elastic.co/kibana/kibana:8.12.2"
# kibana_ingress_hostname = "kb.localhost"

##### Fleet Server Settings #####
# fleet_server_name = "eck-fleet-server"
# elastic_agent_name = "eck-elastic-agent"