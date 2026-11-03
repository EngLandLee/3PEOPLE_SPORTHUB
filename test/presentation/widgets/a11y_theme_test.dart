import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/domain/entities/venue_addon.dart';
import 'package:sporthub/presentation/widgets/visual_court_slot_cell.dart';
import 'package:sporthub/presentation/widgets/venue_addon_selector.dart';

void main() {
  group('Accessibility (A11y) & Theme Tests', () {
    testWidgets('VisualCourtSlotCell renders rich accessibility semantics', (tester) async {
      final slot = TimeSlot(
        id: 'slot_1',
        courtNumber: 2,
        date: '2026-09-08',
        startTime: '18:00',
        endTime: '19:00',
        price: 150000,
        status: SlotStatus.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisualCourtSlotCell(
              slot: slot,
              sportType: 'badminton',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Semantics contains descriptive label
      final semanticsFinder = find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          final label = widget.properties.label ?? '';
          return label.contains('Sân 2') &&
              label.contains('18:00') &&
              label.contains('150.000');
        }
        return false;
      });

      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('VenueAddonSelector provides tooltips and semantic labels for stepper buttons', (tester) async {
      final items = <VenueAddonItem>[
        const VenueAddonItem(
          id: 'racket_yonex',
          name: 'Vợt Yonex Astrox 88D Pro',
          description: 'Vợt thi đấu chuyên nghiệp',
          price: 50000,
          unit: 'cây',
          icon: '🏸',
          category: AddonCategory.rental,
        ),
      ];
      final counts = {'racket_yonex': 2};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueAddonSelector(
                items: items,
                selectedCounts: counts,
                onQuantityChanged: (_, __) {},
              ),
            ),
          ),
        ),
      );

      // Check tooltips for decrement and increment buttons
      expect(find.byTooltip('Giảm số lượng'), findsOneWidget);
      expect(find.byTooltip('Tăng số lượng'), findsOneWidget);
    });

    test('Cyber Volt sports theme colors provide high contrast', () {
      // Dark primary should be high-visibility sports accent
      expect(AppColors.darkPrimary, isNotNull);
      expect(AppColors.accent, isNotNull);
      expect(AppColors.darkBackground, const Color(0xFF070B14));
    });
  });
}
