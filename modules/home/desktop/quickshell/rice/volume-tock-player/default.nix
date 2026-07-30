{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation {
  pname = "quickshell-volume-tock-player";
  version = "1.3.4";

  src = ./.;

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.pipewire ];

  strictDeps = true;

  buildPhase = ''
    runHook preBuild

    $CC \
      -std=gnu11 \
      -O2 \
      -Wall \
      -Wextra \
      -Werror \
      volume-tock-player.c \
      -o volume-tock-player \
      $(pkg-config --cflags --libs libpipewire-0.3) \
      -lm

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 volume-tock-player \
      "$out/bin/volume-tock-player"
    install -Dm644 tink.aiff \
      "$out/share/quickshell-volume-tock/tink.aiff"

    runHook postInstall
  '';
}
