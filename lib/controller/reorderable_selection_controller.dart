import 'dart:collection';

import 'package:flutter/cupertino.dart';

/// GridView内の子要素の選択状態を管理するController。
///
/// [TextEditingController] や [ScrollController] と同じパターンで使用します。
/// [ReorderableBuilder] の `selectionController` パラメータに渡してください。
///
/// `selectionController` を渡さない場合、[ReorderableBuilder] が内部で自動生成します
/// （Uncontrolled モード）。
///
/// ## 使用例
///
/// ```dart
/// final controller = ReorderableSelectionController();
///
/// ReorderableBuilder(
///   selectionController: controller,
///   // ...
/// )
///
/// // 外部からの操作
/// controller.selectAll(allKeys);
/// controller.clear();
/// print(controller.selected); // 現在の選択セット
/// ```
class ReorderableSelectionController extends ChangeNotifier {
  final _selected = <Key>{};
  Key? _lastSelectedKey;

  /// 現在選択されている [Key] のセット（読み取り専用）。
  Set<Key> get selected => UnmodifiableSetView(_selected);

  /// Shift+クリックの起点となる、最後に選択した [Key]。
  ///
  /// 単一選択やCtrl/Cmd+クリック時に更新されます。
  /// 範囲選択（Shift+クリック）では更新されません。
  Key? get lastSelectedKey => _lastSelectedKey;

  /// [key] が現在選択されているか判定します。
  bool isSelected(Key key) => _selected.contains(key);

  /// [key] を選択します。既に選択されている場合は何もしません。
  void select(Key key) {
    if (_selected.add(key)) {
      _lastSelectedKey = key;
      notifyListeners();
    }
  }

  /// [key] の選択を解除します。選択されていない場合は何もしません。
  void deselect(Key key) {
    if (_selected.remove(key)) {
      if (_lastSelectedKey == key) {
        _lastSelectedKey = _selected.isEmpty ? null : _selected.last;
      }
      notifyListeners();
    }
  }

  /// [key] の選択状態をトグルします。
  ///
  /// 選択されていれば解除し、されていなければ選択します。
  void toggle(Key key) {
    if (_selected.contains(key)) {
      deselect(key);
    } else {
      select(key);
    }
  }

  /// [keys] 内のすべての [Key] を選択します。
  ///
  /// 既に選択されているものは変更しません。
  void selectAll(Iterable<Key> keys) {
    final before = _selected.length;
    _selected.addAll(keys);
    if (_selected.length != before) {
      notifyListeners();
    }
  }

  /// [startKey] から [endKey] までの範囲を選択します。
  ///
  /// [allKeys] は現在のGridViewに表示されている全Keyの順序付きリストです。
  /// Shift+クリック時に使用します。
  void selectRange({
    required Key startKey,
    required Key endKey,
    required List<Key> allKeys,
  }) {
    final startIndex = allKeys.indexOf(startKey);
    final endIndex = allKeys.indexOf(endKey);

    if (startIndex == -1 || endIndex == -1) return;

    final from = startIndex <= endIndex ? startIndex : endIndex;
    final to = startIndex <= endIndex ? endIndex : startIndex;

    final rangeKeys = allKeys.sublist(from, to + 1);
    _selected.addAll(rangeKeys);
    notifyListeners();
  }

  /// 全ての選択を解除します。
  void clear() {
    if (_selected.isNotEmpty) {
      _selected.clear();
      _lastSelectedKey = null;
      notifyListeners();
    }
  }

  /// [ReorderableBuilder] がリオーダー完了後にキーのマッピングを更新するために呼び出します。
  ///
  /// Keyベースの管理のため、通常はリオーダー後も選択状態は自動的に維持されます。
  /// このメソッドは、削除されたアイテムのキーを選択セットから取り除くために使用します。
  void removeStaleKeys(Set<Key> validKeys) {
    final before = _selected.length;
    _selected.retainAll(validKeys);
    if (_selected.length != before) {
      if (_lastSelectedKey != null && !validKeys.contains(_lastSelectedKey)) {
        _lastSelectedKey = _selected.isEmpty ? null : _selected.last;
      }
      notifyListeners();
    }
  }
}
