# NFSv2 User Space-Docker Image

A docker image, for Linux, that implements the old NFSv2 protocol in user space. The reasons for this implementation are:

- In the Linux kernel, since few years, the support for the NFSv2 protocol has been removed because of its potential security risks. This means that, in recent distributions, to bring back this protocol the kernel must be recompiled with appropriate options, but this isn't a viable solution for many user.
- Some very old computers and equipments, still in use today, can use only the NFSv2 protocol to access shared storage.
- In my case in a recent retro-computing project, involving the installation of the Linux SLS 1.02 ditribution, from 1993, I needed an NFSv2 server to simplify installation and access shared storage.

If the kernel doesn't support the NFSv2, the only viable alternative is a user-space implementation. A docker image uses the existing kernel, so inside Docker only a user-space implementation can work.

This docker image is based on
- Debian Bullseye slim.
- The very old [LINUX User-Space NFS Server](https://github.com/jgoerzen/nfs-user-server) (1998), that implements in user-space the NVFv2 procol and includes an NFS daemon (`rpc.nfsd`) a mount daemon (`rpc.mountd`) and `rpcbind`.
- Some code taken and modified from [NFSv2 and TFTP service]( https://github.com/epics-containers/nfsv2-tftp-server) project

Please note that higher NFS protocl versions, like versions `3` and `4` are not implemented, only NFSv2 is implemented and support both `udp` and `tcp` connections.

## Installation

The prerequisite is the [Docker](https://www.docker.com/) installation. How to install Docker is outside this project scope, it is recommended to add your normal username to the `docker` group to be able to execute the Docker commands without need to be `root`. Probably [Podman](https://podman.io/) will work as well as Docker, but I havent tested it.

- Clone this repository.
- Buil the docker image.
  ```bash
  $ cd nfs-userspace/
  $ ./dockbuild.sh
  ```

## Running

### Prerequisites

The prerequisite is that to prevent conflicts you must not have other NFS services running. In an Ubuntu 24.04 distribution you can check with:
```bash 
$ sudo systemctl status nfs-kernel-server.service nfs-server.service
```
and, eventually, you can stop them with:
```bash
$ sudo systemctl stop nfs-kernel-server.service nfs-server.service
```
and disable them with:
```bash
$ sudo systemctl disable nfs-kernel-server.service nfs-server.service
```

I you don't have the `rpcbind` service running it is fine because this service will run inside the container. If, instead, you have it running it is fine also because, in this case, the `rpcbind` inside the container will nost start and the NFS services will register themselves with the host `rpcbind`.
If you want you can check if you have `rpcbind` running, in Ubuntu 24.04` with:
```bash
$ sudo systemctl status rpcbind rpcbind.socket
```

### NFS sharing configuration

NFS sharing configuration is done in the same way as using the kernel based NFS service, modifying the `/etc/exports` configuration file. It is important to note that the options supported are the ones supported by this old user-space NFS server, you can check the [exports manpage](./exports.md).
An example of an `/etc/exports` file is the following:
```
/export/cd	    192.168.2.0/255.255.255.0(insecure,ro,all_squash,anonuid=0,anongid=0)
/export/misc	192.168.2.0/255.255.255.0(insecure,rw,all_squash,sync,anonuid=1026,anongid=1026)
```

In this example:
- `192.168.2.0/255.255.255.0` means that only clients in this subnet can access the shared folder;
- `insecure` allows connections from ports lower than `1024`;
- `ro` read only, the client cannot modify files on the server;
- `rw` read/write, the client can modify, remove and create files on the server;
- `all_squash` every `userid` on the client side is mapped on the `anonuid` and `anongid` on the server side;

The `/export/cd` is exported read/only and every user on the client side is mapped to the root user on the server side, this allows every user to read each files in this exported directory. Because it is exported read/only no file can be modified.

The `/export/misc` is exported read/only and every user on the client side is mapped to the userid `1026` (my userid) on the server side, this simplify a lot the access to files from the client side where the userids don't match the server's userids.

## Running the NFSv2 server

The server can be started from the downloaded folder `nfs-userspace` executing the script `./dockrun.sh` as in the following example:
```bash
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

This script:
- It stops an already running docker container.
- Starts itself mounting `/etc/exports` and the file sistems included in this file into the Docker container.
- Prints the container id.

The container prints the content of `/var/log/syslog` to its standard output and this output can be inspected and monitored with:
```bash
valerio@ubu24:~/mygit/nfs-userspace$ docker logs -n 100 -f  nfs-userspace
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

For further debugging it is possible to start an interactive shell inside the container:
```bash
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

## On the client

In the following example, a very old Linux, Linux SLS 1.02 from 1993 is successfully able to mount a folder from our Ubuntu 20.04 running our docker container:
```bash
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
drwxr-xr-x   2 root     other        2048 May 12  1993 proc/
drwxrwxrwx   2 root     other        2048 May 12  1993 root/
d---------  49 root     root         6144 May 12  1993 rr_moved/
drwxrwxrwx   3 root     other        2048 May 12  1993 tmp/
drwxr-xr-x   2 root     other        2048 May 12  1993 user/
drwxr-xr-x   8 root     other        2048 May 12  1993 usr/
drwxr-xr-x   3 root     other        2048 Apr 28  1993 xtra/
softland3:/#
```

## Stopping the container

The server can be stopped from the downloaded folder `nfs-userspace` executing the script `./dockrm.sh` as in the following example:
```bash
valerio@ubu24:~/mygit/nfs-userspace$ ./dockrm.sh
edbbbe6eff9f   digiampietro/nfs-userspace   "/bin/bash -c 'bash …"   10 minutes ago   Up 10 minutes                            nfs-userspace
--- Stopping nfs-userspace
nfs-userspace
--- Removing nfs-userspace
nfs-userspace
```
