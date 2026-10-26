import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/player/widgets/player_output_volume_card.dart';

void main() {
  testWidgets(
    'PlayerOutputVolumeCard renders device selector without volume slider',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PlayerOutputVolumeCard())),
      );

      await tester.pumpAndSettle();

      // Verify there is no Slider widget (volume removed)
      expect(find.byType(Slider), findsNothing);

      // Verify output destination elements exist
      expect(find.text('SWITCH'), findsOneWidget);

      // Verify tap opens bottom sheet
      await tester.tap(find.text('SWITCH'));
      await tester.pumpAndSettle();

      // Bottom sheet header should be visible
      expect(find.text('OUTPUT DESTINATIONS'), findsOneWidget);
      expect(find.text('Select audio hardware to stream to'), findsOneWidget);
    },
  );
}
