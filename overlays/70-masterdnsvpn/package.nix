{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "masterdnsvpn";
  version = "2026.10.26.100415-5f83ee9";

  src = fetchFromGitHub {
    owner = "masterking32";
    repo = "MasterDnsVPN";
    rev = "v${version}";
    hash = "sha256-WuONqlZDc8nJkef06X77Zunswj8pQ3lXlsPmsqYNoIo=";
  };
  vendorHash = "sha256-X0TpheIBmhT0tbNf5FEnUW1faIgY2oTxMfoRUDTjn34=";

  subPackages = [
    "cmd/client"
    "cmd/server"
  ];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X masterdnsvpn-go/internal/version.BuildVersion=${version}"
  ];

  doCheck = true;

  postInstall = ''
    mv $out/bin/client $out/bin/masterdnsvpn-client
    mv $out/bin/server $out/bin/masterdnsvpn-server
  '';
}

