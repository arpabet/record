// ─────────────────────────────────────────────────────────────────────────────
// MIGRATION IN PROGRESS — this module does NOT build yet. See ../MIGRATION.md.
// Remaining hands-on work before `go build` passes:
//   1. Port main.go + sprintframework usages to the current arpabet builder API
//      (role-based glue.Child(sprint.CoreRole, …); see arpabet/template/main.go).
//   2. raftgrpc — RESOLVED: ported to go.arpabet.com/sprint/raftgrpc (new module in
//      the arpabet/sprint monorepo). Requires publishing a `raftgrpc/v1.1.0` tag there.
//   3. Finish the server-side Map* sub-API (handler + service + raft apply).
//   4. Run `go mod tidy` to regenerate the indirect dependency block.
// ─────────────────────────────────────────────────────────────────────────────

module go.arpabet.com/record/recordmod

go 1.23

require (
	go.arpabet.com/glue v1.5.0
	go.arpabet.com/record/recordpb v0.0.0-00010101000000-000000000000
	go.arpabet.com/sprint/raftapi v1.1.0
	go.arpabet.com/sprint/raftgrpc v1.1.0
	go.arpabet.com/sprint/raftmod v1.1.0
	go.arpabet.com/sprint/raftpb v1.1.0
	go.arpabet.com/sprint/sprint v1.1.0
	go.arpabet.com/sprint/sprintframework v1.1.0
	go.arpabet.com/store v1.1.0

	github.com/golang/protobuf v1.5.2
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.15.2
	github.com/hashicorp/raft v1.3.11
	go.uber.org/zap v1.24.0
	golang.org/x/xerrors v0.0.0-20200804184101-5ec99f83aff1
	google.golang.org/genproto v0.0.0-20230303212802-e74f57abe488
	google.golang.org/grpc v1.53.0
	google.golang.org/protobuf v1.28.1
)

// recordpb is resolved locally within this monorepo (also covered by ../go.work).
replace go.arpabet.com/record/recordpb => ../recordpb
