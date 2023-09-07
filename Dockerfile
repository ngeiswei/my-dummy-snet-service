FROM ubuntu:20.04

# Install prerequisites
RUN apt update
RUN apt install -y sudo
RUN apt install -y wget
RUN apt install -y tree
RUN apt install -y psmisc
RUN apt install -y neofetch
RUN apt install -y emacs
RUN apt install -y python3 python3-pip git
RUN apt install -y nodejs npm
RUN apt install -y ca-certificates curl gnupg lsb-release

# Create user
ENV USER=user
RUN useradd -m -G sudo -p "" user
RUN chsh -s /bin/bash user
USER ${USER}
ENV HOME=/home/${USER}
WORKDIR ${HOME}

# Set local directories
ENV LOCAL=${HOME}/.local
ENV PATH=${LOCAL}/bin:${PATH}
RUN mkdir -p ${LOCAL}/bin

# Install ETCD
ENV ETCD_VER=v3.4.27
ENV ETCD_DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download
ENV ETCD_DIR=etcd-${ETCD_VER}-linux-amd64
ENV ETCD_ARCHIVE=${ETCD_DIR}.tar.gz
RUN curl -L ${ETCD_DOWNLOAD_URL}/${ETCD_VER}/${ETCD_ARCHIVE} -o ${ETCD_ARCHIVE}
RUN tar xzvf ${ETCD_ARCHIVE}
RUN rm ${ETCD_ARCHIVE}
RUN cp ${ETCD_DIR}/etcd ${LOCAL}/bin
RUN cp ${ETCD_DIR}/etcdctl ${LOCAL}/bin

# Install CFSSL
RUN curl -s -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o ${LOCAL}/bin/cfssl
RUN curl -s -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o ${LOCAL}/bin/cfssljson
RUN chmod a+x ${LOCAL}/bin/cfssl
RUN chmod a+x ${LOCAL}/bin/cfssljson

# Configure ETCD
ENV VAR_ETCD_DIR=${LOCAL}/var/lib/etcd
ENV CERT_DIR=${VAR_ETCD_DIR}/cfssl
RUN mkdir -p ${CERT_DIR}
RUN chmod 700 -R ${VAR_ETCD_DIR}
WORKDIR ${CERT_DIR}
ENV years=5
RUN validity=$((years*365*24)) &&\
    echo "{\n\
    \"signing\": {\n\
        \"default\": {\n\
            \"expiry\": \"${validity}h\"\n\
        },\n\
        \"profiles\": {\n\
            \"server\": {\n\
                \"expiry\": \"${validity}h\",\n\
                \"usages\": [\n\
                    \"signing\",\n\
                    \"key encipherment\",\n\
                    \"server auth\"\n\
                ]\n\
            },\n\
            \"client\": {\n\
                \"expiry\": \"${validity}h\",\n\
                \"usages\": [\n\
                    \"signing\",\n\
                    \"key encipherment\",\n\
                    \"client auth\"\n\
                ]\n\
            },\n\
            \"peer\": {\n\
                \"expiry\": \"${validity}h\",\n\
                \"usages\": [\n\
                    \"signing\",\n\
                    \"key encipherment\",\n\
                    \"server auth\",\n\
                    \"client auth\"\n\
                ]\n\
            }\n\
        }\n\
    }\n\
}" > ca-config.json
RUN echo "{\n\
    \"CN\": \"${org_name} CA\",\n\
    \"key\": {\n\
        \"algo\": \"rsa\",\n\
        \"size\": 2048\n\
    },\n\
    \"names\": [\n\
        {\n\
            \"C\": \"US\",\n\
            \"L\": \"CA\",\n\
            \"O\": \"${org_name} Name\",\n\
            \"ST\": \"San Francisco\",\n\
            \"OU\": \"Org Unit 1\",\n\
            \"OU\": \"Org Unit 2\"\n\
        }\n\
    ]\n\
}" > ca-csr.json
RUN cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
RUN public_ip=$(curl ifconfig.me) && private_ip=$(hostname -I | awk '{print $1}') &&\
    echo "{\n\
    \"CN\": \"etcd-cluster\",\n\
    \"hosts\": [\n\
        \"${public_ip}\",\n\
        \"${private_ip}\",\n\
        \"127.0.0.1\"\n\
    ],\n\
    \"key\": {\n\
        \"algo\": \"ecdsa\",\n\
        \"size\": 256\n\
    },\n\
    \"names\": [\n\
        {\n\
            \"C\": \"US\",\n\
            \"L\": \"CA\",\n\
            \"ST\": \"San Francisco\"\n\
        }\n\
    ]\n\
}" > server.json
RUN cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server
RUN private_ip=$(hostname -I | awk '{print $1}') &&\
    echo "{\n\
    \"CN\": \"member-1\",\n\
    \"hosts\": [\n\
      \"member-1\",\n\
      \"member-1.local\",\n\
      \"${private_ip}\",\n\
      \"127.0.0.1\"\n\
    ],\n\
    \"key\": {\n\
        \"algo\": \"ecdsa\",\n\
        \"size\": 256\n\
    },\n\
    \"names\": [\n\
        {\n\
            \"C\": \"US\",\n\
            \"L\": \"CA\",\n\
            \"ST\": \"San Francisco\"\n\
        }\n\
    ]\n\
}" > member-1.json
RUN cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer member-1.json | cfssljson -bare member-1
RUN echo "{\n\
    \"CN\": \"client\",\n\
    \"hosts\": [\"\"],\n\
    \"key\": {\n\
        \"algo\": \"ecdsa\",\n\
        \"size\": 256\n\
    },\n\
    \"names\": [\n\
        {\n\
            \"C\": \"US\",\n\
            \"L\": \"CA\",\n\
            \"ST\": \"San Francisco\"\n\
        }\n\
    ]\n\
}" > client.json
RUN cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

# Install SNET daemon
WORKDIR ${LOCAL}/bin
ENV SNET_DAEMON_URL "https://drive.google.com/u/0/uc?id=1jbme-TD_HVOlyvkdcT_B0iOOzUpM9c3r&export=download"
RUN wget ${SNET_DAEMON_URL} -O snetd
RUN chmod +x snetd
RUN touch snetd.config.json

# Install SNET CLI
WORKDIR ${HOME}
RUN git clone https://github.com/singnet/snet-cli.git
WORKDIR snet-cli/packages/snet_cli
RUN ./scripts/blockchain install
RUN pip3 install -e .
WORKDIR ${HOME}
