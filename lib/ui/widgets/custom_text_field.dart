// lib/ui/widgets/custom_text_field.dart

import 'package:flutter/material.dart';

/// Campo de texto personalizado hermoso
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final String? hint;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.hint,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: _isFocused 
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isFocused ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _isFocused 
              ? const Color(0xFF1E3A8A) 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(
              widget.icon, 
              color: _isFocused 
                  ? const Color(0xFF1E3A8A) 
                  : Colors.grey.shade600,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: _isFocused 
                          ? const Color(0xFF1E3A8A) 
                          : Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
            contentPadding: const EdgeInsets.all(16),
            labelStyle: TextStyle(
              color: _isFocused 
                  ? const Color(0xFF1E3A8A) 
                  : Colors.grey.shade600,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}