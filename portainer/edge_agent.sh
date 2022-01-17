#!/bin/bash
docker swarm init

docker network create \
  --driver overlay \
  portainer_agent_network;

docker service create \
  --name portainer_edge_agent \
  --network portainer_agent_network \
  -e AGENT_CLUSTER_ADDR=tasks.portainer_edge_agent \
  -e EDGE=1 \
  -e EDGE_ID=<ID_GENERADO_POR_PORTAINER> \
  -e EDGE_KEY=<KEY_GENERADO_POR_PORTAINER> \
  -e CAP_HOST_MANAGEMENT=1 \
  -e EDGE_INSECURE_POLL=1 \
  --mode global \
  --constraint 'node.platform.os == linux' \
  --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=bind,src=//var/lib/docker/volumes,dst=/var/lib/docker/volumes \
  --mount type=bind,src=//,dst=/host \
  --mount type=volume,src=portainer_agent_data,dst=/data \
  portainer/agent:2.11.0