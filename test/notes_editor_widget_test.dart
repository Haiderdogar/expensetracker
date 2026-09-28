import 'package:expensetracker/views/notes/note_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('note editor remains scrollable with keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: NoteEditorScreen())),
    );
    await tester.pumpAndSettle();

    const longTitle =
        'A note title that is long enough to wrap across several lines and remain fully visible';
    await tester.enterText(find.byType(TextFormField).first, longTitle);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(longTitle), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(TextFormField).first,
              matching: find.byType(TextField),
            ),
          )
          .maxLines,
      isNull,
    );

    await tester.enterText(find.byType(TextFormField).last, 'Note details');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
