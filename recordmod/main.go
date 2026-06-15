/*
 * Copyright (c) 2022-2023 Zander Schwid & Co. LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */

// ─────────────────────────────────────────────────────────────────────────────
// TODO(arpabet-migration): this file must be ported to the current arpabet
// sprintframework builder API before it compiles. The codeallergy framework this
// was written against (sprint*/v1.0.x) differs substantially from arpabet v1.1.x.
//
// Reference: https://github.com/arpabet/template/blob/main/main.go
//
// Required changes:
//   • app.Application(...).Run(args)  → sprintapp.Application(name, opts…).Run(args)
//   • app.Beans / app.Core / app.Server / app.Client (scanner style)
//                                     → one []interface{} of beans nested with
//                                       glue.Child(sprint.CoreRole, …),
//                                       glue.Child(sprint.ServerRole, …),
//                                       glue.Child(sprint.ControlClientRole, …)
//   • app.DefaultApplicationBeans     → sprintapp.ApplicationBeans
//   • sprintcmd.DefaultCommands       → sprintcmd.ApplicationCommands
//   • sprintcore.CoreScanner(…)       → sprintcore.CoreServices (inside CoreRole child)
//   • sprintcore.BadgerStorageFactory → sprintcore.BadgerStoreFactory
//   • sprintserver.ServerScanner(…)   → sprintserver.GrpcServerScanner(name) + beans
//   • raftgrpc.RaftCommand()          → go.arpabet.com/sprint/raftgrpc.RaftCommand()  (ported module)
//   • raftgrpc.RaftGrpcServer()       → go.arpabet.com/sprint/raftgrpc.RaftGrpcServer() (ported module)
//   • raftmod.Scan                    → raftmod.RaftServices... (slice, not a scanner)
// ─────────────────────────────────────────────────────────────────────────────
package main

import (
	"fmt"
	"go.arpabet.com/glue"
	"go.arpabet.com/record/recordmod/pkg/resources"
	"go.arpabet.com/record/recordmod/pkg/server"
	"go.arpabet.com/record/recordmod/pkg/service"
	"go.arpabet.com/sprint/raftmod"
	"go.arpabet.com/sprint/raftgrpc"
	"github.com/pkg/errors"
	"go.arpabet.com/sprint/sprintframework/sprintapp"
	sprintclient "go.arpabet.com/sprint/sprintframework/sprintclient"
	sprintcmd "go.arpabet.com/sprint/sprintframework/sprintcmd"
	sprintcore "go.arpabet.com/sprint/sprintframework/sprintcore"
	sprintserver "go.arpabet.com/sprint/sprintframework/sprintserver"
	"os"
	"time"
)

var (
	Version string
	Build   string
)

var AppResources = &glue.ResourceSource{
	Name: "resources",
	AssetNames: resources.AssetNames(),
	AssetFiles: resources.AssetFile(),
}

func doMain() (err error) {

	defer func() {
		if r := recover(); r != nil {
			switch v := r.(type) {
			case error:
				err = v
			case string:
				err = errors.New(v)
			default:
				err = errors.Errorf("%v", v)
			}
		}
	}()

	return app.Application("recordbase",
		app.WithVersion(Version),
		app.WithBuild(Build),
		app.Beans(app.DefaultApplicationBeans, AppResources, sprintcmd.DefaultCommands, raftgrpc.RaftCommand()),
		app.Core(sprintcore.CoreScanner(
			sprintcore.BadgerStorageFactory("config-storage"),
			sprintcore.BadgerStorageFactory("record-storage"),
			sprintcore.BadgerStorageFactory("raft-storage"),
			sprintcore.LumberjackFactory(),
			sprintcore.AutoupdateService(),
			service.Scan,
		)),
		app.Server(sprintserver.ServerScanner(
			sprintserver.AuthorizationMiddleware(),
			sprintserver.GrpcServerFactory("control-grpc-server"),
			sprintserver.ControlServer(),
			sprintserver.TlsConfigFactory("tls-config"),
		)),
		app.Client(sprintclient.ControlClientScanner(
			sprintclient.AnyTlsConfigFactory("tls-config"),
		)),
		app.Server(sprintserver.ServerScanner(
			sprintserver.AuthorizationMiddleware(),
			sprintserver.GrpcServerFactory("api-grpc-server"),
			server.APIServer(),
			raftmod.Scan,
			raftgrpc.RaftGrpcServer(),
			sprintserver.HttpServerFactory("api-gateway-server"),
			sprintserver.TlsConfigFactory("tls-config"),
		)),
		app.Client(sprintclient.ClientScanner("api",
			sprintclient.GrpcClientFactory("api-grpc-client"),
			sprintclient.AnyTlsConfigFactory("tls-config"),
		)),
	).Run(os.Args[1:])

}

func main() {

	if err := doMain(); err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	time.Sleep(100 * time.Millisecond)
}
