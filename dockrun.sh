#!/bin/bash
if docker ps -a | grep nfs-userspace
then
    echo "--- Stopping nfs-userspace"
    docker stop nfs-userspace
    echo "--- Removing nfs-userspace"
    docker rm   nfs-userspace
fi
# build the directory mapping argument
MAP="-v /etc/exports:/etc/exports"
for i in `cat /etc/exports | grep -E "^ */" | awk '{print $1}'`
do
    echo "--- mapping $i"
    MAP="$MAP -v $i:$i"
done
echo "--- mapping options"
echo "--- $MAP"

echo "--- running nfs-userspace" 
docker run \
       -h        nfs-userspace \
       --name    nfs-userspace \
       --network host \
       $MAP \
       -itd       digiampietro/nfs-userspace
