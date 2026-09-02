import 'package:flutter/foundation.dart';

export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
