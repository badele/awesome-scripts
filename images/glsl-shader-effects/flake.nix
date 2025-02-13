{
  description = "Projet Python avec Nix, venv et pip";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      imageProcessing = pkgs.callPackage ./nix-python-image-processing.nix {
        inherit (pkgs.python311Packages) buildPythonPackage;
        inherit (pkgs) fetchFromGitHub;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs;
          [ (python311.withPackages (ps: with ps; [ imageProcessing ])) ];
      };
    };
}
