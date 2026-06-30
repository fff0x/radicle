# Deploying a Radicle node on Kubernetes

A self-contained [kustomize](https://kustomize.io/) example that runs a
[Radicle](https://radicle.xyz/) seed node on Kubernetes.

## Quickstart

```sh
kubectl apply -k deploy
```

This creates a `Deployment`, a `radicle-seeds` `ConfigMap`, a `seed-node`
`LoadBalancer` Service (p2p protocol on `8776`), a `seed-node-http` `ClusterIP`
Service (HTTP API/web on `8080`), and a 10Gi `PersistentVolumeClaim` for the node
identity + repo storage.

## Verify the image signature

Images are signed with [cosign](https://docs.sigstore.dev/) using a fixed key —
[`cosign.pub`](cosign.pub). Verify before pulling/deploying:

```sh
cosign verify --key cosign.pub oci.this-is-fine.io/radicle/node:latest
```

If a copy was not published to a transparency log, add `--insecure-ignore-tlog`.

## Configure

Node settings are plain environment variables in `deployment.yaml`:

| Env var             | Purpose                                          | Default                   |
| ------------------- | ------------------------------------------------ | ------------------------- |
| `RAD_ALIAS`         | Node display name                                | `my-seed`                 |
| `RAD_EXTERNAL_ADDR` | Publicly reachable `<host>:<node-port>`          | `seed.<domain.tld>:8776`   |
| `RAD_DESCRIPTION`   | Node description shown on the web view            | `My Radicle seed node`    |

Seed/pin lists are public Repository IDs and live in the `radicle-seeds` ConfigMap
(`config.yaml`) — `RAD_SEEDS`, `RAD_PRIVATE_SEEDS`, `RAD_PINNED_REPOS`.

What to change per file:

| File              | Change                                                            |
| ----------------- | ----------------------------------------------------------------- |
| `deployment.yaml` | `RAD_ALIAS`, `RAD_EXTERNAL_ADDR`, `RAD_DESCRIPTION`; pin image tag |
| `config.yaml`     | RIDs in `RAD_SEEDS` / `RAD_PRIVATE_SEEDS` / `RAD_PINNED_REPOS`     |
| `service.yaml`    | Service type if you route p2p without a `LoadBalancer`            |
| `pvc.yaml`        | `storage` size and `storageClassName` if needed                   |

## Expose

- **p2p** — the `seed-node` LoadBalancer Service exposes port `8776`. Point the DNS
  used in `RAD_EXTERNAL_ADDR` at its external IP so peers can reach the node.
- **HTTP/web** — front the `seed-node-http` Service port `8080` with an
  Ingress/HTTPRoute and TLS.

## Use as a GitOps base

```yaml
resources:
  - https://your-git-host/radicle//node/deploy?ref=main
```

## Uninstall

```sh
kubectl delete -k deploy
```

> The PVC holds the node's identity keypair — deleting it changes the Node ID.
> Back up `/node/radicle` first if you want to keep the same identity.
