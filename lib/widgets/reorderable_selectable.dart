import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_selection_controller.dart';

/// 子要素に選択機能・フォーカス管理・キーボードナビゲーションを付与するウィジェット。
///
/// [enableMultiSelection] が true の場合、以下の操作が有効になります：
///
/// - **クリック**: 単一選択（他の選択は解除）
/// - **Ctrl/Cmd + クリック**: トグル選択
/// - **Shift + クリック**: 範囲選択
/// - **Space / Enter**: フォーカスアイテムの選択トグル
/// - **Escape**: 全選択解除
/// - **Ctrl/Cmd + A**: 全選択（`enableSelectAll` が true の場合）
///
/// macOSでは `Ctrl` の代わりに `Cmd` (Meta) キーが自動的に使用されます。
class ReorderableSelectable extends StatefulWidget {
  /// このアイテムの一意なKey（選択管理に使用）
  final Key itemKey;

  /// このアイテムのインデックス
  final int index;

  /// 選択状態を管理するController
  final ReorderableSelectionController selectionController;

  /// このアイテムが現在選択されているか
  final bool isSelected;

  /// このアイテムが選択不可か（lockedIndices や disabledSelectionPredicate による）
  final bool isSelectionDisabled;

  /// 複数選択機能が有効か
  final bool enableMultiSelection;

  /// Ctrl+A による全選択を有効にするか
  final bool enableSelectAll;

  /// Shift+クリックの範囲選択に使用する全キーの順序付きリスト
  final List<Key> allKeys;

  /// 選択状態が変化した時のコールバック
  final void Function(Set<Key> selectedKeys)? onSelectionChanged;

  /// 選択されたアイテムに適用するデコレーション（selectedBuilder が null の場合に使用）
  final BoxDecoration? selectedDecoration;

  /// 選択されたアイテムのカスタムビルダー（selectedDecoration より優先）
  final Widget Function(BuildContext context, Widget child, bool isSelected)?
      selectedBuilder;

  /// 表示する子ウィジェット
  final Widget child;

  /// GestureDetector によるタップジェスチャーの検知を有効にするか（子が独自にタップ/ダブルタップを処理する場合は false に設定する）
  final bool enableTapGesture;

  const ReorderableSelectable({
    required this.itemKey,
    required this.index,
    required this.selectionController,
    required this.isSelected,
    required this.isSelectionDisabled,
    required this.enableMultiSelection,
    required this.enableSelectAll,
    required this.allKeys,
    required this.child,
    this.enableTapGesture = true,
    this.onSelectionChanged,
    this.selectedDecoration,
    this.selectedBuilder,
    super.key,
  });

  @override
  State<ReorderableSelectable> createState() => _ReorderableSelectableState();
}

class _ReorderableSelectableState extends State<ReorderableSelectable> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// macOS では Meta (Cmd) キー、その他のプラットフォームでは Control キー
  bool get _isMultiModifierPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (_isMacOS) {
      return keys.contains(LogicalKeyboardKey.metaLeft) ||
          keys.contains(LogicalKeyboardKey.metaRight);
    } else {
      return keys.contains(LogicalKeyboardKey.controlLeft) ||
          keys.contains(LogicalKeyboardKey.controlRight);
    }
  }

  bool get _isShiftPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }

  bool get _isMacOS {
    try {
      return Platform.isMacOS;
    } catch (_) {
      // Web環境など Platform が使用できない場合は false
      return false;
    }
  }

  void _handleTap() {
    if (!widget.enableMultiSelection || widget.isSelectionDisabled) return;

    debugPrint(
      '[ReorderableSelectable] _handleTap 実行: itemKey=${widget.itemKey}, shift=$_isShiftPressed, multi=$_isMultiModifierPressed',
    );

    _focusNode.requestFocus();
    final controller = widget.selectionController;

    if (_isShiftPressed) {
      // Shift+クリック: 範囲選択
      final lastKey = controller.lastSelectedKey;
      if (lastKey != null && lastKey != widget.itemKey) {
        controller.selectRange(
          startKey: lastKey,
          endKey: widget.itemKey,
          allKeys: widget.allKeys,
        );
      } else {
        controller.select(widget.itemKey);
      }
    } else if (_isMultiModifierPressed) {
      // Ctrl/Cmd+クリック: トグル選択
      controller.toggle(widget.itemKey);
    } else {
      // 通常クリック: 単一選択（他を解除）
      controller.clear();
      controller.select(widget.itemKey);
    }

    widget.onSelectionChanged?.call(controller.selected);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enableMultiSelection) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final controller = widget.selectionController;
    final logicalKey = event.logicalKey;

    // Escape: 全選択解除
    if (logicalKey == LogicalKeyboardKey.escape) {
      controller.clear();
      widget.onSelectionChanged?.call(controller.selected);
      return KeyEventResult.handled;
    }

    // Ctrl/Cmd + A: 全選択
    if (widget.enableSelectAll &&
        _isMultiModifierPressed &&
        logicalKey == LogicalKeyboardKey.keyA) {
      controller.selectAll(widget.allKeys);
      widget.onSelectionChanged?.call(controller.selected);
      return KeyEventResult.handled;
    }

    // Space / Enter: フォーカスアイテムの選択トグル
    if (logicalKey == LogicalKeyboardKey.space ||
        logicalKey == LogicalKeyboardKey.enter) {
      if (!widget.isSelectionDisabled) {
        controller.toggle(widget.itemKey);
        widget.onSelectionChanged?.call(controller.selected);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildChild(BuildContext context) {
    final child = widget.child;
    final isSelected = widget.isSelected;

    // selectedBuilder が優先
    final customBuilder = widget.selectedBuilder;
    if (customBuilder != null) {
      return customBuilder(context, child, isSelected);
    }

    // selectedDecoration を適用
    final decoration = widget.selectedDecoration;
    if (decoration != null && isSelected) {
      return DecoratedBox(
        decoration: decoration,
        child: child,
      );
    }

    // デフォルト: 選択時のデコレーション
    if (isSelected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 2.0,
          ),
        ),
        child: child,
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableMultiSelection) {
      return widget.child;
    }

    final childContent = _buildChild(context);

    return Focus(
      focusNode: _focusNode,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.enableTapGesture
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: childContent,
            )
          : childContent,
    );
  }
}
