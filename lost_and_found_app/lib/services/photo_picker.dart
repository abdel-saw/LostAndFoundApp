// The current client is Web-only.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class SelectedPhoto {
  final Uint8List bytes;
  final String contentType;
  const SelectedPhoto(this.bytes, this.contentType);
}

Future<SelectedPhoto?> pickPhoto() async {
  final input = html.FileUploadInputElement()
    ..id = 'report-photo-input'
    ..accept = 'image/jpeg,image/png,image/webp'
    ..style.display = 'none';
  html.document.body!.append(input);
  final completed = Completer<void>();
  void finish(html.Event event) {
    if (!completed.isCompleted) completed.complete();
  }
  input.addEventListener('change', finish);
  input.addEventListener('cancel', finish);
  try {
    input.click();
    await completed.future;
    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files.single;
    if (!['image/jpeg', 'image/png', 'image/webp'].contains(file.type)) {
      throw const FormatException('Choose a JPEG, PNG or WebP photo.');
    }
    if (file.size > 5 * 1024 * 1024) {
      throw const FormatException('The photo must be 5 MiB or smaller.');
    }
    final reader = html.FileReader();
    final loaded = reader.onLoad.first;
    reader.readAsArrayBuffer(file);
    await loaded;
    if (reader.error != null) throw const FormatException('Could not read the photo.');
    return SelectedPhoto(reader.result as Uint8List, file.type);
  } finally {
    input.removeEventListener('change', finish);
    input.removeEventListener('cancel', finish);
    input.remove();
  }
}
