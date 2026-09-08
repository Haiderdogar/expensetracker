import 'package:flutter/material.dart';

InputDecoration noteEditorInputDecoration(
  BuildContext context, {
  required String hint,
  bool isTitle = false,
}) {
  final colors = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: colors.outlineVariant),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: (isTitle ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyLarge)
        ?.copyWith(color: colors.onSurfaceVariant),
    alignLabelWithHint: !isTitle,
    filled: true,
    fillColor: colors.surfaceContainerHighest,
    contentPadding: isTitle ? const EdgeInsets.symmetric(horizontal: 16, vertical: 18) : const EdgeInsets.all(16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary, width: 1.5)),
  );
}
