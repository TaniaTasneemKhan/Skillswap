import 'package:flutter/material.dart';

/// Type a skill, press add/enter, and it becomes a removable chip.
class SkillChipInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  const SkillChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  @override
  State<SkillChipInput> createState() => _SkillChipInputState();
}

class _SkillChipInputState extends State<SkillChipInput> {
  final _ctrl = TextEditingController();

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    final exists = widget.values.any((e) => e.toLowerCase() == v.toLowerCase());
    if (!exists) widget.onChanged([...widget.values, v]);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _add),
            ),
          ),
          if (widget.values.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in widget.values)
                    InputChip(
                      label: Text(s),
                      onDeleted: () => widget
                          .onChanged(widget.values.where((e) => e != s).toList()),
                    ),
                ],
              ),
            ),
        ],
      );
}
