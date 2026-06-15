# record

The **Record Service** — a multi-tenant, raft-replicated, indexed record store
(generalization of the now-deprecated `userid` service).

This is a **multi-module monorepo** (one `go.mod` per component, coordinated by
`go.work`), following the same layout as `go.arpabet.com/store` and
`go.arpabet.com/sprint`.

| Module | Path | Role |
|--------|------|------|
| `recordpb`   | `go.arpabet.com/record/recordpb`   | Protobuf + generated gRPC / grpc-gateway / swagger |
| `recordbase` | `go.arpabet.com/record/recordbase` | Go client library |
| `recordmod`  | `go.arpabet.com/record/recordmod`  | Server (sprint app + glue DI + store + raft) |

## Status

- ✅ `recordpb` — builds.
- ✅ `recordbase` — builds & vets clean against arpabet `glue v1.5.0`.
- 🟡 `recordmod` — structurally migrated; needs a framework-API port before it
  builds. See [MIGRATION.md](MIGRATION.md).

## Build

```sh
go build ./recordpb/...      # ok
go build ./recordbase/...    # ok
# recordmod: see MIGRATION.md (framework port + Map API + raftgrpc)
```

## Releasing

All modules release together under one shared version (the arpabet `store` / `sprint`
convention). Tags follow `<module>/vX.Y.Z`; internal `require`s are pinned and the
local-dev `replace … => ../X` directives are stripped at release time.

```sh
./release.sh --dry-run v1.1.0            # preview plan + go.mod changes, change nothing
./release.sh v1.1.0                      # tag recordpb/recordbase/recordmod at v1.1.0 and push
./release.sh v1.1.0 recordbase=v1.1.1    # per-module patch override within the same major
```

