FROM ubuntu:22.04

# Install prerequisites
RUN apt update
RUN apt install -y wget
RUN apt install -y neofetch
RUN apt install -y emacs
RUN apt install -y python3 python3-pip git
RUN apt install -y nodejs npm

# Create user
RUN useradd -m user
RUN chsh -s /bin/bash user
USER user
WORKDIR /home/user

# Set up environment variables
ENV PATH="$HOME/.local/bin:$PATH"

# Install SNET (obtained from https://docs.google.com/document/d/1jkkIMvUObSc81Cv3WXl9wtjFwt-itFSaOctyGdPg_30/edit?pli=1)

# Install SNET deamon
RUN wget "https://drive.google.com/u/0/uc?id=1jbme-TD_HVOlyvkdcT_B0iOOzUpM9c3r&export=download" -O snetd
RUN chmod +x snetd
RUN touch snetd.config.json

# Install SNET CLI
RUN git clone https://github.com/singnet/snet-cli.git
WORKDIR snet-cli/packages/snet_cli
RUN ./scripts/blockchain install
# RUN pip3 install -e .           # <- THIS FAILS

# # # Install ETCD
# # RUN wget https://raw.githubusercontent.com/singnet/platform-setup/main/docker-etcd-setup.sh
# # RUN bash docker-etcd-setup.sh
