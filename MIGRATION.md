# record — codeallergy → arpabet migration

Consolidates the three former repos `recordpb`, `recordbase`, `recordbaseserv`
into one multi-module monorepo `go.arpabet.com/record`, mirroring the
`go.arpabet.com/sprint` / `go.arpabet.com/store` layout (per-module `go.mod`,
shared `go.work`). The `userid` product is **deprecated** in favour of this one
(a user is a record in a `users` tenant — see bottom).

## Repo mapping

| Former (codeallergy) | Now (arpabet) |
|---|---|
| `github.com/codeallergy/recordpb`        | `go.arpabet.com/record/recordpb` |
| `github.com/codeallergy/recordbase`      | `go.arpabet.com/record/recordbase` |
| `github.com/codeallergy/recordbaseserv`  | `go.arpabet.com/record/recordmod` |

## Dependency mapping (verified against the live arpabet org)

| codeallergy | arpabet | notes |
|---|---|---|
| `glue` | `go.arpabet.com/glue` | **v1.5.0** (was v1.0.2) |
| `store` + `badgerstore`/`boltstore`/`cachestore` | `go.arpabet.com/store` (+ `…/store/providers/*`) | v1.1.0; providers are separate modules, pulled transitively |
| `sprint` / `sprintframework` / `sprintpb` | `go.arpabet.com/sprint/{sprint,sprintframework,sprintpb}` | v1.1.0 |
| `raftapi` / `raftmod` / `raftpb` | `go.arpabet.com/sprint/{raftapi,raftmod,raftpb}` | v1.1.0 |
| `seal` / `sealmod` | `go.arpabet.com/sprint/{seal,sealmod}` | |
| `base62` / `uuid` / `properties` | `go.arpabet.com/{base62,uuid,properties}` | |
| `raftbadger` | `go.arpabet.com/raft-badger` | note the hyphen |
| `grpc-multi-resolver` | `go.arpabet.com/grpc-multi-resolver` | re-pathed in **v1.3.0** (tags ≤ v1.2.0 still declared the codeallergy path) |
| `raftgrpc` | `go.arpabet.com/sprint/raftgrpc` | ✅ ported (new module in arpabet/sprint, from `github.com/openraft/raftgrpc` — the renamed upstream) — see below |

### Version-tag scheme
arpabet sub-modules in a monorepo are tagged `<module>/vX.Y.Z`
(e.g. `raftpb/v1.1.0`, `sprintframework/v1.1.0`). The codeallergy `v1.0.x` pins
do not exist on arpabet; current line is **v1.1.0** for `sprint/*` and `store`,
**v1.5.0** for `glue`.

## What was done mechanically
- Copied the three repos into `recordpb/`, `recordbase/`, `recordmod/`
  (dropped per-repo `.git` and stale `go.sum`).
- Rewrote all `github.com/codeallergy/*` imports → arpabet paths
  (except `raftgrpc`, which has no arpabet repo — left for the port).
- Rewrote `sprintframework/pkg/<x>` → `sprintframework/sprint<x>` (package layout changed).
- Set per-module `go.mod` paths/versions, added `go.work`, bumped `go 1.23`.

## Build status
| module | status |
|---|---|
| `recordpb`   | ✅ builds (`GOWORK=off go build ./...`) |
| `recordbase` | ✅ builds & `go vet` clean against arpabet glue v1.5.0 |
| `recordmod`  | 🟡 needs the framework port below |

## Remaining work on `recordmod`

### 1. Framework-API port (the big one)
The arpabet `sprintframework` builder changed shape from the codeallergy v1.0.x
this was written against. See the inline `TODO(arpabet-migration)` block in
`recordmod/main.go` and use **`arpabet/template/main.go`** as the reference.
Key deltas:
- `sprintframework/pkg/app|client|cmd|core|server|util` → `…/sprint{app,client,cmd,core,server,utils}`
- `app.Application(...).Run()` → `sprintapp.Application(name, sprintapp.WithBeans(beans)).Run(args)`
  where `beans []interface{}` nests `glue.Child(sprint.CoreRole, …)`,
  `glue.Child(sprint.ServerRole, …)`, `glue.Child(sprint.ControlClientRole, …)`.
- `sprintcore.BadgerStorageFactory` → `sprintcore.BadgerStoreFactory`.
- `sprintframework/sprintutils.FindGatewayHandler` (used in `pkg/server/grpc_api_server.go`) — verify signature.

