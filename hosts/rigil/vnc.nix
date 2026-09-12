{ pkgs, lib, config, ... }:

let
  netns-name = "vnc";
  tun-name = "vnc-tun";
  tun-ip = "172.16.0.1";
in {
  users.users.vnc = {
    isNormalUser = true;
    linger = true;
    uid = 1001;
  };

  systemd.user.services.vnc-compositor = let
    browser = lib.getExe pkgs.firefox;
    terminal = lib.getExe pkgs.foot;
    menu-xml = pkgs.writeTextDir "labwc-config/menu.xml" ''
      <?xml version="1.0" ?>
      <openbox_menu>
        <menu id="root-menu" label="">
          <item label="Web browser"><action name="Execute" command="${browser}"/></item>
          <item label="Terminal"><action name="Execute" command="${terminal}"/></item>
          <item label="Reconfigure"><action name="Reconfigure"/></item>
        </menu>
      </openbox_menu>
    '';
  in {
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "vnc";
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = with pkgs; "${labwc}/bin/labwc -C ${menu-xml}/labwc-config";
      Environment = [ "WLR_BACKENDS=headless" "WLR_LIBINPUT_NO_DEVICES=1" ];
    };
  };

  systemd.user.services.vnc-wayvnc = let
    wayvnc-config = pkgs.writeText "wayvnc-config" ''
      address=127.0.0.1
      port=5900
      enable_auth=true
      username=vnc
      password=p455w0rd
      relax_encryption=true
    '';
  in {
    wantedBy = [ "default.target" ];
    bindsTo = [ "vnc-compositor.service" ];
    after = [ "vnc-compositor.service" ];
    unitConfig.ConditionUser = "vnc";
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc -C ${wayvnc-config}";
      Environment = [ "WAYLAND_DISPLAY=wayland-0" ]; # hack
    };
  };

  # TODO: I love the cat but publicdomainpictures.net returns 403 in gh actions
  #systemd.user.services.vnc-swaybg = let
  #  cat = pkgs.fetchurl {
  #    url =
  #      "https://publicdomainpictures.net/pictures/140000/velka/cat-in-the-grass-1449361188Hqe.jpg";
  #    hash = "sha256-ODhB2DtLy7nUvskvHhXHiq28j2WOSnpEl4tANw337bc=";
  #  };
  #in {
  #  wantedBy = [ "default.target" ];
  #  bindsTo = [ "vnc-compositor.service" ];
  #  after = [ "vnc-compositor.service" ];
  #  unitConfig.ConditionUser = "vnc";
  #  serviceConfig = {
  #    Type = "simple";
  #    Restart = "always";
  #    ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${cat}";
  #    Environment = [ "WAYLAND_DISPLAY=wayland-0" ]; # hack
  #  };
  #};

  systemd.services.vnc-netns-proxy = let
    tun2socks-config = pkgs.writers.writeYAML "vnc-tun2socks-config.yaml" {
      tunnel.name = tun-name;
      socks5 = {
        address = "127.0.0.1";
        port = 10888;
        udp = "udp";
      };
    };
    script = with pkgs; writeShellApplication {
      name = "vnc-netns-proxy.sh";
      runtimeInputs = [ coreutils iproute2 hev-socks5-tunnel systemd ];
      text = ''
        # create tun device in the root netns
        ip tuntap add dev "${tun-name}" mode tun

        # let tun2socks open the tun device...
        hev-socks5-tunnel "${tun2socks-config}" &
        # ..and wait for it to get brought up
        attempts=0
        while ! ip link show "${tun-name}" | grep -qFe 'state UP'; do
            attempts=$(( attempts + 1 ))
            if [ "$attempts" -gt 30 ]; then
                echo "tun2socks didn't bring tun interface up"
                exit 1
            fi
            sleep 0.1
        done

        # now create netns, move tun iface there and set up routing
        ip netns add "${netns-name}"
        ip link set "${tun-name}" netns "${netns-name}"
        ip -n "${netns-name}" link set lo up
        ip -n "${netns-name}" link set "${tun-name}" up
        ip -n "${netns-name}" addr add "${tun-ip}" dev "${tun-name}"
        ip -n "${netns-name}" route add default dev "${tun-name}"

        # notify systemd that we finished initialisation
        systemd-notify --ready

        wait
      '';
    };
    cleanup-script = with pkgs; writeShellApplication {
      name = "vnc-netns-proxy-cleanup.sh";
      runtimeInputs = [ iproute2 ];
      text = ''
        ip link delete "${tun-name}" || true
        ip netns delete "${netns-name}" || true
      '';
    };
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${script}/bin/vnc-netns-proxy.sh";
      ExecStopPost = "${cleanup-script}/bin/vnc-netns-proxy-cleanup.sh";
      Restart = "on-failure";
    };
  };

  systemd.services.vnc-netns-forward = {
    wantedBy = [ "multi-user.target" ];
    bindsTo = [ "vnc-netns-proxy.service" "wireguard-wg0.target" ];
    after = [ "vnc-netns-proxy.service" "wireguard-wg0.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.socat}/bin/socat"
        "TCP4-LISTEN:5900,fork"
        "TCP4-CONNECT:127.0.0.1:5900,netns=vnc"
      ];
    };
  };

  systemd.services."user@${builtins.toString config.users.users.vnc.uid}" = {
    overrideStrategy = "asDropin";
    bindsTo = [ "vnc-netns-proxy.service" ];
    after = [ "vnc-netns-proxy.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${netns-name}";
      BindReadOnlyPaths = let
        # this is only to trick routing, it will be intercepted by xray anyway
        resolv-conf = pkgs.writeText "vnc-resolv.conf" "nameserver 1.1.1.1";
      in
        "${resolv-conf}:/etc/resolv.conf"
      ;
      # give this user a very low priority (browser is very CPU heavy)
      CPUSchedulingPolicy = "idle";
    };
  };
}

