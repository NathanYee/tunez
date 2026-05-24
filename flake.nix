{
  description = "Ash tunez";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            elixir_1_19
            erlang
            hex
            rebar3

            # Phoenix assets
            nodejs
            esbuild
            tailwindcss_4

            # For file watching (Phoenix live reload)
            inotify-tools

            # PostgreSQL client (server runs as a system service)
            postgresql

            # Web automation
            playwright-driver
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.mix
            export HEX_HOME=$PWD/.hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            export ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild"
            export TAILWIND_PATH="${pkgs.tailwindcss_4}/bin/tailwindcss"
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"

            if ! ls "$MIX_HOME"/archives/hex-* >/dev/null 2>&1; then
              mix local.hex --if-missing --force
            fi

            if [ ! -x "$MIX_HOME/elixir/1-19-otp-28/rebar3" ]; then
              mix local.rebar --if-missing --force
            fi
          '';
        };
      });
}
