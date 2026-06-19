// This file now acts as a conditional exporter
export 'ai_helper_stub.dart'
    if (dart.library.io) 'ai_helper_mobile.dart'
    if (dart.library.html) 'ai_helper_web.dart';
