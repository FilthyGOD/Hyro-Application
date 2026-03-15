import 'dart:io';

void main() {
  final bytes = File('assets/mascot/jairo19.riv').readAsBytesSync();
  final sb = StringBuffer();
  for (final b in bytes) {
    if (b >= 32 && b <= 126) {
      sb.writeCharCode(b);
    } else {
      if (sb.length > 3) {
        print(sb.toString());
      }
      sb.clear();
    }
  }
}
