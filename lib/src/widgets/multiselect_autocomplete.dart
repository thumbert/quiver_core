import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// A multi-select autocomplete widget. Similar to [AutocompleteUi] but allows
/// selecting multiple items simultaneously.
///
/// Selected items are shown at the top of the dropdown with a checkbox next to
/// them. Unselected choices that match the current search query appear below.
/// A "Clear all" button at the top lets the user deselect everything at once.
///
/// The dropdown opens when the text field gains focus and closes when the user
/// taps outside the widget.
///
class MultiSelectAutocompleteUi<T> extends StatefulWidget {
  const MultiSelectAutocompleteUi({
    required this.model,
    required this.setSelection,
    required this.getSelection,
    required this.choices,
    required this.width,
    this.height = 500.0,
    this.itemName = 'item',
    super.key,
  });

  // what gets selected
  final Signal<T> model;
  final void Function(List<String> value) setSelection;
  final List<String> Function(T model) getSelection;

  /// All available choices to pick from.
  final Set<String> choices;

  /// The reactive list of currently selected items. Updated in place as the
  /// user makes or removes selections.
  // final ListSignal<String> selections;

  /// Width of the text field and the dropdown overlay.
  final double width;

  /// Maximum height of the dropdown overlay.
  final double height;

  /// Name of the item type, used in the text field hint (e.g. "3 fruits selected").
  final String itemName;

  @override
  State<MultiSelectAutocompleteUi<T>> createState() =>
      _MultiSelectAutocompleteUiState<T>();
}

class _MultiSelectAutocompleteUiState<T>
    extends State<MultiSelectAutocompleteUi<T>> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final Signal<String> _querySignal;

  // Shared group id so that tapping inside the overlay does not count as
  // "outside" and close the dropdown prematurely.
  final Object _tapRegionGroupId = Object();

  @override
  void initState() {
    super.initState();
    _querySignal = Signal<String>('');
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _querySignal.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _onTextChanged() {
    _querySignal.value = _controller.text;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.text = '';
  }

  void _toggleSelection(String value) {
    final current = widget.getSelection(widget.model.value).toSet();
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    widget.setSelection(current.toList());
    _focusNode.requestFocus();
  }

  void _clearAll() {
    widget.setSelection([]);
    _focusNode.requestFocus();
  }

  void _selectAll() {
    final query = _querySignal.value.toLowerCase();
    final selected = widget.getSelection(widget.model.value).toSet();
    final toAdd = widget.choices.where(
      (e) =>
          !selected.contains(e) &&
          (query.isEmpty || e.toLowerCase().contains(query)),
    );
    widget.setSelection([...selected, ...toAdd].toList());
    _focusNode.requestFocus();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      // The structural widgets (Positioned, CompositedTransformFollower, etc.)
      // are static and never rebuild. Only the list content inside
      // _MultiSelectOverlayList is wrapped in Watch and rebuilds on signal
      // changes.
      builder: (context) => Positioned(
        width: widget.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 36),
          child: TapRegion(
            groupId: _tapRegionGroupId,
            // One PointerInterceptor covers the whole overlay instead of
            // one per item, reducing widget-tree depth.
            child: PointerInterceptor(
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: widget.height,
                    maxWidth: widget.width,
                  ),
                  child: _MultiSelectOverlayList<T>(
                    choices: widget.choices,
                    model: widget.model,
                    getSelection: widget.getSelection,
                    querySignal: _querySignal,
                    onToggle: _toggleSelection,
                    onClearAll: _clearAll,
                    onSelectAll: _selectAll,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroupId,
      onTapOutside: (_) => _removeOverlay(),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Watch((_) {
          final count = widget.getSelection(widget.model.value).length;
          return TextFormField(
            style: const TextStyle(fontSize: 13.0),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 10,
              ),
              enabledBorder: InputBorder.none,
              hintText:
                  '$count ${widget.itemName}${count == 1 ? '' : 's'} selected',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            controller: _controller,
            focusNode: _focusNode,
          );
        }),
      ),
    );
  }
}

/// Private widget that owns the reactive list content of the multi-select
/// overlay. Isolating it here means the structural overlay widgets
/// (Positioned, CompositedTransformFollower, Material, etc.) never rebuild
/// when signals change — only the CustomScrollView inside does.
class _MultiSelectOverlayList<T> extends StatelessWidget {
  const _MultiSelectOverlayList({
    required this.choices,
    required this.model,
    required this.getSelection,
    required this.querySignal,
    required this.onToggle,
    required this.onClearAll,
    required this.onSelectAll,
  });

  final Set<String> choices;
  final Signal<T> model;
  final List<String> Function(T) getSelection;
  final Signal<String> querySignal;
  final void Function(String) onToggle;
  final VoidCallback onClearAll;
  final VoidCallback onSelectAll;

  // Fixed row height lets SliverFixedExtentList compute scroll positions in
  // O(1) instead of measuring every item, which eliminates scrollbar jank.
  static const double _itemHeight = 32.0;

  Widget _buildItem(String item, bool isSelected) {
    return InkWell(
      onTap: () => onToggle(item),
      child: SizedBox(
        height: _itemHeight,
        child: Row(
          children: [
            ExcludeFocus(
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(item),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final query = querySignal.value.toLowerCase();
      final selectedList = getSelection(model.value);
      final selected = selectedList.toSet();
      final unselected = choices
          .where(
            (e) =>
                !selected.contains(e) &&
                (query.isEmpty || e.toLowerCase().contains(query)),
          )
          .toList();
      if (query.isNotEmpty) {
        unselected.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }

      return CustomScrollView(
        slivers: [
          // Action bar: "Select all" on the left, "Clear all" on the right.
          // Always rendered so the layout doesn't shift as items are selected.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (unselected.isNotEmpty)
                    InkWell(
                      onTap: onSelectAll,
                      child: const Text(
                        'Select all',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (selected.isNotEmpty)
                    InkWell(
                      onTap: onClearAll,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          // Selected items + divider (only when something is selected).
          if (selected.isNotEmpty)
            SliverList(
              delegate: SliverChildListDelegate([
                ...selectedList.map((item) => _buildItem(item, true)),
                const Divider(height: 1),
              ]),
            ),
          // Unselected choices: SliverFixedExtentList gives O(1) scroll
          // position calculation — no layout work for off-screen items.
          SliverFixedExtentList(
            itemExtent: _itemHeight,
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildItem(unselected[i], false),
              childCount: unselected.length,
            ),
          ),
        ],
      );
    });
  }
}
