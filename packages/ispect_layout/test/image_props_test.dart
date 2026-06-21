import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/image_props.dart';
import 'package:ispect_layout/src/widgets/components/property_widgets.dart';

PropSpec? _propBySubtitle(List<PropSpec> props, String subtitle) {
  for (final p in props) {
    if (p.subtitle == subtitle) return p;
  }
  return null;
}

String? _textOf(Widget? child) {
  if (child is EllipsizedText) return child.value;
  if (child is Text) return child.data;
  return null;
}

void main() {
  group('imageProps source', () {
    test('uses debugImageLabel when present', () {
      final render = RenderImage(
        debugImageLabel: 'https://example.com/cat.png',
        textDirection: TextDirection.ltr,
      );

      final source = _propBySubtitle(imageProps(render), 'source');

      expect(_textOf(source?.child), 'https://example.com/cat.png');
    });

    test('omits source when no label or provider is available', () {
      final render = RenderImage(textDirection: TextDirection.ltr);

      expect(_propBySubtitle(imageProps(render), 'source'), isNull);
    });
  });

  group('imageProps detail', () {
    test('surfaces non-default render properties', () {
      final render = RenderImage(
        debugImageLabel: 'a',
        fit: BoxFit.cover,
        scale: 2.0,
        filterQuality: FilterQuality.high,
        color: const Color(0xFF00FF00),
        colorBlendMode: BlendMode.modulate,
        repeat: ImageRepeat.repeat,
        centerSlice: const Rect.fromLTRB(2, 2, 8, 8),
        invertColors: true,
        matchTextDirection: true,
        isAntiAlias: true,
        textDirection: TextDirection.ltr,
      );

      final props = imageProps(render);

      expect(_textOf(_propBySubtitle(props, 'fit')?.child), 'cover');
      expect(_textOf(_propBySubtitle(props, 'scale')?.child), '2.0×');
      expect(_textOf(_propBySubtitle(props, 'filter quality')?.child), 'high');
      expect(_textOf(_propBySubtitle(props, 'blend mode')?.child), 'modulate');
      expect(_textOf(_propBySubtitle(props, 'repeat')?.child), 'repeat');
      expect(_propBySubtitle(props, 'center slice'), isNotNull);
      expect(_propBySubtitle(props, 'invert colors'), isNotNull);
      expect(_propBySubtitle(props, 'match text dir'), isNotNull);
      expect(_propBySubtitle(props, 'anti-alias'), isNotNull);
    });

    test('suppresses properties left at their defaults', () {
      final render = RenderImage(
        debugImageLabel: 'a',
        textDirection: TextDirection.ltr,
      );

      final props = imageProps(render);

      expect(_propBySubtitle(props, 'scale'), isNull);
      expect(_propBySubtitle(props, 'filter quality'), isNull);
      expect(_propBySubtitle(props, 'repeat'), isNull);
      expect(_propBySubtitle(props, 'center slice'), isNull);
      expect(_propBySubtitle(props, 'blend mode'), isNull);
      expect(_propBySubtitle(props, 'invert colors'), isNull);
      expect(_propBySubtitle(props, 'match text dir'), isNull);
      expect(_propBySubtitle(props, 'anti-alias'), isNull);
    });

    test('raw px chip reports pixel size and estimated memory', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final image = await createTestImage(width: 100, height: 50);
      addTearDown(image.dispose);
      final render = RenderImage(
        image: image,
        textDirection: TextDirection.ltr,
      );

      final raw = _textOf(_propBySubtitle(imageProps(render), 'raw px')?.child);

      expect(raw, contains('100×50'));
      expect(raw, contains('KB'));
    });
  });

  group('resolveImageProvider', () {
    testWidgets('recovers the provider from the Image ancestor of RawImage',
        (tester) async {
      const provider = _IdleImageProvider();

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Image(image: provider, width: 20, height: 20),
        ),
      );

      final render = tester.renderObject<RenderImage>(find.byType(RawImage));

      expect(resolveImageProvider(render), same(provider));
    });
  });
}

/// An [ImageProvider] whose stream never completes, so [Image] mounts a
/// [RawImage] without any network access, decode, or error reporting.
class _IdleImageProvider extends ImageProvider<_IdleImageProvider> {
  const _IdleImageProvider();

  @override
  Future<_IdleImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_IdleImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _IdleImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      _IdleImageStreamCompleter();
}

class _IdleImageStreamCompleter extends ImageStreamCompleter {}
