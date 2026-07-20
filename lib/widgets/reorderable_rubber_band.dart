import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_selection_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';

/// ラバーバンド（矩形ドラッグ）選択の設定。
class RubberBandConfiguration {
  /// ラバーバンド矩形のデコレーション。
  ///
  /// null の場合はデフォルトの半透明青矩形が使用される。
  final BoxDecoration? decoration;

  /// デスクトップ環境でのみ有効にするか。
  ///
  /// true の場合、モバイル環境（Android / iOS）ではラバーバンドが無効化される。
  /// Default: true
  final bool desktopOnly;

  const RubberBandConfiguration({
    this.decoration,
    this.desktopOnly = true,
  });
}

/// ラバーバンド選択のオーバーレイウィジェット。
///
/// [ReorderableBuilder] と組み合わせて使用する。
/// [ReorderableBuilder] の内部に配置する場合と、ページレベルに配置する場合の
/// 両方に対応する。
///
/// ページレベルに配置する場合は [gridKey] を指定する。
/// [gridKey] は [ReorderableBuilder] が返す GridView の `key` と同一のものを渡す。
/// これにより、ラバーバンドのローカル座標をグリッドのローカル座標に変換して
/// ヒットテストを行う。
///
/// ## ページレベルでの使用例
///
/// ```dart
/// final _gridKey = GlobalKey();
/// final _selectionController = ReorderableSelectionController();
///
/// Stack(
///   children: [
///     // コンテンツ
///     Padding(
///       padding: EdgeInsets.all(16),
///       child: ReorderableBuilder(
///         selectionController: _selectionController,
///         children: children,
///         builder: (children) => GridView(
///           key: _gridKey,
///           children: children,
///         ),
///       ),
///     ),
///     // ラバーバンドオーバーレイ（ページ全体をカバー）
///     ReorderableRubberBand(
///       selectionController: _selectionController,
///       gridKey: _gridKey,
///       getScrollOffset: () => scrollOffset,
///       getChildrenKeyMap: () => childrenKeyMap,
///     ),
///   ],
/// )
/// ```
class ReorderableRubberBand extends StatefulWidget {
  /// 選択状態を管理するController。
  final ReorderableSelectionController selectionController;

  /// ラバーバンド設定。
  final RubberBandConfiguration configuration;

  /// 現在のスクロールオフセットを取得するコールバック。
  final Offset Function() getScrollOffset;

  /// 全アイテムの [ReorderableEntity] マップを取得するコールバック。
  final Map<dynamic, ReorderableEntity> Function() getChildrenKeyMap;

  /// ラバーバンドによる選択開始時に呼ばれるコールバック。
  final void Function(Set<Key> selectedKeys)? onSelectionChanged;

  /// ドラッグ中かどうか（リオーダードラッグ中はラバーバンドを無効化）。
  final bool isDragging;

  /// 選択不可のインデックス。
  final List<int> lockedIndices;

  /// 選択不可の述語。
  final bool Function(int index)? disabledSelectionPredicate;

  /// グリッドの GlobalKey。
  ///
  /// ページレベルに配置する場合に指定する。
  /// ラバーバンドのローカル座標をこの Key の RenderBox 座標系に変換して
  /// アイテムとのヒットテストを行う。
  ///
  /// null の場合は自身のローカル座標をそのまま使用する
  /// （[ReorderableBuilder] 内部に配置するケース）。
  final GlobalKey? gridKey;

  const ReorderableRubberBand({
    required this.selectionController,
    required this.getScrollOffset,
    required this.getChildrenKeyMap,
    this.configuration = const RubberBandConfiguration(),
    this.isDragging = false,
    this.onSelectionChanged,
    this.lockedIndices = const [],
    this.disabledSelectionPredicate,
    this.gridKey,
    super.key,
  });

  @override
  State<ReorderableRubberBand> createState() => _ReorderableRubberBandState();
}

class _ReorderableRubberBandState extends State<ReorderableRubberBand> {
  /// ラバーバンドの開始位置（自身のローカル座標）。
  Offset? _bandStartLocal;

  /// ラバーバンドの終了位置（自身のローカル座標）。
  Offset? _bandEndLocal;

  /// ラバーバンド開始前の選択状態（Ctrl/Cmd + ドラッグ時の追加選択用）。
  Set<Key> _selectionBeforeBand = {};

  /// Ctrl/Cmd が押されているかどうか。
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

