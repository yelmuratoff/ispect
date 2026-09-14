import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/element_resolver.dart';

void main() {
  testWidgets('resolves the owning element once and reuses it', (tester) async {
    const targetKey = ValueKey<String>('target');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(key: targetKey, width: 10, height: 10)),
      ),
    );
    final renderObject = tester.renderObject(find.byKey(targetKey));

    final first = elementForRenderObject(renderObject);
    final second = elementForRenderObject(renderObject);

    expect(first, isNotNull);
    expect(first!.widget.key, targetKey);
    expect(second, same(first));
  });

  testWidgets('drops a cached element once its render object is replaced', (
    tester,
  ) async {
    const targetKey = ValueKey<String>('target');
    Widget build(bool wrapped) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: wrapped
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(key: targetKey, width: 10, height: 10),
              )
            : const SizedBox(key: targetKey, width: 10, height: 10),
      ),
    );

    await tester.pumpWidget(build(false));
    final before = tester.renderObject(find.byKey(targetKey));
    expect(elementForRenderObject(before), isNotNull);

    await tester.pumpWidget(build(true));
    final after = tester.renderObject(find.byKey(targetKey));

    expect(elementForRenderObject(before), isNull);
    expect(elementForRenderObject(after)?.widget.key, targetKey);
  });
}
