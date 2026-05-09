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

            # PostgreSQL
            postgresql

            # Web automation
            playwright-driver
          ];

          shellHook = ''
            export MIX_HOME=$PWD/.mix
            export HEX_HOME=$PWD/.hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            # Local PostgreSQL setup (no system service required)
            export PGDATA=$PWD/.pgdata
            export PGHOST=$PWD/.pghost
            mkdir -p $PGHOST

            if [ ! -d "$PGDATA" ]; then
              initdb --auth=trust --no-locale --encoding=UTF8
            fi

            if ! pg_ctl status > /dev/null 2>&1; then
              pg_ctl start -l $PGDATA/postgresql.log \
                -o "-k $PGHOST -h localhost"
              echo "PostgreSQL started. Stop with: pg_ctl stop"
            fi

            # Ensure a `postgres` superuser role exists (config/*.exs connects as it).
            # initdb only creates a role matching $USER, so create `postgres` if missing.
            if ! psql -h localhost -U "$USER" -d postgres -tAc \
                 "SELECT 1 FROM pg_roles WHERE rolname='postgres'" | grep -q 1; then
              psql -h localhost -U "$USER" -d postgres -c \
                "CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'postgres';" \
                > /dev/null
              echo "Created 'postgres' superuser role."
            fi

            export ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild"
            export TAILWIND_PATH="${pkgs.tailwindcss_4}/bin/tailwindcss"
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"

            mix local.hex --if-missing --force
            mix local.rebar --if-missing --force
	    fish
          '';
        };
      });
}
