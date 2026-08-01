{
  inputs,
  lib,
  pkgs,
}:

let
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  monoSdf = pkgs.callPackage ./mono-sdf.nix { };
  volumeTockPlayer = pkgs.callPackage ./rice/volume-tock-player/default.nix { };

  config = pkgs.runCommand "quickshell-rice-config" { } ''
    mkdir -p "$out"
    cp ${./rice}/*.qml "$out/"
    cp -r ${./rice}/scripts "$out/scripts"
    cp -r ${./rice}/assets "$out/assets"
    ln -s ${volumeTockPlayer} "$out/.volume-tock-player"
  '';

  start = pkgs.writeShellApplication {
    name = "quickshell-rice";
    runtimeInputs = [ quickshell ];
    text = ''
      export QML_IMPORT_PATH="${monoSdf}/qml''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
      export QML2_IMPORT_PATH="${monoSdf}/qml''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

      exec ${lib.getExe quickshell} \
        --no-duplicate \
        --config rice \
        "$@"
    '';
  };

  reload = pkgs.writeShellApplication {
    name = "quickshell-rice-reload";
    runtimeInputs = [ quickshell ];
    text = ''
      ${lib.getExe quickshell} kill \
        --config rice \
        --any-display \
        >/dev/null 2>&1 || true

      exec ${lib.getExe start} --daemonize
    '';
  };

  ipc = pkgs.writeShellApplication {
    name = "quickshell-rice-ipc";
    runtimeInputs = [ quickshell ];
    text = ''
      exec ${lib.getExe quickshell} ipc \
        --config rice \
        "$@"
    '';
  };
in

{
  inherit
    config
    ipc
    monoSdf
    quickshell
    reload
    start
    volumeTockPlayer
    ;
}
