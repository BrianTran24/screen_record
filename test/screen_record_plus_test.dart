import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenRecorderController', () {
    test('creates controller with default settings', () {
      final controller = ScreenRecorderController();
      expect(controller.recordingRect, isNull);
    });

    test('creates controller with custom coordinates', () {
      final rect = const Rect.fromLTWH(100, 100, 200, 200);
      final controller = ScreenRecorderController(
        recordingRect: rect,
      );
      expect(controller.recordingRect, rect);
    });

    test('duration throws when recording not started', () {
      final controller = ScreenRecorderController();
      expect(() => controller.duration, throwsException);
    });

    testWidgets('getWidgetRect returns null for unmounted widget', (tester) async {
      final key = GlobalKey();
      final rect = ScreenRecorderController.getWidgetRect(key);
      expect(rect, isNull);
    });

    testWidgets('getWidgetRect returns correct rect for mounted widget', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: key,
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      final rect = ScreenRecorderController.getWidgetRect(key);
      expect(rect, isNotNull);
      expect(rect!.width, 200);
      expect(rect.height, 200);
    });
  });

  group('NativeScreenRecorder', () {
    test('startRecording returns bool', () async {
      final result = await NativeScreenRecorder.startRecording();
      expect(result, isA<bool>());
    });

    test('startRecording with coordinates', () async {
      final result = await NativeScreenRecorder.startRecording(
        x: 100,
        y: 100,
        width: 200,
        height: 200,
      );
      expect(result, isA<bool>());
    });

    test('stopRecording returns bool', () async {
      final result = await NativeScreenRecorder.stopRecording();
      expect(result, isA<bool>());
    });

    test('isSupported returns bool', () async {
      final result = await NativeScreenRecorder.isSupported();
      expect(result, isA<bool>());
    });

    test('isRecording returns bool', () async {
      final result = await NativeScreenRecorder.isRecording();
      expect(result, isA<bool>());
    });

    test('exportVideo with path', () async {
      final result = await NativeScreenRecorder.exportVideo(
        outputPath: '/tmp/test.mp4',
      );
      expect(result, isA<String?>());
    });
  });

  group('Exporter', () {
    test('creates exporter from controller', () {
      final controller = ScreenRecorderController();
      final exporter = controller.exporter;
      expect(exporter, isA<Exporter>());
    });
  });

  group('ExportResult', () {
    test('creates export result with status', () {
      final result = ExportResult(status: ExportStatus.exporting);
      expect(result.status, ExportStatus.exporting);
      expect(result.file, isNull);
      expect(result.percent, isNull);
    });

    test('creates export result with all parameters', () {
      final result = ExportResult(
        status: ExportStatus.exported,
        percent: 1.0,
      );
      expect(result.status, ExportStatus.exported);
      expect(result.percent, 1.0);
    });

    test('export status enum has all values', () {
      expect(ExportStatus.values.length, 5);
      expect(ExportStatus.values.contains(ExportStatus.exporting), isTrue);
      expect(ExportStatus.values.contains(ExportStatus.encoding), isTrue);
      expect(ExportStatus.values.contains(ExportStatus.encoded), isTrue);
      expect(ExportStatus.values.contains(ExportStatus.exported), isTrue);
      expect(ExportStatus.values.contains(ExportStatus.failed), isTrue);
    });
  });
}
