import 'package:flutter/material.dart';

import '../../domain/value_objects/measurement_unit.dart';

/// Campo numérico en milímetros que sincroniza su texto con el modelo.
///
/// No fuerza el valor mientras el usuario escribe: la validación se encarga
/// de avisar. Si el valor cambia desde fuera (por ejemplo al restablecer),
/// el texto se actualiza cuando el campo no tiene el foco.
class MmField extends StatefulWidget {
  final Key? fieldKey;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? helperText;
  final MeasurementUnit unit;

  const MmField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fieldKey,
    this.helperText,
    this.unit = MeasurementUnit.millimeter,
  });

  @override
  State<MmField> createState() => _MmFieldState();
}

class _MmFieldState extends State<MmField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.unit.formatValue(widget.value),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant MmField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        ((widget.value - oldWidget.value).abs() > 0.001 ||
            widget.unit != oldWidget.unit)) {
      _controller.text = widget.unit.formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) return;
    widget.onChanged(widget.unit.toMillimeters(parsed));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onChanged: _handleChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        suffixText: widget.unit.code,
      ),
    );
  }
}
