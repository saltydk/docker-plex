FROM ubuntu:20.04

ARG S6_OVERLAY_VERSION=v2.2.0.3
ARG S6_OVERLAY_ARCH=amd64
ARG PLEX_BUILD=linux-x86_64
ARG PLEX_DISTRO=debian
ARG DEBIAN_FRONTEND="noninteractive"
ARG INTEL_NEO_VERSION=22.23.23405
ARG INTEL_IGC_VERSION=1.0.11378
ARG INTEL_GMMLIB_VERSION=22.1.3
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

ENTRYPOINT ["/init"]

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get install -y \
      tzdata \
      wget \
      curl \
      xmlstarlet \
      uuid-runtime \
      unrar \
      beignet-opencl-icd \
      ocl-icd-libopencl1 \
    && \
    \
# Fetch and extract S6 overlay
    curl -J -L -o /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz -C / --exclude='./bin' && \
    tar xzf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz -C /usr ./bin && \
    \
# Fetch and install Intel Compute Runtime and its deps
    mkdir neo && \
    cd neo && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.11378/intel-igc-core_1.0.11378_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.11378/intel-igc-opencl_1.0.11378_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.23.23405/intel-level-zero-gpu-dbgsym_1.3.23405_amd64.ddeb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.23.23405/intel-level-zero-gpu_1.3.23405_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.23.23405/intel-opencl-icd-dbgsym_22.23.23405_amd64.ddeb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.23.23405/intel-opencl-icd_22.23.23405_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.23.23405/libigdgmm12_22.1.3_amd64.deb && \
    dpkg -i *.deb && \
    cd .. && \
    rm -rf neo && \
    \
# Add user
    useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex && \
    \
# Setup directories
    mkdir -p \
      /config \
      /transcode \
      /data \
    && \
    \
# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=beta
ARG URL=

COPY root/ /

RUN \
# Save version and install
    /installBinary.sh

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1
