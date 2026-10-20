{ pkgs, ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts."larry.mooo.info" = let
      dir = pkgs.writeTextFile {
        name = "index.html";
        text = ''
          <head>
           <title>Larry the Cow</title>
           <meta charset="UTF-8"/>
          </head>
          <body>
           <pre>
            Larry loves Gentoo (Linux)

           _______________________
          &lt; Have you mooed today? &gt;
           -----------------------
                  \   ^__^
                   \  (oo)\_______
                      (__)\       )\/\
                          ||----w |
                          ||     ||
           </pre>
          </body>
        '';
        destination = "/srv/index.html";
      };
    in {
      root = "${dir}/srv";
      locations."/" = {
        tryFiles = "/index.html =404";
      };
      locations."= /favicon.ico" = {
        return = 404;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}

