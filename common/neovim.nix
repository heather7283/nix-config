{ config, lib, pkgs, ... }:

{
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
        set ignorecase smartcase

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
}

