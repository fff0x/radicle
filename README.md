# radicle/node

[![CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fci.this-is-fine.io%2Fbadge%2Fradicle.json)](https://ci.this-is-fine.io/)

Alpine-based container for a [Radicle](https://radicle.xyz/) **seed node** (public hub + HTTP dashboard) or **client node** (outbound P2P, e.g. ZeroClaw sidecar).

Registry: **`oci.this-is-fine.io/radicle/node`** (`:latest`, `:<git-sha>`). Built and cosign-signed by `images/.build.yml`.

Based on [seed.radicle.garden](https://app.radicle.xyz/nodes/seed.radicle.garden/rad:zNd4qti1Jc69mCBQAdBeK3Avzy4R).

## Modes

| `MODE` | Role | Typical use |
|--------|------|-------------|
| `seed-node` (default) | Public seed + `radicle-httpd` on `:8080`, P2P on `:8776` | `seed.this-is-fine.io` |
| `client-node` | Outbound-only node, identity from PVC or secret | ZeroClaw `radicle-node` sidecar |

Entrypoint logic: [`ep`](ep).

## Environment variables

### seed-node

**Required**

| Variable | Description |
|----------|-------------|
| `RAD_ALIAS` | Node alias (e.g. `seed.this-is-fine.io`) |

**Optional**

| Variable | Description |
|----------|-------------|
| `RAD_EXTERNAL_ADDR` | Public dial address advertised to peers (`host:8776`) |
| `RAD_SEEDING_POLICY` | Default policy: `block` (default) or `allow` — sets `node.seedingPolicy.default` |
| `RAD_SEEDS` | Semicolon-separated RIDs — each `rad seed $RID --scope all` |
| `RAD_PRIVATE_SEEDS` | `rad:$RID@$NID;…` — each `rad seed … --from $NID --scope all` |
| `RAD_PINNED_REPOS` | Semicolon-separated RIDs — pinned in web UI and seeded with `--scope all` |
| `RAD_BANNER_URL` | Seedling dashboard banner |
| `RAD_AVATAR_URL` | Seedling dashboard avatar |
| `RAD_DESCRIPTION` | Seedling dashboard description |

**Seeding model:** default **`block`** (selective). Listed repos are **`allow`** with **`--scope all`** so all peer namespaces replicate (patch authors included) without per-node `rad follow`.

### client-node

| Variable | Description |
|----------|-------------|
| `RADICLE_HOME` | Overrides `RAD_HOME` |
| `RAD_HOME` | State directory [default: `/node/radicle`] — must match the volume mount |
| `IDENTITY_SRC` | Secret mount to bootstrap identity [default: `/radicle-identity`] |
| `RAD_ALIAS` | Alias when generating new config [default: `client`] |
| `RAD_HUB_SEED` | `NID@host:port` → `preferredSeeds` + `node.connect` |
| `RAD_EXTERNAL_ADDR` | Advertised dial address (enables inbound P2P when set) |
| `RAD_P2P_LISTEN` | Listen port when `RAD_EXTERNAL_ADDR` set [default: `8776`] |
| `SEED_ENABLE` | `0` (default for client) — do not run as seed |
| `HTTP_ENABLE` | `0` (default for client) — do not run HTTP dashboard |

## Ports

| Port | Service |
|------|---------|
| `8776` | Radicle P2P |
| `8080` | `radicle-httpd` (seed-node only, when `HTTP_ENABLE=1`) |

## Kubernetes

Deploy with the shared Helm chart — see [`deploy/`](deploy/) (`values.yaml` + instructions).

Production (lab): `k8s/clusters/hydra/applications/radicle/seed-node/` and ZeroClaw sidecar in the lab repo.

### Verify seeding (after rollout)

```bash
kubectl -n radicle exec deploy/seed-node -- rad seed
# lab RID should show Policy: allow, Scope: all
```

ZeroClaw patch workflow docs: lab repo `zeroclaw/workspaces/main/shared-context/RADICLE.md`.

## Local run

```bash
docker build -t radicle-node:local .
docker run --rm -it \
  -e MODE=seed-node \
  -e RAD_ALIAS=dev-seed \
  -e RAD_SEEDS='rad:z6MQ7ck2rSh7h4qEgbRYg3ftnrGv' \
  -p 8776:8776 -p 8080:8080 \
  -v radicle-data:/node/radicle \
  radicle-node:local
```
