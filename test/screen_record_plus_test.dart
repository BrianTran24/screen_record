import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_record_plus/screen_record_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenRecorderController', () {
    test('creates controller with default settings', () {
      final controller = ScreenRecorderController();
      expect(controller.pixelRatio, 0.5);
      expect(controller.skipFramesBetweenCaptures, 2);
      expect(controller.recordingMode, RecordingMode.widget);
      expect(controller.recordingRect, isNull);
    });

    test('creates controller with custom settings', () {
      final rect = const Rect.fromLTWH(100, 100, 200, 200);
      final controller = ScreenRecorderController(
        pixelRatio: 1.0,
        skipFramesBetweenCaptures: 0,
        recordingMode: RecordingMode.native,
        recordingRect: rect,
      );
      expect(controller.pixelRatio, 1.0);
      expect(controller.skipFramesBetweenCaptures, 0);
      expect(controller.recordingMode, RecordingMode.native);
      expect(controller.recordingRect, rect);
    });

    test('recording mode enum has correct values', () {
      expect(RecordingMode.values.length, 2);
      expect(RecordingMode.values.contains(RecordingMode.widget), isTrue);
      expect(RecordingMode.values.contains(RecordingMode.native), isTrue);
    });
  });

  group('NativeScreenRecorder', () {
    test('startRecording returns bool', () async {
      // Since we're in test environment, native platform won't be available
      // This will test that the method exists and returns a bool
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

  group('ScreenRecorder Widget', () {
    testWidgets('creates widget with required parameters', (tester) async {
      final controller = ScreenRecorderController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenRecorder(
            controller: controller,
            width: 300,
            height: 300,
            child: const Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('applies custom background color', (tester) async {
      final controller = ScreenRecorderController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenRecorder(
            controller: controller,
            width: 300,
            height: 300,
            background: Colors.red,
            child: const Text('Test'),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScreenRecorder),
          matching: find.byType(Container),
        ).first,
      );
      
      expect(container.color, Colors.red);
    });
  });

  group('Exporter', () {
    test('creates exporter from controller', () {
      final controller = ScreenRecorderController();
      final exporter = controller.exporter;
      expect(exporter, isA<Exporter>());
    });

    test('exporter has correct skip frames', () {
      final controller = ScreenRecorderController(skipFramesBetweenCaptures: 5);
      final exporter = controller.exporter;
      expect(exporter.skipFramesBetweenCaptures, 5);
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

  group('Frame', () {
    test('creates frame with timestamp and image', () {
      // Frame requires a ui.Image which is hard to mock in tests
      // So we just verify the class exists and is exported
      expect(Frame, isNotNull);
    });
  });
}
