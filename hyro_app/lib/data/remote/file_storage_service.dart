// Barrel file: exports the IO implementation on native, stub on web.
export 'file_storage_service_io.dart'
    if (dart.library.html) 'file_storage_service_web.dart';
