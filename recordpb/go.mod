module go.arpabet.com/record/recordpb

go 1.25.8

require (
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.29.0
	google.golang.org/genproto/googleapis/api v0.0.0-20260622175928-b703f567277d
	google.golang.org/grpc v1.81.1
	google.golang.org/protobuf v1.36.11
)

require (
	go.opentelemetry.io/otel v1.44.0 // indirect
	go.opentelemetry.io/otel/sdk/metric v1.44.0 // indirect
	golang.org/x/net v0.56.0 // indirect
	golang.org/x/sys v0.46.0 // indirect
	golang.org/x/text v0.38.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260622175928-b703f567277d // indirect
)

// Pin the monolithic genproto to its post-split version so its (now-removed)
// googleapis/api and googleapis/rpc packages don't clash with the split modules
// that grpc v1.81 / grpc-gateway v2.29 require. Older deps (e.g. raftpb) still
// request a pre-split genproto, which would otherwise reintroduce the ambiguity.
replace google.golang.org/genproto => google.golang.org/genproto v0.0.0-20260622175928-b703f567277d
