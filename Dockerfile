FROM debian:bullseye-slim
MAINTAINER Valerio Di Giampietro "valerio@digiampietro.com"
#
# increase the version to force recompilation of everything
#
ENV MYVERSION 0.8.7
# ------------------------------------------------------------------
# environment variables to avoid that dpkg-reconfigure 
# tries to ask the user any questions
#
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

CMD ["/bin/bash"]

RUN printf '%s\n' \
    'deb http://snapshot.debian.org/archive/debian/20260831T235959Z bullseye main' \
    'deb http://snapshot.debian.org/archive/debian-security/20260831T235959Z bullseye-security main' \
    'deb http://snapshot.debian.org/archive/debian/20260831T235959Z bullseye-updates main' \
    > /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y \
    git \
    gcc \
    libntirpc-dev \
    make \
    nfs-common \
    net-tools \
    procps \
    rsyslog \
 && rm -rf /var/lib/apt/lists/*


# nfs-user-server with v2 support is an abandoned project
# To protect against it disappearing we use a fork in dls-controls
RUN git clone https://github.com/jgoerzen/nfs-user-server /serverfiles
#RUN git clone https://github.com/dls-controls/nfs-user-server /serverfiles
COPY config /config
RUN patch -s -p0 < /config/nfsbuild.patch

RUN cd /serverfiles; cat /config/buildoptions.cfg | ./BUILD; \
    make install; \
    make clean

COPY scripts /scripts
RUN chmod +x -R /scripts
ENV PATH=/scripts/:$PATH

# setup necessary folders
# sendsigs.omit.d Empirically required to start rpcbind
RUN mkdir -p /run/sendsigs.omit.d /iocs /autosave

# configure rsync deamon for debugging
# COPY rsyncd.conf /etc/rsyncd.conf

ENTRYPOINT ["/bin/bash", "-c", "bash startup.sh && sleep infinity"]
#ENTRYPOINT ["tail", "-f", "/dev/null"]
