use core::ffi::c_void;
use core::pin::Pin;

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!(<QtQuick/QQuickItem>);
        type QQuickItem;
    }

    extern "RustQt" {
        #[qobject]
        #[base = QQuickItem]
        #[qml_element]
        #[qproperty(f64, radius)]
        type SdfBlob = super::SdfBlobRust;

        #[qobject]
        #[base = QQuickItem]
        #[qml_element]
        #[qproperty(f64, half_width, cxx_name = "halfWidth")]
        #[qproperty(f64, half_height, cxx_name = "halfHeight")]
        #[qproperty(f64, corner_radius, cxx_name = "cornerRadius")]
        #[qproperty(f64, corner_smoothing, cxx_name = "cornerSmoothing")]
        type SdfRoundRect = super::SdfRoundRectRust;
    }

    impl cxx_qt::Constructor<()> for SdfBlob {}
    impl cxx_qt::Constructor<()> for SdfRoundRect {}
}

pub struct SdfBlobRust {
    radius: f64,
}

impl Default for SdfBlobRust {
    fn default() -> Self {
        Self { radius: 60.0 }
    }
}

pub struct SdfRoundRectRust {
    half_width: f64,
    half_height: f64,
    corner_radius: f64,
    corner_smoothing: f64,
}

impl Default for SdfRoundRectRust {
    fn default() -> Self {
        Self {
            half_width: 40.0,
            half_height: 20.0,
            corner_radius: 35.0,
            corner_smoothing: 0.25,
        }
    }
}

impl cxx_qt::Initialize for qobject::SdfBlob {
    fn initialize(self: Pin<&mut Self>) {}
}

impl cxx_qt::Initialize for qobject::SdfRoundRect {
    fn initialize(self: Pin<&mut Self>) {}
}

#[repr(C)]
struct QPluginMetaData {
    data: *const c_void,
    size: usize,
}

unsafe extern "C" {
    fn mono_sdf_qt_plugin_instance_internal() -> *mut c_void;
    fn mono_sdf_qt_plugin_query_metadata_v2_internal() -> QPluginMetaData;
}

#[no_mangle]
unsafe extern "C" fn qt_plugin_instance() -> *mut c_void {
    mono_sdf_qt_plugin_instance_internal()
}

#[no_mangle]
unsafe extern "C" fn qt_plugin_query_metadata_v2() -> QPluginMetaData {
    mono_sdf_qt_plugin_query_metadata_v2_internal()
}
