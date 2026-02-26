import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium text field with icon, label animation, and accessible semantics.
class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.autofillHints,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          suffixIcon: suffixIcon,
          counterText: '',
        ),
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        autofillHints: autofillHints,
        enabled: enabled,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
