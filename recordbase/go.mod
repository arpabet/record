module go.arpabet.com/record/recordbase

go 1.25.0

require (
	github.com/grpc-ecosystem/go-grpc-middleware v1.3.0
	github.com/pkg/errors v0.9.1
	go.arpabet.com/glue v1.5.0
	go.arpabet.com/record/recordpb v1.0.3
	go.arpabet.com/sprint/raftpb v1.1.0
	go.uber.org/atomic v1.10.0
	google.golang.org/grpc v1.53.0
	google.golang.org/protobuf v1.36.11
)

require github.com/BurntSushi/toml v1.6.0 // indirect

require (
	github.com/golang/protobuf v1.5.4 // indirect
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.15.2 // indirect
	github.com/kr/pretty v0.3.0 // indirect
	github.com/rogpeppe/go-internal v1.9.0 // indirect
	go.arpabet.com/grpc-multi-resolver v1.3.0
	golang.org/x/net v0.30.0 // indirect
	golang.org/x/sys v0.46.0 // indirect
	golang.org/x/text v0.19.0 // indirect
	google.golang.org/genproto v0.0.0-20230303212802-e74f57abe488 // indirect
	gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace go.arpabet.com/record/recordpb => ../recordpb
