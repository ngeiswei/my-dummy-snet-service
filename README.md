# My SNET Service

Personal tutorial on how to publish an snet service, based on [SNET Full Guide (Testnet)](https://docs.google.com/document/d/1jkkIMvUObSc81Cv3WXl9wtjFwt-itFSaOctyGdPg_30).
It is meant for my own consumption.

## Docker

Most of the procedure is scripted in a Dockerfile present in the root
folder of that repository.  Commands should be executed from that root
folder, unless specified otherwise.

To build locally the docker image run

```bash
docker build -t my-snet-service --build-arg org_name=<YOUR_ORG_NAME> .
```

This creates an image with everthing you need to publish your service.
A user called `user` is created as well with no password.

Then you can enter a container of that image with

```bash
docker run -it my-snet-service bash -i
```

Once you're inside the container, you may start ETCD

```bash
private_ip=$(hostname -I | awk '{print $1}') &&\
 cert_dir=~/.local/var/lib/etcd/cfssl &&\
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
 --trusted-ca-file=${cert_dir}/ca.pem\
 --cert-file=${cert_dir}/server.pem\
 --key-file=${cert_dir}/server-key.pem\
 --peer-client-cert-auth\
 --peer-trusted-ca-file=${cert_dir}/ca.pem\
 --peer-cert-file=${cert_dir}/member-1.pem\
 --peer-key-file=${cert_dir}/member-1-key.pem\
 --initial-cluster-state new &
```

## Troubleshooting

### Docker

Sometimes it may be useful to purge docker images and containers.
This may happen when incrementally building a docker image fails.  To
purge all images and containers from your system, run the following
command:

```bash
docker system prune -a
```

### ETCD

#### Testing

Inside the docker container, after starting ETCD, you may want to test
it.  There are two ways to do that

1. Doing a `health` check via `curl`:

```bash
private_ip=$(hostname -I | awk '{print $1}') &&\
 cert_dir=~/.local/var/lib/etcd/cfssl &&\
 curl --cacert ${cert_dir}/ca.pem --cert ${cert_dir}/client.pem --key ${cert_dir}/client-key.pem https://${private_ip}:2379/health
```

which should output

```
{"health":"true"}
```

2. Putting, getting and deleting values via `etcdctl`:

Put a key value pair:

```bash
cert_dir=~/.local/var/lib/etcd/cfssl &&\
 etcdctl --cacert=${cert_dir}/ca.pem --cert=${cert_dir}/client.pem --key=${cert_dir}/client-key.pem put greeting "Hello, etcd"
```

which should output

```
OK
```

Retrieve the value

```bash
cert_dir=~/.local/var/lib/etcd/cfssl &&\
 etcdctl --cacert=${cert_dir}/ca.pem --cert=${cert_dir}/client.pem --key=${cert_dir}/client-key.pem get greeting
```

which should output

```
greeting
Hello, etcd
```

Delete the key value pair

```bash
cert_dir=~/.local/var/lib/etcd/cfssl &&\
 etcdctl --cacert=${cert_dir}/ca.pem --cert=${cert_dir}/client.pem --key=${cert_dir}/client-key.pem del greeting
```

which should output

```
1
```

#### ETCD Daemon Error Message

After launching the etcd server you get messages such as

```
2023-09-07 12:09:43.693445 I | embed: rejected connection from "127.0.0.1:37776" (error "tls: failed to verify client certificate: x509: certificate specifies an incompatible key usage", ServerName "")
```

This is not a blocking error, it does not stop you from using etcd.
