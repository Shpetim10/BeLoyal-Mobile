import 'package:flutter/material.dart';

/// Password field with visibility toggle and premium icon.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscured,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
            tooltip: _obscured ? 'Show password' : 'Hide password',
          ),
        ),
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        autofillHints: const [AutofillHints.password],
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