  bool get _isMacOS {
    try {
      return Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// デスクトップ環境かどうか。
  bool get _isDesktop {
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// ラバーバンドが有効かどうか。
  bool get _isEnabled {
    if (widget.isDragging) return false;
    if (widget.configuration.desktopOnly && !_isDesktop) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // ジェスチャ検出レイヤー
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onPanCancel: _handlePanCancel,
            ),
          ),
          // ラバーバンド矩形描画
          if (_bandStartLocal != null && _bandEndLocal != null)
            _buildBandRect(),
        ],
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    // Ctrl/Cmd が押されている場合、既存の選択を維持して追加選択
    if (_isMultiModifierPressed) {
      _selectionBeforeBand = Set<Key>.from(widget.selectionController.selected);
    } else {
      _selectionBeforeBand = {};
      widget.selectionController.clear();
    }

    setState(() {
      _bandStartLocal = details.localPosition;
      _bandEndLocal = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_bandStartLocal == null) return;

    setState(() {
      _bandEndLocal = details.localPosition;
    });

    _updateSelection();
  }

  void _handlePanEnd(DragEndDetails details) {
    _finishBand();
  }

  void _handlePanCancel() {
    _finishBand();
  }

  void _finishBand() {
    setState(() {
      _bandStartLocal = null;
      _bandEndLocal = null;
    });
    _selectionBeforeBand = {};
  }

  /// 自身のローカル座標をグリッド座標系に変換する。
  ///
  /// [gridKey] が指定されている場合は RenderBox 間の座標変換を行い、
  /// スクロールオフセットを加算してグリッドのコンテンツ座標に変換する。
  /// [gridKey] が null の場合はスクロールオフセットのみ加算する。
  Offset _localToGridContent(Offset localPosition) {
    final scrollOffset = widget.getScrollOffset();
    final gridKey = widget.gridKey;

    if (gridKey != null) {
      final gridRenderBox =
          gridKey.currentContext?.findRenderObject() as RenderBox?;
      final myRenderBox = context.findRenderObject() as RenderBox?;

      if (gridRenderBox != null && myRenderBox != null) {
        // 自身のローカル座標 → グローバル → グリッドのローカル
        final globalPos = myRenderBox.localToGlobal(localPosition);
        final gridLocal = gridRenderBox.globalToLocal(globalPos);
        return gridLocal + scrollOffset;
      }
    }

    // gridKey が未指定または RenderBox が見つからない場合はフォールバック
    return localPosition + scrollOffset;
  }

  /// 現在のラバーバンド矩形内にあるアイテムを選択する。
  void _updateSelection() {
    final startLocal = _bandStartLocal;
    final endLocal = _bandEndLocal;
    if (startLocal == null || endLocal == null) return;

    // ラバーバンドのローカル座標をグリッドコンテンツ座標に変換
    final startGrid = _localToGridContent(startLocal);
    final endGrid = _localToGridContent(endLocal);
    final bandRect = Rect.fromPoints(startGrid, endGrid);

    final hitKeys = _getKeysInRect(bandRect);

    // Ctrl/Cmd + ドラッグの場合は追加選択
    final newSelection = <Key>{..._selectionBeforeBand, ...hitKeys};

    // 効率化: 変更がない場合はスキップ
    final currentSelection = widget.selectionController.selected;
    if (_setEquals(newSelection, currentSelection)) return;

    widget.selectionController.clear();
    if (newSelection.isNotEmpty) {
      widget.selectionController.selectAll(newSelection);
    }
    widget.onSelectionChanged?.call(widget.selectionController.selected);
  }

  /// 矩形 [bandRect] と交差する全アイテムの Key を返す。
  Set<Key> _getKeysInRect(Rect bandRect) {
    final hitKeys = <Key>{};
    final childrenKeyMap = widget.getChildrenKeyMap();

    for (final entry in childrenKeyMap.entries) {
      final entity = entry.value;

      // 選択不可チェック
      final index = entity.updatedOrderId;
      if (widget.lockedIndices.contains(index)) continue;
      if (widget.disabledSelectionPredicate?.call(index) ?? false) continue;

      final itemRect = Rect.fromLTWH(
        entity.updatedOffset.dx,
        entity.updatedOffset.dy,
        entity.size.width,
        entity.size.height,
      );

      if (bandRect.overlaps(itemRect)) {
        hitKeys.add(entity.key);
      }
    }
    return hitKeys;
  }

  /// ラバーバンドの視覚表現を構築する（自身のローカル座標で描画）。
  Widget _buildBandRect() {
    final rect = Rect.fromPoints(_bandStartLocal!, _bandEndLocal!);

    final decoration = widget.configuration.decoration ??
        BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.12),
          border:
              Border.all(color: Colors.blue.withValues(alpha: 0.6), width: 1),
          borderRadius: BorderRadius.circular(2),
        );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: decoration,
        ),
      ),
    );
  }

  bool _setEquals(Set<Key> a, Set<Key> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
