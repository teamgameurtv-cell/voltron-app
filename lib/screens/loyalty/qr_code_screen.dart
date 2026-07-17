import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('MON QR CODE'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.name.isNotEmpty ? profile.name : 'Mon compte',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${profile.loyaltyPoints} points disponibles',
                  style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: CustomPaint(painter: _FakeQrPainter()),
              ),
              const SizedBox(height: 20),
              const Text(
                'Présente ce code en boutique pour cumuler\nou utiliser tes points fidélité.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = VoltronColors.deepBlack;
    const cells = 12;
    final cellSize = size.width / cells;
    final rnd = List.generate(cells * cells, (i) => (i * 928371 + i * i * 17) % 5 == 0);

    for (int y = 0; y < cells; y++) {
      for (int x = 0; x < cells; x++) {
        final isCorner = (x < 3 && y < 3) || (x < 3 && y >= cells - 3) || (x >= cells - 3 && y < 3);
        if (isCorner || rnd[y * cells + x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize * 0.9, cellSize * 0.9),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
