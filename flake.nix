{
  description = "iced_comet";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      fenix,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ fenix.overlays.default ];
        };
        ld_library_path = pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            expat
            fontconfig
            freetype
            freetype.dev
            libGL
            pkg-config
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            wayland
            libxkbcommon
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pkgs.fenix.stable.toolchain
            pkg-config
            openssl
            openssl.dev
          ];

          LD_LIBRARY_PATH = ld_library_path;
        };

        packages.default =
          let
            manifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
          in
          pkgs.rustPlatform.buildRustPackage {
            pname = manifest.package.name;
            name = manifest.package.name;
            version = manifest.package.version;

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
              allowBuiltinFetchGit = true;
            };

            nativeBuildInputs = with pkgs; [
              makeWrapper
              openssl.dev
              openssl
              pkg-config
            ];

            BuildInputs = with pkgs; [
              openssl
            ];

            preBuild = ''
              export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig
            '';

            postInstall = ''
              wrapProgram $out/bin/${manifest.package.name} --set LD_LIBRARY_PATH ${ld_library_path}
            '';

            meta = {
              description = "Your favorite tool for inspecting and debugging iced applications. Built with iced!";
              homepage = "https://github.com/iced-rs/comet";
              license = pkgs.lib.licenses.mit;
            };
          };
      }
    );
}
