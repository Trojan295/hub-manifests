#!/usr/bin/env bash

set -e

TARGET_REGISTRY="347763108806.dkr.ecr.eu-west-1.amazonaws.com"

#
# Create registries
#

# NOTE: Output from the command `kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}"` edited in IDE

IMAGES=(
   ironbank/opensource/jet/kube-webhook-certgen
   ironbank/elastic/kibana/kibana
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/elastic/kibana/kibana
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/elastic/kibana/kibana
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/kiwigrid/k8s-sidecar
   ironbank/opensource/grafana/grafana
   ironbank/opensource/openpolicyagent/gatekeeper
   ironbank/cluster-auditor/opa-collector
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/opensource/openpolicyagent/gatekeeper
   ironbank/opensource/prometheus/node-exporter
   ironbank/opensource/coreos/kube-state-metrics
   ironbank/opensource/prometheus/alertmanager
   ironbank/opensource/jimmidyson/configmap-reload
   ironbank/opensource/kiali/kiali
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/opensource/prometheus/prometheus
   ironbank/opensource/coreos/prometheus-config-reloader
   ironbank/opensource/jimmidyson/configmap-reload
   ironbank/opensource/jaegertracing/jaeger-operator
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/twistlock/console/console
   ironbank/opensource/coreos/prometheus-operator
   ironbank/opensource/kiali/kiali-operator
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/fluxcd/helm-controller
   ironbank/fluxcd/notification-controller
   ironbank/opensource/fluent/fluent-bit
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/opensource/istio-1.8/pilot
   ironbank/fluxcd/kustomize-controller
   ironbank/opensource/istio-1.8/operator
   ironbank/opensource/jaegertracing/all-in-one
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/elastic/elasticsearch/elasticsearch
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/fluxcd/source-controller
   ironbank/elastic/elasticsearch/elasticsearch
   ironbank/opensource/istio-1.8/proxyv2
   ironbank/elastic/eck-operator/eck-operator
)

for i in "${IMAGES[@]}"
do
aws ecr create-repository \
    --repository-name "$i" \
    --region eu-west-1 --output yaml || true
done

#
# Repush all images
#
# NOTE: Do `aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 347763108806.dkr.ecr.eu-west-1.amazonaws.com` first
# Output from the command `kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}"` edited in IDE

IMAGES=(
   /ironbank/elastic/kibana/kibana:7.12.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/elastic/kibana/kibana:7.12.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/elastic/kibana/kibana:7.12.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/kiwigrid/k8s-sidecar:1.3.0
   /ironbank/opensource/grafana/grafana:7.1.3-1
   /ironbank/opensource/openpolicyagent/gatekeeper:v3.4.0
   /ironbank/cluster-auditor/opa-collector:0.3.2
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/opensource/openpolicyagent/gatekeeper:v3.4.0
   /ironbank/opensource/prometheus/node-exporter:v1.0.1
   /ironbank/opensource/coreos/kube-state-metrics:v1.9.7
   /ironbank/opensource/prometheus/alertmanager:v0.21.0
   /ironbank/opensource/jimmidyson/configmap-reload:v0.4.0
   /ironbank/opensource/kiali/kiali:v1.32.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/opensource/prometheus/prometheus:v2.22.0
   /ironbank/opensource/coreos/prometheus-config-reloader:v0.42.1
   /ironbank/opensource/jimmidyson/configmap-reload:v0.4.0
   /ironbank/opensource/jaegertracing/jaeger-operator:1.23.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/twistlock/console/console:21.04.412
   /ironbank/opensource/coreos/prometheus-operator:v0.42.1
   /ironbank/opensource/kiali/kiali-operator:v1.32.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/fluxcd/helm-controller:v0.9.0
   /ironbank/fluxcd/notification-controller:v0.12.0
   /ironbank/opensource/fluent/fluent-bit:1.7.8
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/opensource/istio-1.8/pilot:1.8.4
   /ironbank/fluxcd/kustomize-controller:v0.9.3
   /ironbank/opensource/istio-1.8/operator:1.8.4
   /ironbank/opensource/jaegertracing/all-in-one:1.23.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/elastic/elasticsearch/elasticsearch:7.12.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/fluxcd/source-controller:v0.9.1
   /ironbank/elastic/elasticsearch/elasticsearch:7.12.0
   /ironbank/opensource/istio-1.8/proxyv2:1.8.4
   /ironbank/elastic/eck-operator/eck-operator:1.6.0
   /ironbank/opensource/jet/kube-webhook-certgen:v1.5.1
)

for i in "${IMAGES[@]}"
do

   source_image="localhost:5000$i"
   echo "> $source_image"
   docker pull "$source_image"

   target_image="$TARGET_REGISTRY$i"
   docker tag "$source_image" "$target_image"
   docker push "$target_image"
done
