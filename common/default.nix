{ config, lib, pkgs, nix-secrets, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Select internationalisation properties.
  i18n.defaultLocale = "C.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    heather = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW47TMs+tXJEl6bY0FGd54kf5DM/g21mfA5tij5JNJc heather@FA506IH"
      ];
      shell = pkgs.zsh;
      packages = with pkgs; [ fzf btop ];
    };
  };

  programs.zsh = {
    enable = true;
    shellInit = lib.concatLines [
      "export ZDOTDIR=\"$HOME\"/.config/zsh/" # zshenv
    ];
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure = {
      customRC = ''
        set modeline
        set expandtab
        set tabstop=4
        set shiftwidth=4
        set number
        set autochdir

        lua << EOF
        vim.api.nvim_set_hl(0, "TrailingWhitespace", { bg = "red", ctermbg = "red" })
        vim.api.nvim_create_autocmd({"BufWinEnter", "InsertLeave"}, {
          pattern = "*",
          callback = function()
            if vim.bo.buftype == "" then
              vim.fn.clearmatches()
              vim.fn.matchadd('TrailingWhitespace', [[\v\s+$|^\s+$]])
            end
          end
        })

        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "html", "xml", "lua", "css", "nix" },
          callback = function()
            vim.bo.tabstop = 2      -- Set tab width to 2 spaces
            vim.bo.shiftwidth = 2   -- Set indentation width to 2 spaces
            vim.bo.expandtab = true -- Convert tabs to spaces
          end
        })
        EOF
      '';
    };
  };
  environment.systemPackages = with pkgs; [
    git
    age
    sops
    curl
    rsync
    python3
  ];

  # https://github.com/systemd/systemd/issues/5356
  systemd.settings.Manager = {
      StatusUnitFormat = "combined";
  };

  environment.etc."inputrc".text = "set editing-mode vi";

  system.stateVersion = "25.11"; # Do not change
}

