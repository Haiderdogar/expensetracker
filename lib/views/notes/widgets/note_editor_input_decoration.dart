import 'package:flutter/material.dart';

InputDecoration noteEditorInputDecoration(
  BuildContext context, {
  required String hint,
  bool isTitle = false,
}) {
  final colors = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: (isTitle ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyLarge)
        ?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.45),
          fontWeight: isTitle ? FontWeight.w700 : FontWeight.w400,
        ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    isDense: true,
  );
}
