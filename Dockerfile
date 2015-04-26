FROM debian:wheezy
MAINTAINER Faye Salwin "faye.salwin@opower.com"

RUN apt-get update && apt-get -y install  unzip \
                        xz-utils \
                        curl \
                        bc \
                        git \
                        build-essential \
                        cpio \
                        gcc-multilib libc6-i386 libc6-dev-i386 \
                        kmod \
                        squashfs-tools \
                        genisoimage \
                        xorriso \
                        syslinux \
                        automake \
                        pkg-config \
                        p7zip-full

# http://sourceforge.net/p/aufs/aufs3-standalone/ref/master/branches/
ENV AUFS_BRANCH     aufs3.18.1+
ENV AUFS_COMMIT     863c3b76303a1ebea5b6a5b1b014715ac416f913
# we use AUFS_COMMIT to get stronger repeatability guarantees

# Fetch the kernel sources
# https://www.kernel.org/
RUN KERNEL_VERSION=$(uname -r) && \
    KERNEL_VERSION=${KERNEL_VERSION%-*} && \
    curl --retry 10 https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL_VERSION.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION /linux-kernel

# Download AUFS and apply patches and files, then remove it
RUN git clone -b $AUFS_BRANCH http://git.code.sf.net/p/aufs/aufs3-standalone && \
    cd aufs3-standalone && \
    git checkout $AUFS_COMMIT && \
    cd /linux-kernel && \
    cp -r /aufs3-standalone/Documentation /linux-kernel && \
    cp -r /aufs3-standalone/fs /linux-kernel && \
    cp -r /aufs3-standalone/include/uapi/linux/aufs_type.h /linux-kernel/include/uapi/linux/ &&\
    for patch in aufs3-kbuild aufs3-base aufs3-mmap aufs3-standalone aufs3-loopback; do \
        patch -p1 < /aufs3-standalone/$patch.patch; \
    done

COPY kernel_config /linux-kernel/.config

RUN jobs=$(nproc); \
    cd /linux-kernel && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

RUN make -C /linux-kernel INSTALL_MOD_PATH=/default modules_install

COPY module_config /linux-kernel/.config

RUN jobs=$(nproc); \
    cd /linux-kernel && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

RUN make -C /linux-kernel INSTALL_MOD_PATH=/new modules_install
RUN rsync -rlmc --compare-dest=/default/ /new/* /target/
RUN cd /target && tar -jcvf /tmp/modules.tar.bz2 $(find * -type f)
CMD ["cat", "/tmp/modules.tar.bz2"]
