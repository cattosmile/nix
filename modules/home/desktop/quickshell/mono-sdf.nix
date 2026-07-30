{
  cargo,
  cmake,
  corrosion,
  fetchFromGitHub,
  ninja,
  qt6,
  rustPlatform,
  rustc,
  stdenv,
}:

let
  cxxQtCmake = fetchFromGitHub {
    owner = "KDAB";
    repo = "cxx-qt-cmake";
    rev = "06a121ef560a0b368008ca3de35fb185fe91de21";
    hash = "sha256-1dbLbKSy4Aqaxpv9ws3JN0p6nD/AUEqZR1sTxihcdxw=";
  };
in

stdenv.mkDerivation {
  pname = "quickshell-mono-sdf";
  version = "1.0.0";

  src = ./rice/mono-sdf;

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./rice/mono-sdf/Cargo.lock;
  };

  nativeBuildInputs = [
    cargo
    cmake
    corrosion
    ninja
    rustPlatform.cargoSetupHook
    rustc
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
  ];

  dontWrapQtApps = true;
  strictDeps = true;

  preConfigure = ''
    qtPrefix="$PWD/qt-prefix"
    mkdir -p \
      "$qtPrefix/include" \
      "$qtPrefix/lib" \
      "$qtPrefix/bin" \
      "$qtPrefix/libexec"

    for sourcePrefix in \
      ${qt6.qtbase} \
      ${qt6.qtbase.dev} \
      ${qt6.qtdeclarative} \
      ${qt6.qtdeclarative.dev}; do
      for directory in include lib bin libexec; do
        if [ ! -d "$sourcePrefix/$directory" ]; then
          continue
        fi

        for entry in "$sourcePrefix/$directory"/*; do
          if [ ! -e "$entry" ]; then
            continue
          fi

          destination="$qtPrefix/$directory/$(basename "$entry")"
          if [ ! -e "$destination" ]; then
            ln -s "$entry" "$destination"
          fi
        done
      done
    done

    export MONO_SDF_QT_PREFIX="$qtPrefix"
    export QSB="${qt6.qtshadertools}/bin/qsb"
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCorrosion_DIR=${corrosion}/lib/cmake/Corrosion"
    "-DFETCHCONTENT_SOURCE_DIR_CXXQT=${cxxQtCmake}"
  ];
}
