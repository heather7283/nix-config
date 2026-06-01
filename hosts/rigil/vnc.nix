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
    browser = "${pkgs.ungoogled-chromium}/bin/chromium";
    terminal = "${pkgs.foot}/bin/foot";
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
      RestartSec = 5;
      ExecStart = with pkgs; "${labwc}/bin/labwc -C ${menu-xml}/labwc-config";
      Environment = [
        "WLR_BACKENDS=headless"
        "WLR_LIBINPUT_NO_DEVICES=1"
      ];
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
      RestartSec = 5;
      ExecStart = with pkgs; "${wayvnc}/bin/wayvnc -C ${wayvnc-config}";
      Environment = [
        "WAYLAND_DISPLAY=wayland-0" # hack
      ];
    };
  };

  systemd.user.services.vnc-swaybg = let
    cat = pkgs.fetchurl {
      url =
        "https://publicdomainpictures.net/pictures/140000/velka/cat-in-the-grass-1449361188Hqe.jpg";
      hash = "sha256-ODhB2DtLy7nUvskvHhXHiq28j2WOSnpEl4tANw337bc=";
    };
  in {
    wantedBy = [ "default.target" ];
    bindsTo = [ "vnc-compositor.service" ];
    after = [ "vnc-compositor.service" ];
    unitConfig.ConditionUser = "vnc";
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      ExecStart = with pkgs; "${swaybg}/bin/swaybg -i ${cat}";
      Environment = [
        "WAYLAND_DISPLAY=wayland-0" # hack
      ];
    };
  };

  systemd.services.vnc-netns-proxy = let
    tun2socks-config = pkgs.writers.writeYAML "vnc-tun2socks-config.yaml" {
      tunnel = {
        name = tun-name;
        mtu = 8500;
      };
      socks5 = {
        address = "127.0.0.1";
        port = 10808;
        udp = "udp";
      };
    };
    script = with pkgs; writeShellApplication {
      name = "vnc-netns-proxy.sh";
      runtimeInputs = [ coreutils iproute2 hev-socks5-tunnel ];
      text = ''
        netns="${netns-name}"
        tun="${tun-name}"
        tunip="${tun-ip}"

        # create netns itself
        ip netns add "$netns"
        # bring up lo in netns
        ip -n "$netns" link set lo up

        # create tun device outside of netns
        ip tuntap add dev "$tun" mode tun

        # let tun2socks open the tun device...
        hev-socks5-tunnel ${tun2socks-config} &

        # ..and wait for it to bring it up
        attempts=0
        while ! ip link show "$tun" | grep -qFe 'state UP'; do
            attempts=$(( attempts + 1 ))
            if [ "$attempts" -gt 50 ]; then
                echo "tun2socks didn't bring tun interface up"
                exit 1
            fi
            sleep 0.1
        done

        # now move the tun into netns and set up routing
        ip link set "$tun" netns "$netns"
        ip -n "$netns" link set "$tun" up
        ip -n "$netns" addr add "$tunip" dev "$tun"
        ip -n "$netns" route add default dev "$tun"

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
      Type = "simple";
      ExecStart = "${script}/bin/vnc-netns-proxy.sh";
      ExecStopPost = "${cleanup-script}/bin/vnc-netns-proxy-cleanup.sh";
      Restart = "on-failure";
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
    };
  };
}

