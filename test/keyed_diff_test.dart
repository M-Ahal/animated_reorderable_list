import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  List<int> items, {
  Object Function(int item)? keyOf,
  bool Function(int a, int b)? isSameItem,
}) =>
    MaterialApp(
      home: Scaffold(
        body: AnimatedListView<int>(
          items: items,
          isSameItem: isSameItem,
          keyOf: keyOf,
          insertDuration: Duration.zero,
          removeDuration: Duration.zero,
          itemBuilder: (context, index) => SizedBox(
            key: ValueKey<int>(items[index]),
            height: 20,
            child: Text('${items[index]}'),
          ),
        ),
      ),
    );

List<int> _rendered(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => int.parse(t.data!))
    .toList();

void main() {
  // keyOf must be a drop-in for isSameItem.
  for (final mode in <String>['isSameItem', 'keyOf']) {
    testWidgets('$mode: insert, remove and replace land the same', (
      tester,
    ) async {
      Widget host(List<int> items) => mode == 'keyOf'
          ? _host(items, keyOf: (i) => i)
          : _host(items, isSameItem: (a, b) => a == b);

      await tester.pumpWidget(host(<int>[1, 2, 3]));
      expect(_rendered(tester), <int>[1, 2, 3]);

      await tester.pumpWidget(host(<int>[1, 9, 2, 3]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[1, 9, 2, 3]);

      await tester.pumpWidget(host(<int>[1, 9, 3]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[1, 9, 3]);

      await tester.pumpWidget(host(<int>[7, 8]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[7, 8]);
    });
  }

  // The whole point of keyOf.
  testWidgets('keyOf keeps the diff linear', (tester) async {
    const n = 200;
    var calls = 0;
    Object countingKeyOf(int item) {
      calls++;
      return item;
    }

    final items = List<int>.generate(n, (i) => i);
    await tester.pumpWidget(_host(items, keyOf: countingKeyOf));
    // Explicit pumps: a 300ms timer per item means pumpAndSettle never drains.
    await tester.pump(const Duration(milliseconds: 400));

    calls = 0;
    await tester.pumpWidget(_host(<int>[...items, n], keyOf: countingKeyOf));
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, greaterThan(0), reason: 'keyOf should drive the diff');
    expect(calls, lessThan(n * 5), reason: 'diff went quadratic again');
  });
}
