cmake_minimum_required(VERSION 3.24)
project(mono_sdf_rust VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Gui Qml Quick QmlImportScanner)

get_target_property(MONO_SDF_REAL_QMAKE Qt::qmake IMPORTED_LOCATION)
set(MONO_SDF_QT_PREFIX "$ENV{MONO_SDF_QT_PREFIX}")
if(MONO_SDF_QT_PREFIX STREQUAL "")
    message(FATAL_ERROR "MONO_SDF_QT_PREFIX is missing; invoke the build through build.sh")
endif()

set(MONO_SDF_QMAKE_PROXY "${CMAKE_BINARY_DIR}/mono-sdf-qmake")
file(WRITE "${MONO_SDF_QMAKE_PROXY}"
"#!/bin/sh
if [ \"$1\" = \"-query\" ] && [ \"$#\" -eq 2 ]; then
    case \"$2\" in
        QT_INSTALL_PREFIX) printf '%s\\n' '${MONO_SDF_QT_PREFIX}'; exit 0 ;;
        QT_INSTALL_HEADERS) printf '%s\\n' '${MONO_SDF_QT_PREFIX}/include'; exit 0 ;;
        QT_INSTALL_LIBS) printf '%s\\n' '${MONO_SDF_QT_PREFIX}/lib'; exit 0 ;;
        QT_INSTALL_BINS|QT_HOST_BINS) printf '%s\\n' '${MONO_SDF_QT_PREFIX}/bin'; exit 0 ;;
        QT_INSTALL_LIBEXECS|QT_HOST_LIBEXECS) printf '%s\\n' '${MONO_SDF_QT_PREFIX}/libexec'; exit 0 ;;
    esac
fi
exec '${MONO_SDF_REAL_QMAKE}' \"$@\"
")
file(CHMOD "${MONO_SDF_QMAKE_PROXY}"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

include(FetchContent)
find_package(CxxQt QUIET)
if(NOT CxxQt_FOUND)
    FetchContent_Declare(
        CxxQt
        GIT_REPOSITORY https://github.com/KDAB/cxx-qt-cmake.git
        GIT_TAG 0.9.1
    )
    FetchContent_MakeAvailable(CxxQt)
endif()

cxx_qt_import_crate(
    MANIFEST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Cargo.toml"
    CRATES mono-sdf-rust
    LOCKED
    QMAKE "${MONO_SDF_QMAKE_PROXY}"
    QT_MODULES Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
)

set(MONO_SDF_RUST_QML_ROOT "${CMAKE_BINARY_DIR}/qml")
set(MONO_SDF_RUST_MODULE_DIR "${MONO_SDF_RUST_QML_ROOT}/Mono/Sdf/Rust")
cxx_qt_import_qml_module(MonoSdfRustQmlModule
    URI "Mono.Sdf.Rust"
    SOURCE_CRATE mono_sdf_rust
    OUTPUT_DIR "${MONO_SDF_RUST_QML_ROOT}"
)

set(MONO_SDF_RUST_INSTALL_DIR "qml/Mono/Sdf/Rust" CACHE STRING
    "QML module install path relative to CMAKE_INSTALL_PREFIX")

install(
    DIRECTORY "${MONO_SDF_RUST_MODULE_DIR}/"
    DESTINATION "${MONO_SDF_RUST_INSTALL_DIR}"
)
