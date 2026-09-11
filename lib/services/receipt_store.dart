import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Where a receipt photo comes from.
enum ReceiptSource { camera, gallery }

/// Keeps receipt photos beside the ledger without putting them in it.
///
/// Every other piece of Sobra state is one JSON string in `shared_preferences`,
/// re-encoded on each save and copied whole into a backup key. A photo cannot
/// live there: a handful of them would make every expense save rewrite several
/// megabytes. So the bytes go to `<documents>/receipts/` and the ledger keeps
/// only the file name.
///
/// The cost of that split is that deletion is no longer a single write.
/// [SobraStore.deleteExpense] is undoable, so a photo must outlive the row that
/// pointed at it — [sweepOrphans] collects the leftovers at launch instead,
/// once the undo window is provably gone.
abstract class ReceiptStore {
  /// Whether this build can take and keep photos at all.
  ///
  /// False on web, which has no writable documents directory. Callers hide the
  /// attach control rather than offering a button that cannot work.
  bool get isSupported;

  /// Picks a photo and copies it in, returning its file name.
  ///
  /// Null means the user backed out of the picker, which is not a failure and
  /// must not be reported as one. A genuine problem throws.
  Future<String?> capture(ReceiptSource source);

  /// The file a stored name refers to, or null if it is gone.
  ///
  /// A missing file is normal rather than exceptional: the phone can clear an
  /// app's container, and a backup restored onto a new device brings the
  /// ledger without the photos.
  File? fileFor(String name);

  /// Deletes the photo with this name, if it is still there.
  Future<void> remove(String name);

  /// Deletes every stored photo no longer named by an expense.
  ///
  /// Covers both halves of the leak: a photo attached in the register screen
  /// and then abandoned without saving, and one whose expense was deleted for
  /// good. Runs at launch, where no undo is pending.
  Future<int> sweepOrphans(Iterable<String> referenced);

  /// The implementation this platform can actually run.
  static ReceiptStore forPlatform() =>
      kIsWeb ? const UnsupportedReceiptStore() : FileReceiptStore();
}

/// The stand-in for platforms with no place to put a file.
class UnsupportedReceiptStore implements ReceiptStore {
  const UnsupportedReceiptStore();

  @override
  bool get isSupported => false;

  @override
  Future<String?> capture(ReceiptSource source) async => null;

  @override
  File? fileFor(String name) => null;

  @override
  Future<void> remove(String name) async {}

  @override
  Future<int> sweepOrphans(Iterable<String> referenced) async => 0;
}

class FileReceiptStore implements ReceiptStore {
  FileReceiptStore({ImagePicker? picker, Directory? directory})
    : _picker = picker ?? ImagePicker(),
      _directory = directory;

  /// The long edge every stored photo is resized to.
  ///
  /// A receipt only has to stay readable on a phone screen. The picker does
  /// the resize and the JPEG re-encode natively, before the file ever reaches
  /// the documents directory: a 12 MP camera frame lands at 1600 px on its
  /// long edge. Measured on a simulator, a dense photograph comes out around
  /// 450 KB and a receipt — mostly white paper — well under that.
  static const double _maxEdge = 1600;
  static const int _quality = 78;
  static const String _folder = 'receipts';

  final ImagePicker _picker;
  Directory? _directory;
  int _sequence = 0;

  Future<Directory> _receiptsDirectory() async {
    final existing = _directory;
    if (existing != null) return existing;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_folder');
    if (!directory.existsSync()) await directory.create(recursive: true);
    return _directory = directory;
  }

  @override
  bool get isSupported => true;

  @override
  Future<String?> capture(ReceiptSource source) async {
    final picked = await _picker.pickImage(
      source: source == ReceiptSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
    );
    if (picked == null) return null;
    final directory = await _receiptsDirectory();
    final name = _newName();
    // `saveTo` rather than `File.rename`: the picker's temporary file can sit
    // on a different volume from the documents directory, where a rename
    // fails outright instead of falling back to a copy.
    await picked.saveTo('${directory.path}/$name');
    return name;
  }

  String _newName() {
    // Same shape as the store's ids, and for the same reason: two photos taken
    // inside one millisecond must not collide on web-resolution clocks.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return 'receipt-$stamp-${_sequence++}.jpg';
  }

  @override
  File? fileFor(String name) {
    final directory = _directory;
    if (directory == null) return null;
    final file = File('${directory.path}/$name');
    return file.existsSync() ? file : null;
  }

  @override
  Future<void> remove(String name) async {
    final directory = await _receiptsDirectory();
    final file = File('${directory.path}/$name');
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<int> sweepOrphans(Iterable<String> referenced) async {
    final keep = referenced.toSet();
    final directory = await _receiptsDirectory();
    var removed = 0;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (keep.contains(name)) continue;
      await entity.delete();
      removed++;
    }
    return removed;
  }

  /// Resolves the directory so [fileFor] can answer synchronously afterwards.
  ///
  /// Thumbnails are built during `build`, which cannot await. Warming the path
  /// once at launch is what lets those rows stay synchronous.
  Future<void> warmUp() => _receiptsDirectory();
}

/// Hands the receipt store down the tree, so a test can swap in its own.
class ReceiptScope extends InheritedWidget {
  const ReceiptScope({super.key, required this.store, required super.child});

  final ReceiptStore store;

  static ReceiptStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReceiptScope>();
    // A screen built outside the scope should degrade to "no receipts here"
    // rather than crash, which is what widget tests of unrelated screens get.
    return scope?.store ?? const UnsupportedReceiptStore();
  }

  @override
  bool updateShouldNotify(ReceiptScope oldWidget) => store != oldWidget.store;
}
