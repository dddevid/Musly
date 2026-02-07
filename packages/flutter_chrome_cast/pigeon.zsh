flutter pub run pigeon \
  --input pigeons/google_cast/google_cast_context.dart \
  --dart_out lib/google_cast_context.dart \
  --objc_header_out ios/Classes/google_cast_context.h \
  --objc_source_out ios/Classes/google_cast_context.m \
  --experimental_swift_out ios/Classes/GoogleCastContext.swift \
  --java_out android/src/main/java/com/example/google_cast.java \
  --java_package "com.felnanuke.google_cast"