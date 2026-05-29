# Deploy radicle/node

Uses the shared chart [`../../charts/generic`](../../charts/generic) with the values in this directory.

## Prerequisites

- [Helm 3](https://helm.sh/docs/intro/install/)
- Cluster access (`kubectl`)
- Image published at `oci.this-is-fine.io/radicle/node` (or override `image.*` in `values.yaml`)

Chart install from OCI (versions, signing): [`../../charts/README.md`](../../charts/README.md).

## Install

From this directory:

```bash
helm upgrade --install seed-node ../../charts/generic \
  -n radicle --create-namespace \
  -f values.yaml
```

Or from the repo root:

```bash
helm upgrade --install seed-node images/charts/generic \
  -n radicle --create-namespace \
  -f images/radicle/deploy/values.yaml
```

## Configure

Edit [`values.yaml`](values.yaml):

| Key | Purpose |
|-----|---------|
| `env` | Container env vars (`RAD_ALIAS`, `RAD_SEEDS`, …) — see [../README.md](../README.md) |
| `persistence.size` | PVC size for `/node/radicle` |
| `ports` | HTTP `:8080`, P2P `:8776` |

**Client node** (sidecar): set `MODE=client-node` in `env`, add identity secret via `extraVolumes` / `extraVolumeMounts` (see chart defaults).

Example override file:

```bash
helm upgrade --install seed-node ../../charts/generic \
  -n radicle --create-namespace \
  -f values.yaml -f my-overrides.yaml
```

## Verify

```bash
kubectl -n radicle get pods
kubectl -n radicle exec deploy/seed-node -- rad seed
```

## Uninstall

```bash
helm uninstall seed-node -n radicle
```

PVC is retained unless you delete it manually.

## Preview manifests

```bash
helm template seed-node ../../charts/generic \
  -n radicle -f values.yaml
```
