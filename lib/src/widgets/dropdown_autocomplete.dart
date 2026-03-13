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
    required this.choices,
    ListSignal<String>? accumulatedSelection,
    required this.width,
    this.height = 500.0,
    super.key,
  }) {
    this.accumulatedSelection = accumulatedSelection ?? <String>[].toSignal();
  }

  // what gets selected
  final Signal<T> model;
  final void Function(String value) setSelection;
  final String? Function(T model) getSelection;

  final Set<String> choices;
  late final ListSignal<String> accumulatedSelection;
  final double width;
  // height of the dropdown
  final double height;

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
  }

  @override
  void dispose() {
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
                        maxHeight: 400,
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
  });

  final FocusNode focusNode;

  final VoidCallback onFieldSubmitted;

  final TextEditingController textEditingController;

  final Iterable<String> options;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(fontSize: 13.0),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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

// /// A multi-select autocomplete widget. Similar to [AutocompleteUi] but allows
// /// selecting multiple items simultaneously.
// ///
// /// Selected items are shown at the top of the dropdown with a checkbox next to
// /// them. Unselected choices that match the current search query appear below.
// /// A "Clear all" button at the top lets the user deselect everything at once.
// ///
// /// The dropdown opens when the text field gains focus and closes when the user
// /// taps outside the widget.
// ///
// class MultiSelectAutocompleteUi extends StatefulWidget {
//   const MultiSelectAutocompleteUi({
//     required this.choices,
//     required this.selections,
//     required this.width,
//     this.height = 500.0,
//     this.itemName = 'item',
//     super.key,
//   });

//   /// All available choices to pick from.
//   final Set<String> choices;

//   /// The reactive list of currently selected items. Updated in place as the
//   /// user makes or removes selections.
//   final ListSignal<String> selections;

//   /// Width of the text field and the dropdown overlay.
//   final double width;

//   /// Maximum height of the dropdown overlay.
//   final double height;

//   /// Name of the item type, used in the text field hint (e.g. "3 fruits selected").
//   final String itemName;

//   @override
//   State<MultiSelectAutocompleteUi> createState() =>
//       _MultiSelectAutocompleteUiState();
// }

// class _MultiSelectAutocompleteUiState extends State<MultiSelectAutocompleteUi> {
//   final FocusNode _focusNode = FocusNode();
//   final TextEditingController _controller = TextEditingController();
//   final LayerLink _layerLink = LayerLink();
//   OverlayEntry? _overlayEntry;
//   late final Signal<String> _querySignal;

//   // Shared group id so that tapping inside the overlay does not count as
//   // "outside" and close the dropdown prematurely.
//   final Object _tapRegionGroupId = Object();

//   @override
//   void initState() {
//     super.initState();
//     _querySignal = Signal<String>('');
//     _focusNode.addListener(_onFocusChanged);
//     _controller.addListener(_onTextChanged);
//   }

//   @override
//   void dispose() {
//     _removeOverlay();
//     _focusNode.removeListener(_onFocusChanged);
//     _focusNode.dispose();
//     _controller.removeListener(_onTextChanged);
//     _controller.dispose();
//     _querySignal.dispose();
//     super.dispose();
//   }

//   void _onFocusChanged() {
//     if (_focusNode.hasFocus) {
//       _showOverlay();
//     }
//   }

//   void _onTextChanged() {
//     _querySignal.value = _controller.text;
//   }

//   void _showOverlay() {
//     if (_overlayEntry != null) return;
//     _overlayEntry = _createOverlayEntry();
//     Overlay.of(context).insert(_overlayEntry!);
//   }

//   void _removeOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//     _controller.text = '';
//   }

//   void _toggleSelection(String value) {
//     final current = widget.selections.value.toSet();
//     if (current.contains(value)) {
//       current.remove(value);
//     } else {
//       current.add(value);
//     }
//     widget.selections.value = current.toList();
//   }

//   void _clearAll() {
//     widget.selections.value = [];
//   }

//   void _selectAll() {
//     final query = _querySignal.value.toLowerCase();
//     final selected = widget.selections.value.toSet();
//     final toAdd = widget.choices.where(
//       (e) =>
//           !selected.contains(e) &&
//           (query.isEmpty || e.toLowerCase().contains(query)),
//     );
//     widget.selections.value = [...selected, ...toAdd].toList();
//   }

