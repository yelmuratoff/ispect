export 'download_native_logs.dart'
    if (dart.library.html) 'download_html_logs.dart'
    if (dart.library.js_interop) 'download_wasm_logs.dart';
