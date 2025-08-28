{
  description = "tones generator";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      tones-generator = pkgs.stdenv.mkDerivation {
        pname = "tones-generator";
        version = "1.0.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [ makeWrapper ];

        buildInputs = with pkgs; [
          imagemagick
        ];

        installPhase = ''
          mkdir -p $out/bin

          cp tones-generator.sh $out/bin/

          chmod +x $out/bin/tones-generator.sh
        '';

        meta = {
          description = "tones-generator";
          maintainers = [ ];
        };
      };
    in
    {
      packages.${system}.default = tones-generator;

      # nix run
      apps.${system}.default = {
        type = "app";
        program = "${tones-generator}/bin/tones-generator.sh";
      };

      # nix develop
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          imagemagick
        ];
      };
    };
}