### 2. raftgrpc — ✅ RESOLVED
`main.go` uses `raftgrpc.RaftCommand()` and `raftgrpc.RaftGrpcServer()`.

Investigation: `github.com/codeallergy/raftgrpc` was **renamed, not deleted** — its
live home is `github.com/openraft/raftgrpc` (same author, up to v1.2.2 vs codeallergy's
v1.1.1; both gone from public GitHub but cached on `goproxy.cn`). It can't be required
directly: it belongs to a *third* parallel ecosystem (`github.com/openraft/raftapi`,
`github.com/sprintframework/sprint`, `github.com/keyvalstore/store`) incompatible with the
`go.arpabet.com/*` types recordmod uses.

The arpabet refactor split the old raftgrpc in two: the node-to-node consensus transport
moved into `raftmod` (TCP stream layer), but the **raft management gRPC service** — the
`raftpb.RaftService` impl (`Bootstrap/Join/GetConfiguration/ApplyCommand/Recover`) and the
`raft` CLI command — was only *declared* (`raftapi.RaftGrpcServer` interface + the `raftpb`
proto) and **never implemented** in arpabet. That implementation is the genuinely missing
piece.

Fix: ported the 4 source files from `openraft/raftgrpc` into a new arpabet module
**`go.arpabet.com/sprint/raftgrpc`** (`raft_grpc_server.go`, `raft_api_server.go`,
`utils.go`, `raft_cmd.go`) — purely import re-pathing (`openraft/raftapi`→`sprint/raftapi`,
`openraft/raftpb`→`sprint/raftpb`, `sprintframework/sprint`→`sprint/sprint`,
`codeallergy/glue`→`arpabet/glue`) plus one fixup (`glue.Context`→`glue.Container`).
Builds clean against arpabet glue v1.5.0 / sprint v1.1.0.

**Action still required:** commit + tag `raftgrpc/v1.1.0` in the arpabet/sprint monorepo
so recordmod (a separate repo) can pull `go.arpabet.com/sprint/raftgrpc v1.1.0` from the
proxy. Until then, add a temporary `replace go.arpabet.com/sprint/raftgrpc => <path>` to
recordmod/go.mod for local builds. main.go already imports the new path and drops the
codeallergy require; in the builder port, wire `raftgrpc.RaftGrpcServer()` into the API
`ServerRole` next to `raftmod.RaftServices...`, and `raftgrpc.RaftCommand()` into the
command beans (the serf CLI is the separate `raftcmd.RaftCommands...`).

### 3. Finish the Map* server sub-API (pre-existing gap, unrelated to arpabet)
`recordpb` defines and `recordbase` implements `MapGet/MapPut/MapRemove/MapRange`,
but the **server never did**. To complete:
- add the 4 methods to `pkg/api/services.go` (`api.RecordService` interface);
- implement them in `pkg/service/record_service.go`;
- add `MAP_PUT` / `MAP_REMOVE` cases to the raft `Apply` switch in `pkg/service/raft_service.go`;
- add handlers in `pkg/server/record_api_service.go`.

### 4. Cosmetic
In `recordmod/pkg/server/*`, the injected field is still named `UserService`
(typed `api.RecordService`) — copy-paste residue from userid. Rename → `RecordService`.

### 5. Finalize deps
After the port: `cd recordmod && go mod tidy` to regenerate the indirect block,
then `go build ./...`.

## userid deprecation
`userid` was the earlier prototype of this same engine. `record` is a strict
generalization:

| userid | record |
|---|---|
| `user_id` | `primary_key` (within a `tenant`) |
| single implicit tenant | `tenant` (multi-tenant) |
| `AttributeEntity` | `AttributeEntry` (+ `tags`, `columns`) |
| `FileEntity` | `FileEntry` |
| `Range` / `Capacity` | `KeyRange` / `KeyCapacity` |
| unique-attribute lookup | `Lookup BY_ATTRIBUTE` |
| `Delete` with `keep_attributes` (selective PII TTL) | `Delete` — **port this semantic if needed** |
| — | Map sub-API, per-tenant counts |

Model users as the `users` tenant. The only userid-only behaviour to carry over
is selective-retention delete (`keep_attributes`). The `userid*` repos should be
archived with a pointer here.
