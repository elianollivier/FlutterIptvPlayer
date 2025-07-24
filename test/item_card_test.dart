import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';

import 'package:flutter_iptv_player/src/models/iptv_models.dart';
import 'package:flutter_iptv_player/src/widgets/item_card.dart';

void main() {
  final item = IptvItem(
    id: '1',
    type: IptvItemType.media,
    name: 'Item',
    links: [
      ChannelLink(
        name: 'L1',
        url: 'https://example.com/very/long/path/stream.m3u8',
        logo: '',
        resolution: '',
        fps: '',
        notes: const [],
      ),
    ],
  );

  Widget buildTest() {
    return MaterialApp(
      home: Material(
        child: ItemCard(
          item: item,
          onEdit: () {},
          onOpenLink: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows preview on hover', (tester) async {
    await tester.pumpWidget(buildTest());
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(ItemCard)));
    await tester.pumpAndSettle();
    expect(find.text('L1'), findsOneWidget);
  });

  testWidgets('tapping preview expands list', (tester) async {
    await tester.pumpWidget(buildTest());
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(ItemCard)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L1'));
    await tester.pumpAndSettle();
    expect(find.text('L1'), findsNWidgets(2));
  });
}
