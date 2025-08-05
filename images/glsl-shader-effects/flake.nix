{
  description = "Projet Python avec Nix, venv et pip";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      imageProcessing = pkgs.callPackage ./nix-python-image-processing.nix {
        inherit (pkgs.python311Packages) buildPythonPackage;
        inherit (pkgs) fetchFromGitHub;
      };

      glsl-shader-effects = pkgs.stdenv.mkDerivation {
        pname = "glsl-shader-effects";
        version = "1.0.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [ makeWrapper ];

        buildInputs = with pkgs; [
          bash
          (python311.withPackages (ps: with ps; [ imageProcessing ]))
        ];

        installPhase = ''
          mkdir -p $out/bin

          cp glsl-shader-effects.py $out/bin/

          chmod +x $out/bin/glsl-shader-effects.py
        '';

        meta = {
          description = "GLSL shader effects with Python image processing";
          maintainers = [ ];
        };
      };
    in
    {
      packages.${system}.default = glsl-shader-effects;

      # nix run
      apps.${system}.default = {
        type = "app";
        program = "${glsl-shader-effects}/bin/glsl-shader-effects.py";
      };

      # nix develop
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (python311.withPackages (ps: with ps; [ imageProcessing ]))
        ];
      };
    };
}