//   OverlayEntry _createOverlayEntry() {
//     return OverlayEntry(
//       // The structural widgets (Positioned, CompositedTransformFollower, etc.)
//       // are static and never rebuild. Only the list content inside
//       // _MultiSelectOverlayList is wrapped in Watch and rebuilds on signal
//       // changes.
//       builder: (context) => Positioned(
//         width: widget.width,
//         child: CompositedTransformFollower(
//           link: _layerLink,
//           showWhenUnlinked: false,
//           offset: const Offset(0, 36),
//           child: TapRegion(
//             groupId: _tapRegionGroupId,
//             // One PointerInterceptor covers the whole overlay instead of
//             // one per item, reducing widget-tree depth.
//             child: PointerInterceptor(
//               child: Material(
//                 elevation: 4.0,
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight: widget.height,
//                     maxWidth: widget.width,
//                   ),
//                   child: _MultiSelectOverlayList(
//                     choices: widget.choices,
//                     selections: widget.selections,
//                     querySignal: _querySignal,
//                     onToggle: _toggleSelection,
//                     onClearAll: _clearAll,
//                     onSelectAll: _selectAll,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return TapRegion(
//       groupId: _tapRegionGroupId,
//       onTapOutside: (_) => _removeOverlay(),
//       child: CompositedTransformTarget(
//         link: _layerLink,
//         child: Watch((_) {
//           final count = widget.selections.value.length;
//           return TextFormField(
//             style: const TextStyle(fontSize: 13.0),
//             decoration: InputDecoration(
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(
//                 vertical: 12,
//                 horizontal: 10,
//               ),
//               enabledBorder: InputBorder.none,
//               hintText:
//                   '$count ${widget.itemName}${count == 1 ? '' : 's'} selected',
//               hintStyle: const TextStyle(fontSize: 13, color: Colors.black87),
//             ),
//             controller: _controller,
//             focusNode: _focusNode,
//           );
//         }),
//       ),
//     );
//   }
// }

// /// Private widget that owns the reactive list content of the multi-select
// /// overlay. Isolating it here means the structural overlay widgets
// /// (Positioned, CompositedTransformFollower, Material, etc.) never rebuild
// /// when signals change — only the CustomScrollView inside does.
// class _MultiSelectOverlayList extends StatelessWidget {
//   const _MultiSelectOverlayList({
//     required this.choices,
//     required this.selections,
//     required this.querySignal,
//     required this.onToggle,
//     required this.onClearAll,
//     required this.onSelectAll,
//   });

//   final Set<String> choices;
//   final ListSignal<String> selections;
//   final Signal<String> querySignal;
//   final void Function(String) onToggle;
//   final VoidCallback onClearAll;
//   final VoidCallback onSelectAll;

//   // Fixed row height lets SliverFixedExtentList compute scroll positions in
//   // O(1) instead of measuring every item, which eliminates scrollbar jank.
//   static const double _itemHeight = 32.0;

//   Widget _buildItem(String item, bool isSelected) {
//     return InkWell(
//       onTap: () => onToggle(item),
//       child: SizedBox(
//         height: _itemHeight,
//         child: Row(
//           children: [
//             ExcludeFocus(
//               child: Checkbox(
//                 value: isSelected,
//                 onChanged: (_) => onToggle(item),
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 visualDensity: VisualDensity.compact,
//               ),
//             ),
//             const SizedBox(width: 4),
//             Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Watch((_) {
//       final query = querySignal.value.toLowerCase();
//       final selectedList = selections.value;
//       final selected = selectedList.toSet();
//       final unselected = choices
//           .where(
//             (e) =>
//                 !selected.contains(e) &&
//                 (query.isEmpty || e.toLowerCase().contains(query)),
//           )
//           .toList();
//       if (query.isNotEmpty) {
//         unselected.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
//       }

//       return CustomScrollView(
//         slivers: [
//           // Action bar: "Select all" on the left, "Clear all" on the right.
//           // Always rendered so the layout doesn't shift as items are selected.
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   if (unselected.isNotEmpty)
//                     InkWell(
//                       onTap: onSelectAll,
//                       child: const Text(
//                         'Select all',
//                         style: TextStyle(color: Colors.blue, fontSize: 12),
//                       ),
//                     )
//                   else
//                     const SizedBox.shrink(),
//                   if (selected.isNotEmpty)
//                     InkWell(
//                       onTap: onClearAll,
//                       child: const Text(
//                         'Clear all',
//                         style: TextStyle(color: Colors.blue, fontSize: 12),
//                       ),
//                     )
//                   else
//                     const SizedBox.shrink(),
//                 ],
//               ),
//             ),
//           ),
//           // Selected items + divider (only when something is selected).
//           if (selected.isNotEmpty)
//             SliverList(
//               delegate: SliverChildListDelegate([
//                 ...selectedList.map((item) => _buildItem(item, true)),
//                 const Divider(height: 1),
//               ]),
//             ),
//           // Unselected choices: SliverFixedExtentList gives O(1) scroll
//           // position calculation — no layout work for off-screen items.
//           SliverFixedExtentList(
//             itemExtent: _itemHeight,
//             delegate: SliverChildBuilderDelegate(
//               (ctx, i) => _buildItem(unselected[i], false),
//               childCount: unselected.length,
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }
