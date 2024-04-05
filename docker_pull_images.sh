#! /bin/bash

# Package Registry
docker pull docker.elastic.co/package-registry/distribution:8.13.1

# Artifact Registry is built using docker build command, see sub directory.

# ECK Operator
docker pull docker.elastic.co/eck/eck-operator:2.12.1

# Elasticsearch
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.13.1

# Kibana
docker pull docker.elastic.co/kibana/kibana:8.13.1

# Elastic Agent
docker pull docker.elastic.co/beats/elastic-agent:8.13.1

