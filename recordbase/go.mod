module go.arpabet.com/record/recordbase

go 1.25.8

require (
	github.com/grpc-ecosystem/go-grpc-middleware v1.4.0
	go.arpabet.com/glue v1.5.1
	go.arpabet.com/record/recordpb v1.0.3
	go.arpabet.com/sprint/raftpb v1.2.0
	go.uber.org/atomic v1.11.0
	golang.org/x/xerrors v0.0.0-20240903120638-7835f813f4da
	google.golang.org/grpc v1.81.1
	google.golang.org/protobuf v1.36.11
)

require (
	github.com/BurntSushi/toml v1.6.0 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20260622175928-b703f567277d // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260622175928-b703f567277d // indirect
)

require (
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.29.0 // indirect
	go.arpabet.com/grpc-multi-resolver v1.3.1
	golang.org/x/net v0.56.0 // indirect
	golang.org/x/sys v0.46.0 // indirect
	golang.org/x/text v0.38.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace go.arpabet.com/record/recordpb => ../recordpb

// Pin the monolithic genproto to its post-split version so its (now-removed)
// googleapis/api and googleapis/rpc packages don't clash with the split modules
// that grpc v1.81 / grpc-gateway v2.29 require. Older deps (e.g. raftpb) still
// request a pre-split genproto, which would otherwise reintroduce the ambiguity.
replace google.golang.org/genproto => google.golang.org/genproto v0.0.0-20260622175928-b703f567277d
