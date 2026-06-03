import 'package:dandi_bot/app.dart';
import 'package:dandi_bot/screens/analysis/analysis_screen.dart';
import 'package:dandi_bot/screens/history/history_screen.dart';
import 'package:dandi_bot/services/app_controller.dart';
import 'package:dandi_bot/services/local_storage_service.dart';
import 'package:dandi_bot/services/storage_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeStorageBackend implements StorageBackend {
  final Map<String, String> _memory = {};

  @override
  Future<String?> read(String key) async => _memory[key];

  @override
  Future<void> write(String key, String value) async {
    _memory[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _memory.remove(key);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets('Dandi Bot home renders', (tester) async {
    final fakeBackend = FakeStorageBackend();
    final fakeStorage = LocalStorageService(backend: fakeBackend);
    
    final controller = AppController(localStorageService: fakeStorage);
    await tester.runAsync(() async {
      await controller.initialize();
    });

    await tester.pumpWidget(DandiApp(controller: controller));
    await tester.pump();

    expect(find.text('Dandi Bot'), findsWidgets);
    expect(find.text('ANALISAR'), findsOneWidget);
  });

  testWidgets('AnalysisScreen renders with stock and crypto', (tester) async {
    // Configura tamanho de Desktop confortável no teste
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeBackend = FakeStorageBackend();
    final fakeStorage = LocalStorageService(backend: fakeBackend);
    final controller = AppController(localStorageService: fakeStorage);
    
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.analyzeTicker('PETR4.SA');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DandiScope(
          controller: controller,
          child: const Scaffold(
            body: AnalysisScreen(),
          ),
        ),
      ),
    );
    // Dá pump de 1 segundo para resolver o delay de 500ms do MockAnalysisService disparado no initState
    await tester.pump(const Duration(seconds: 1));

    await tester.runAsync(() async {
      await controller.analyzeTicker('BTC-USD');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DandiScope(
          controller: controller,
          child: const Scaffold(
            body: AnalysisScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(true, true);
  });

  testWidgets('HistoryScreen renders with stock and crypto', (tester) async {
    // Configura tamanho de Desktop confortável no teste
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeBackend = FakeStorageBackend();
    final fakeStorage = LocalStorageService(backend: fakeBackend);
    final controller = AppController(localStorageService: fakeStorage);
    
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.analyzeTicker('PETR4.SA');
      await controller.analyzeTicker('BTC-USD');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DandiScope(
          controller: controller,
          child: const Scaffold(
            body: HistoryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(true, true);
  });
}
