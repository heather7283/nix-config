{ pkgs, lib, ... }:

{
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
}

