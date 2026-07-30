use cxx_qt_build::{CxxQtBuilder, PluginType, QResource, QResources, QmlModule};
use qt_build_utils::QResourceFile;
use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

fn bake_shader(qsb: &Path, source: &str, output: &Path, batchable: bool) {
    let mut command = Command::new(qsb);
    if batchable {
        command.arg("--batchable");
    }
    let status = command
        .args([
            "--glsl",
            "100es,120,150",
            "--hlsl",
            "50",
            "--msl",
            "12",
            "-o",
        ])
        .arg(output)
        .arg(source)
        .status()
        .unwrap_or_else(|error| panic!("failed to run {}: {error}", qsb.display()));
    assert!(status.success(), "qsb failed for {source}");
    println!("cargo::rerun-if-changed={source}");
}

fn main() {
    let qsb = env::var_os("QSB")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("qsb"));
    let out_dir = PathBuf::from(env::var_os("OUT_DIR").expect("OUT_DIR is missing"));
    let vertex_qsb = out_dir.join("sdf_gpu.vert.qsb");
    let fragment_qsb = out_dir.join("sdf_gpu.frag.qsb");
    bake_shader(&qsb, "shaders/sdf_gpu.vert", &vertex_qsb, true);
    bake_shader(&qsb, "shaders/sdf_gpu.frag", &fragment_qsb, false);

    let shader_resources = QResources::new().resource(
        QResource::new()
            .file(QResourceFile::new(vertex_qsb).alias("qml/sdf_gpu.vert.qsb"))
            .file(QResourceFile::new(fragment_qsb).alias("qml/sdf_gpu.frag.qsb")),
    );

    let builder = CxxQtBuilder::new_qml_module(
        QmlModule::new("Mono.Sdf.Rust")
            .plugin_type(PluginType::Dynamic)
            .qml_files(["qml/AnimatedSdfBlob.qml", "qml/GpuSdfCanvas.qml"]),
    )
    .qt_module("Quick")
    .files(["src/qml_plugin.rs"])
    .qrc_resources(shader_resources);

    unsafe {
        builder
            .cc_builder(|compiler| {
                compiler.define("qt_plugin_instance", "mono_sdf_qt_plugin_instance_internal");
                compiler.define(
                    "qt_plugin_query_metadata_v2",
                    "mono_sdf_qt_plugin_query_metadata_v2_internal",
                );
            })
            .build();
    }
}
