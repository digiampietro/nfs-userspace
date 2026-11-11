#!/bin/bash
if docker ps -a | grep nfs-userspace
then
    echo "--- Stopping nfs-userspace"
    docker stop nfs-userspace
    echo "--- Removing nfs-userspace"
    docker rm   nfs-userspace
fi
