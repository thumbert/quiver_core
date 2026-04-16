import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// A performant autocomplete widget.
///
/// It only shows a scrollable window of choices instead of trying to dump
/// everything on the screen like `multiselect_search.dart` does.
///
/// Prefer this over `autocomplete.dart` because it uses get/set on a model
/// allowing for higher abstraction.
///
class AutocompleteUi<T> extends StatefulWidget {
  AutocompleteUi({
    required this.model,
    required this.setSelection,
    required this.getSelection,
    this.clearSelection,
    required this.choices,
    ListSignal<String>? accumulatedSelection,
    required this.width,
    this.height = 500.0,
    this.style,
    super.key,
  }) {
    this.accumulatedSelection = accumulatedSelection ?? <String>[].toSignal();
  }

  // what gets selected
  final Signal<T> model;
  final void Function(String value) setSelection;
  final String? Function(T model) getSelection;

  /// Called when the user clears the text field. Use this to set the model to null.
  final void Function()? clearSelection;

  final Set<String> choices;
  late final ListSignal<String> accumulatedSelection;
  final double width;
  // height of the dropdown
  final double height;
  final TextStyle? style;

  @override
  State<AutocompleteUi<T>> createState() => _AutocompleteUiState<T>();
}

class _AutocompleteUiState<T> extends State<AutocompleteUi<T>> {
  final focusNode = FocusNode();
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.getSelection(widget.model.value) ?? '';
    controller.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    if (controller.text.isEmpty && widget.clearSelection != null) {
      widget.clearSelection!();
    }
  }

  void _onFocusChanged() {
    if (!focusNode.hasFocus) {
      final text = controller.text;
      if (text.isEmpty) {
        widget.clearSelection?.call();
      } else if (widget.choices.contains(text)) {
        widget.setSelection(text);
      } else {
        // Revert to the current model value if the text doesn't match a valid choice
        controller.text = widget.getSelection(widget.model.value) ?? '';
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    focusNode.removeListener(_onFocusChanged);
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.text = widget.getSelection(widget.model.value) ?? '';
    return Watch(
      (_) => RawAutocomplete(
        focusNode: focusNode,
        textEditingController: controller,
        fieldViewBuilder:
            (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) => _AutocompleteField(
              focusNode: focusNode,
              textEditingController: textEditingController,
              onFieldSubmitted: onFieldSubmitted,
              options: widget.choices,
              style: widget.style,
            ),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue == TextEditingValue.empty) {
            return const Iterable<String>.empty();
          }
          final value = textEditingValue.text.toLowerCase();
          var items = widget.choices
              .where((e) => e.toLowerCase().contains(value))
              .toList();
          if (value != '') {
            // sort them to show the entries that give the best match
            items.sort(
              (a, b) =>
                  a.toLowerCase().length.compareTo(b.toLowerCase().length),
            );
          }
          return items;
        },
        onSelected: (String selection) {
          widget.setSelection(selection);
          var aux = widget.accumulatedSelection.value.toSet();
          aux.add(selection);
          widget.accumulatedSelection.value = aux.toList();
        },
        optionsViewBuilder:
            (
              BuildContext context,
              void Function(String) onSelected,
              Iterable<String> options,
            ) {
              return Align(
                alignment: Alignment.topLeft,
                child: PointerInterceptor(
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: widget.height,
                        maxWidth: widget.width,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        // Fixed extent: scroll positions computed in O(1),
                        // eliminating jank when jumping via the scrollbar.
                        itemExtent: 28.0,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Builder(
                              builder: (BuildContext context) {
                                final bool highlight =
                                    AutocompleteHighlightedOption.of(context) ==
                                    index;
                                if (highlight) {
                                  SchedulerBinding.instance
                                      .addPostFrameCallback((Duration _) {
                                        Scrollable.ensureVisible(
                                          context,
                                          alignment: 0.5,
                                        );
                                      });
                                }
                                return Container(
                                  width: widget.width,
                                  color: highlight
                                      ? Theme.of(context).focusColor
                                      : null,
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 2,
                                    bottom: 2,
                                  ),
                                  child: Text(option),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }
}

class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    required this.focusNode,
    required this.textEditingController,
    required this.onFieldSubmitted,
    required this.options,
    this.style,
  });

  final FocusNode focusNode;

  final VoidCallback onFieldSubmitted;

  final TextEditingController textEditingController;

  final Iterable<String> options;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: style,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        // border: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
      controller: textEditingController,
      focusNode: focusNode,
      onFieldSubmitted: (String value) {
        onFieldSubmitted();
      },
    );
  }
}

