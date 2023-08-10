# My SNET Service

Personal tutorial on how to publish an snet service, based on [SNET Full Guide (Testnet)](https://docs.google.com/document/d/1jkkIMvUObSc81Cv3WXl9wtjFwt-itFSaOctyGdPg_30).
It is meant for my own consumption.

# Docker

Most of the procedure is scripted in a Dockerfile present in the root
folder of that repository.  Commands should be executed from that root
folder, unless specified otherwise.

To build locally the docker image run

```bash
docker build -t my-snet-service --build-arg org_name=<YOUR_ORG_NAME> .
```

This create an image with everthing you need to publish you service.
A user called `user` is created as well with no password.

Then you can enter a container of that image with

```bash
docker run -it my-snet-service bash -i
```

Once you're inside the container, you may start ETCD

```bash
private_ip=$(hostname -I | awk '{print $1}') && cert_folder=.local/var/lib/etcd/cfssl &&\
 etcd\
  --name member-1\
  --data-dir ~/.local/var/lib/etcd\
  --initial-advertise-peer-urls https://${private_ip}:2380\
  --listen-peer-urls https://${private_ip}:2380\
  --listen-client-urls https://${private_ip}:2379,https://127.0.0.1:2379\
  --advertise-client-urls https://${private_ip}:2379\
  --initial-cluster-token etcd-cluster-1\
  --initial-cluster member-1=https://${private_ip}:2380\
  --client-cert-auth\
  --trusted-ca-file=${cert_folder}/ca.pem\
  --cert-file=${cert_folder}/server.pem\
  --key-file=${cert_folder}/server-key.pem\
  --peer-client-cert-auth\
  --peer-trusted-ca-file=${cert_folder}/ca.pem\
  --peer-cert-file=${cert_folder}/member-1.pem\
  --peer-key-file=${cert_folder}/member-1-key.pem\
  --initial-cluster-state new &
```
