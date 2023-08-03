FROM ubuntu:20.04

# Install prerequisites
RUN apt update
RUN apt install -y sudo
RUN apt install -y wget
RUN apt install -y neofetch
RUN apt install -y emacs
RUN apt install -y python3 python3-pip git
RUN apt install -y nodejs npm
RUN apt install -y ca-certificates curl gnupg lsb-release
# RUN apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create user
RUN useradd -m -G sudo -p "" user
RUN chsh -s /bin/bash user
USER user
ENV HOME /home/user
WORKDIR ${HOME}

# Set local bin
ENV LOCAL_BIN ${HOME}/.local/bin
ENV PATH "$LOCAL_BIN:$PATH"
RUN mkdir -p ${LOCAL_BIN}

# Install ETCD
ENV ETCD_VER v3.4.27
ENV ETCD_DOWNLOAD_URL https://github.com/etcd-io/etcd/releases/download
ENV ETCD_DIR etcd-${ETCD_VER}-linux-amd64
ENV ETCD_ARCHIVE ${ETCD_DIR}.tar.gz
RUN curl -L ${ETCD_DOWNLOAD_URL}/${ETCD_VER}/${ETCD_ARCHIVE} -o ${ETCD_ARCHIVE}
RUN tar xzvf ${ETCD_ARCHIVE}
RUN rm ${ETCD_ARCHIVE}
RUN cp ${ETCD_DIR}/etcd ${LOCAL_BIN}
RUN cp ${ETCD_DIR}/etcdctl ${LOCAL_BIN}

# Configure ETCD
RUN curl -s -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o ${LOCAL_BIN}/cfssl
RUN curl -s -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o ${LOCAL_BIN}/cfssljson
RUN chmod a+x ${LOCAL_BIN}/cfssl
RUN chmod a+x ${LOCAL_BIN}/cfssljson
# NEXT: continue from line 60 of docker-etcd-setup.sh

# Install SNET daemon
ENV SNET_DAEMON_URL "https://drive.google.com/u/0/uc?id=1jbme-TD_HVOlyvkdcT_B0iOOzUpM9c3r&export=download"
RUN wget ${SNET_DAEMON_URL} -O snetd
RUN chmod +x snetd
RUN touch snetd.config.json

# Install SNET CLI
RUN git clone https://github.com/singnet/snet-cli.git
WORKDIR snet-cli/packages/snet_cli
RUN ./scripts/blockchain install
RUN pip3 install -e .
WORKDIR ${HOME}
