# NFSv2 Userspace Docker Image

A Docker image that provides a userspace implementation of the legacy NFSv2 protocol. It allows vintage and retro clients to mount directories exported by modern Linux distributions.

This image is useful because:

- Recent Linux distributions often disable NFSv2 server support in their kernels, or omit it from their kernel builds. Re-enabling it may require rebuilding the kernel, which is not a practical solution for many users.
- Some very old computers and devices still in use today can only access shared storage using NFSv2.
- I needed an NFSv2 server for a recent retrocomputing project involving the installation of the Linux SLS 1.02 distribution from 1993. The server makes installation and access to shared storage easier.

When the host kernel does not support NFSv2, a userspace implementation is an alternative. Docker containers use the host's kernel, so this image runs the NFS server in userspace.

This image is based on:

- Debian Bullseye slim.
- The very old [Linux User-Space NFS Server](https://github.com/jgoerzen/nfs-user-server) (1998), which implements NFSv2 in userspace. It includes an NFS daemon (`rpc.nfsd`), a mount daemon (`rpc.mountd`), and `rpcbind`.
- Some code adapted from the [NFSv2 and TFTP service](https://github.com/epics-containers/nfsv2-tftp-server) project.

This image supports only NFSv2; it does not implement NFSv3 or NFSv4. NFSv2 connections can use either UDP or TCP.

## Installation

Docker must be installed before using this image. Installing Docker is outside the scope of this project. To run Docker commands without `sudo`, you can add your regular user to the `docker` group. Be aware that membership in this group effectively grants root-level control over the host.

Podman may also work, but I have not tested it.

1. Clone this repository.
   ```bash
   git clone https://github.com/digiampietro/nfs-userspace.git
   ```
2. Build the Docker image:

   ```bash
   cd nfs-userspace/
   ./dockbuild.sh
   ```

## Running

### Prerequisites

To avoid conflicts, stop any other NFS server services before starting this container. On Ubuntu 24.04, check their status with:

```bash
sudo systemctl status nfs-kernel-server.service nfs-server.service
```

If either service is running, stop it:

```bash
sudo systemctl stop nfs-kernel-server.service nfs-server.service
```

If you do not want those services to start automatically, disable them:

```bash
sudo systemctl disable nfs-kernel-server.service nfs-server.service
```

This container uses the host network. There must be only one `rpcbind` instance on that network: if the host's `rpcbind` service is already running, the container shares it; otherwise, `rpcbind` starts inside the container.

On Ubuntu 24.04, check whether `rpcbind` is running with:

```bash
sudo systemctl status rpcbind rpcbind.socket
```

### NFS export configuration

Configure NFS exports in `/etc/exports`, just as you would when using the kernel NFS server. The available options depend on the old userspace NFS server. See the [`exports` man page](./exports.md) for details.

Here is an example `/etc/exports` file:

```text
/export/cd     192.168.2.0/255.255.255.0(insecure,ro,all_squash,anonuid=0,anongid=0)
/export/misc   192.168.2.0/255.255.255.0(insecure,rw,all_squash,sync,anonuid=1026,anongid=1026)
```

In this example:

- `192.168.2.0/255.255.255.0` allows clients on this subnet to access the export.
- `insecure` allows requests from unprivileged source ports.
- `ro` makes the export read-only.
- `rw` allows clients to create, modify, and remove files.
- `all_squash` maps every client user to the anonymous user and group specified by `anonuid` and `anongid`.

The `/export/cd` directory is exported read-only, and all client users are mapped to UID 0 and GID 0 on the server. Because the export is read-only, clients cannot modify its files.

The `/export/misc` directory is exported read/write, and all client users are mapped to UID 1026 and GID 1026 on the server. This can simplify file access when user IDs differ between the client and server.

## Starting the NFSv2 server

From the cloned `nfs-userspace` directory, start the server by running `./dockrun.sh`. For example:

```console
valerio@ubu24:~/mygit/nfs-userspace$ ./dockrun.sh
6218e1b205c0   digiampietro/nfs-userspace   "/bin/bash -c 'bash …"   5 hours ago   Up 5 hours                            nfs-userspace
--- Stopping nfs-userspace
nfs-userspace
--- Removing nfs-userspace
nfs-userspace
--- mapping /export/cd
--- mapping /export/misc
--- mapping options
--- -v /etc/exports:/etc/exports -v /export/cd:/export/cd -v /export/misc:/export/misc
--- running nfs-userspace
0ca046039d7e322c19ad5e75cce0c6897ba47b923ebb9314712229738c485ab7
```

The script:

- Stops and removes any existing container named `nfs-userspace`.
- Mounts `/etc/exports` and the directories listed in that file into the container.
- Starts the container and prints its ID.

The container writes its logs to `/var/log/syslog`. The log output is also sent to standard output and can be viewed with:

```bash
docker logs --tail 100 --follow nfs-userspace
```

For example:

```console
valerio@ubu24:~/mygit/nfs-userspace$ docker logs --tail 100 --follow nfs-userspace
configuring NFSv2
...
Starting enhanced syslogd: rsyslogd.
Starting RPC port mapper daemon: rpcbind.
Starting NFS servers: nfsd mountd.
NFSv2 now live
output of tail -20f /var/log/syslog
-----------------------------------
Nov 11 19:23:38 nfs-userspace rsyslogd: [origin software="rsyslogd" swVersion="8.2102.0" x-pid="18" x-info="https://www.rsyslog.com"] start
Nov 11 19:23:45 nfs-userspace mountd[56]: NFS mount of /export/cd attempted from 192.168.2.23
Nov 11 19:23:45 nfs-userspace mountd[56]: /export/cd has been mounted by 192.168.2.23
```

To open an interactive shell in the container for debugging:

```console
valerio@ubu24:~/mygit/nfs-userspace$ docker exec -it nfs-userspace /bin/bash
root@nfs-userspace:/# rpcinfo -p
   program vers proto   port  service
    100000    4   tcp    111  portmapper
    100000    3   tcp    111  portmapper
    100000    2   tcp    111  portmapper
    100000    4   udp    111  portmapper
    100000    3   udp    111  portmapper
    100000    2   udp    111  portmapper
    100003    2   udp   2049  nfs
    100003    2   tcp   2049  nfs
    100005    1   udp  20048  mountd
    100005    2   udp  20048  mountd
    100005    1   tcp  20048  mountd
    100005    2   tcp  20048  mountd
root@nfs-userspace:/#
```

## Client example

The following example shows a very old Linux client successfully mounting an exported directory from an Ubuntu 20.04 host running this container:

```console
softland3:/# cat /etc/motd

Welcome to Linux SLS 1.01. Type "menu" for a menu driven interface

softland3:/# uname -a
Linux softland3 0.99.pl9-1 04/27/93 i486
softland3:/# mount 192.168.2.76:/export/cd /mnt/cd
softland3:/# ls -l /mnt/cd
total 352
-rw-r--r--   1 root     other      268804 Apr 27  1993 Image
-rwxrwxrwx   1 root     other         821 May 12  1993 YMTRANS.TBL*
drwxr-xr-x   2 root     other       12288 May 12  1993 bin/
drwxrwxrwx   2 root     other       24576 May 12  1993 dev/
drwxr-xr-x   6 root     other       16384 May 12  1993 etc/
drwxr-xr-x   3 root     other        2048 May 12  1993 home/
drwxr-xr-x   2 root     other        2048 May 12  1993 info/
drwxr-xr-x  35 root     other        6144 May 12  1993 install/
drwxrwxrwx   4 root     other        2048 May 12  1993 interviews/
drwxr-xr-x   2 root     other        4096 May 12  1993 lib/
lrwxrwxrwx   1 root     other          13 May 12  1993 linux -> usr/src/linux/
drwxr-xr-x   2 root     other        2048 May 12  1993 mnt/
drwxrwxrwx   2 root     other        2048 May 12  1993 proc/
drwxrwxrwx   2 root     other        2048 May 12  1993 root/
d---------  49 root     root         6144 May 12  1993 rr_moved/
drwxrwxrwx   3 root     other        2048 May 12  1993 tmp/
drwxr-xr-x   2 root     other        2048 May 12  1993 user/
drwxr-xr-x   8 root     other        2048 May 12  1993 usr/
drwxr-xr-x   3 root     other        2048 Apr 28  1993 xtra/
softland3:/#
```

## Stopping the container

From the cloned `nfs-userspace` directory, stop and remove the container by running `./dockrm.sh`. For example:

```console
valerio@ubu24:~/mygit/nfs-userspace$ ./dockrm.sh
edbbbe6eff9f   digiampietro/nfs-userspace   "/bin/bash -c 'bash …"   10 minutes ago   Up 10 minutes                            nfs-userspace
--- Stopping nfs-userspace
nfs-userspace
--- Removing nfs-userspace
nfs-userspace
```
