import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../tracking/data/services/tracking_service.dart';

/// شاشة مسح QR Code - من qr_code_screen.dart الأصلي
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  late final MobileScannerController _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    final uri = Uri.tryParse(rawValue);
    if (uri == null || uri.scheme.isEmpty) return;

    _scanned = true;
    AppLogger.info('📱 QR Code scanned: $rawValue');

    // تطبيق الإعدادات من الرابط
    final storage = ref.read(localStorageProvider);
    await storage.applyFromUri(uri);

    // تحديث المتتبع
    await ref.read(trackingServiceProvider).updateConfig();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.settingsAppliedSuccess),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.qrScannerTitle,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
          ),
          // إطار المسح
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryBlue, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // تعليمات
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              context.loc.qrScannerInstructions,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.surface.withValues(alpha: 0.8),
                fontSize: AppTypography.bodySize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



