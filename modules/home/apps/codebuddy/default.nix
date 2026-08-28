{
  config,
  pkgs,
  lib,
  ...
}:

let
  version = "2.141.0";
  codebuddy = pkgs.stdenv.mkDerivation {
    pname = "codebuddy-code";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@tencent-ai/codebuddy-code/-/codebuddy-code-${version}.tgz";
      hash = "sha256-W/vyPi6xjEJzCTsat9u1dZx2CExTiy7gHscsMeScUHY=";
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.autoPatchelfHook
    ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -dm755 "$out/lib/codebuddy-code"
      cp -r . "$out/lib/codebuddy-code"

      install -dm755 "$out/bin"
      for name in codebuddy codebuddy-code cbc; do
        makeWrapper "${lib.getExe pkgs.nodejs_22}" "$out/bin/$name" \
          --add-flags "$out/lib/codebuddy-code/bin/codebuddy"
      done
      makeWrapper "${lib.getExe pkgs.nodejs_22}" "$out/bin/cbc-prewarm" \
        --add-flags "$out/lib/codebuddy-code/bin/cbc-prewarm"

      runHook postInstall
    '';

    meta = with lib; {
      description = "CodeBuddy Code CLI";
      homepage = "https://registry.npmjs.org/@tencent-ai/codebuddy-code";
      mainProgram = "codebuddy";
      platforms = platforms.linux ++ platforms.darwin;
    };
  };

  settings = {
    model = "hy4-preview";
    reasoningEffort = "max";
    autoUpdates = false;
  };

  managedSettings = pkgs.writeText "codebuddy-settings.json" (builtins.toJSON settings);
in

{
  home.packages = [ codebuddy ];
  home.activation.codebuddySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${config.home.homeDirectory}/.codebuddy/settings.json"
    mkdir -p "$(dirname "$settings")"

    if [ ! -s "$settings" ]; then
      install -Dm644 ${managedSettings} "$settings"
    else
      ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$settings" ${managedSettings} > "$settings.tmp" \
        && mv "$settings.tmp" "$settings"
    fi
  '';
}
