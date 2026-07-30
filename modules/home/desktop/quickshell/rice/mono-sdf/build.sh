#!/usr/bin/env sh
set -eu

module_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cache_root=${XDG_CACHE_HOME:-"$HOME/.cache"}
build_dir=${MONO_SDF_RUST_BUILD_DIR:-"$cache_root/mono-sdf-rust/build"}
cargo_target_dir=${CARGO_TARGET_DIR:-"$cache_root/mono-sdf-rust/cargo-target"}
install_prefix=${MONO_SDF_RUST_PREFIX:-"$HOME/.local/lib/qt6"}
qt_prefix="$cache_root/mono-sdf-rust/qt-prefix"

if ! command -v cargo >/dev/null 2>&1; then
    printf '%s\n' "cargo is missing. On NixOS run:"
    printf '%s\n' "  nix-shell -p rustc cargo cmake ninja stdenv.cc qt6.qtbase qt6.qtdeclarative qt6.qtshadertools --run './build.sh'"
    exit 1
fi

qsb=$(command -v qsb || true)
if [ "$qsb" = "" ]; then
    printf '%s\n' "Qt Shader Tools are missing. On NixOS use qt6.qtshadertools."
    exit 1
fi

real_qmake=$(command -v qmake6 || command -v qmake)
base_prefix=$("$real_qmake" -query QT_INSTALL_PREFIX)
declarative_prefix=
for flag in ${NIX_LDFLAGS:-}; do
    case "$flag" in
        -L*-qtdeclarative-*/lib)
            declarative_prefix=${flag#-L}
            declarative_prefix=${declarative_prefix%/lib}
            ;;
    esac
done

if [ "$declarative_prefix" = "" ]; then
    printf '%s\n' "Qt Quick development files are missing. On NixOS use qt6.qtdeclarative."
    exit 1
fi

mkdir -p "$qt_prefix/include" "$qt_prefix/lib" "$qt_prefix/bin" "$qt_prefix/libexec"
for source_prefix in "$base_prefix" "$declarative_prefix"; do
    for directory in include lib bin libexec; do
        [ -d "$source_prefix/$directory" ] || continue
        for entry in "$source_prefix/$directory"/*; do
            [ -e "$entry" ] || continue
            destination="$qt_prefix/$directory/$(basename "$entry")"
            [ -e "$destination" ] || ln -s "$entry" "$destination"
        done
    done
done

export CARGO_TARGET_DIR="$cargo_target_dir"
export MONO_SDF_QT_PREFIX="$qt_prefix"
export QSB="$qsb"

cmake -E remove_directory "$build_dir/qml"
cmake -S "$module_root" -B "$build_dir" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$install_prefix"

cmake --build "$build_dir" --parallel
cmake -E remove_directory "$install_prefix/qml/Mono/Sdf/Rust"
cmake --install "$build_dir"

printf 'Mono.Sdf.Rust installed in %s/qml/Mono/Sdf/Rust\n' "$install_prefix"
