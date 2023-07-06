# My Dummy SNET Service

Personal tutorial on how to publish an snet service.  It is meant for
my own consumption.

# Docker

Most of the procedure is scripted in a Dockerfile present in the root
folder of that repository.  Commands should be executed from that root
folder, unless specified otherwise.

To build locally that docker image run

```bash
docker build -t my-dummy-snet-service .
```

Then enter a container of that image with

```bash
docker run -it my-dummy-snet-service bash -i
```

<!-- Once you're inside the container, you may start the etcd docker -->

<!-- ```bash -->
<!-- docker start docker-etcd-node-1 -->
<!-- ``` -->

