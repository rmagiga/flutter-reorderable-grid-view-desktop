import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/auto_scroller.dart';
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
/// ## 自動スクロール（Cooperative パターン）
///
/// [scrollController] が指定された場合、ラバーバンドドラッグ中にビューポート端に
/// 近付くと自動スクロールが有効になる。ScrollController の所有権は利用側にあり、
/// ライブラリはドラッグ中のみ協調的にスクロールを制御する。
///
/// [scrollController] が null の場合、自動スクロールは無効。
/// ラバーバンド選択自体は動作するが、画面外のアイテムは選択できない。
///
/// ## ページレベルでの使用例
///
/// ```dart
/// final _gridKey = GlobalKey();
/// final _scrollController = ScrollController();
/// final _selectionController = ReorderableSelectionController();
///
/// Stack(
///   children: [
///     // コンテンツ
///     Padding(
///       padding: EdgeInsets.all(16),
///       child: ReorderableBuilder(
///         selectionController: _selectionController,
///         scrollController: _scrollController,
///         children: children,
///         builder: (children) => GridView(
///           key: _gridKey,
///           controller: _scrollController,
///           children: children,
///         ),
///       ),
///     ),
///     // ラバーバンドオーバーレイ（ページ全体をカバー）
///     ReorderableRubberBand(
///       selectionController: _selectionController,
///       scrollController: _scrollController,
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

  /// GridView の ScrollController。
  ///
  /// 指定された場合、ラバーバンドドラッグ中にビューポート端に近付くと
  /// 自動スクロールが有効になる。また、スクロール位置の変化を監視して
  /// 選択矩形をリアルタイムに更新する。
  ///
  /// null の場合、自動スクロールとスクロール追従は無効。
  final ScrollController? scrollController;

  /// 外部から注入する [AutoScroller]。
  ///
  /// [ReorderableBuilder] が共有の AutoScroller を持つ場合に使用する。
  /// null の場合は内部で生成する。
  final AutoScroller? autoScroller;

  /// 自動スクロールのエッジしきい値。
  ///
  /// ビューポート端からこの距離以内にドラッグが来ると自動スクロールが開始される。
  /// Default: 80.0
  final double autoScrollEdgeThreshold;

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
    this.scrollController,
    this.autoScroller,
    this.autoScrollEdgeThreshold = 80.0,
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

  /// ラバーバンドドラッグ中に一度でも矩形内に入ったキーの累積セット。
  ///
  /// スクロールにより [childrenKeyMap] から一時的に消えたアイテムの
  /// 選択が外れるのを防ぐ。
  Set<Key> _hitKeysDuringBand = {};

  /// ラバーバンド開始時のスクロールオフセット。
  ///
  /// スクロールが発生した場合にラバーバンドの描画位置をコンテンツに追従させるため、
  /// 開始時のスクロール位置を記録する。
  Offset _scrollOffsetAtBandStart = Offset.zero;

  /// 内部で生成した AutoScroller（外部注入されなかった場合のみ使用）。
  AutoScroller? _internalAutoScroller;

  /// ラバーバンドドラッグ中かどうか。
  bool _isBandDragging = false;

  /// 使用する AutoScroller のインスタンス。
  AutoScroller? get _autoScroller {
    if (widget.autoScroller != null) return widget.autoScroller;
    return _internalAutoScroller;
  }

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

  /// 自動スクロールが利用可能かどうか。
  bool get _isAutoScrollAvailable {
    return widget.scrollController != null || widget.autoScroller != null;
  }

  /// パン開始位置が選択済みアイテム上にあるかどうかを判定する。
  ///
  /// 選択済みアイテム上でラバーバンドが開始されるとドラッグ操作と競合するため、
  /// この場合はラバーバンドの開始をスキップする。
  bool _isOnSelectedItem(Offset localPosition) {
    final selectedKeys = widget.selectionController.selected;
    if (selectedKeys.isEmpty) return false;

    final childrenKeyMap = widget.getChildrenKeyMap();

    // ローカル座標をグリッドコンテンツ座標に変換
    final contentPosition = _localToGridContent(localPosition);

    for (final entity in childrenKeyMap.values) {
      if (!selectedKeys.contains(entity.key)) continue;
      if (entity.size.width <= 0 || entity.size.height <= 0) continue;

      final itemRect = Rect.fromLTWH(
        entity.updatedOffset.dx,
        entity.updatedOffset.dy,
        entity.size.width,
        entity.size.height,
      );

      if (itemRect.contains(contentPosition)) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _setupAutoScroller();
  }

  @override
  void didUpdateWidget(covariant ReorderableRubberBand oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ScrollController が差し替わった場合
    if (widget.scrollController != oldWidget.scrollController &&
        widget.autoScroller == null) {
      _internalAutoScroller?.updateController(widget.scrollController);
    }
  }

  @override
  void dispose() {
    _internalAutoScroller?.detach();
    super.dispose();
  }

  /// AutoScroller の初期化。
  void _setupAutoScroller() {
    if (widget.autoScroller != null) return; // 外部注入の場合は何もしない
    if (widget.scrollController == null) return; // ScrollController なしでは不要

    _internalAutoScroller = AutoScroller(
      edgeThreshold: widget.autoScrollEdgeThreshold,
      onScrollChanged: _handleAutoScrollChanged,
    );
    _internalAutoScroller!.attach(widget.scrollController);
  }

  /// AutoScroller によるスクロール位置変化時のハンドラ。
  ///
  /// ドラッグ中のみ選択矩形を再計算する。
  void _handleAutoScrollChanged() {
    if (!_isBandDragging) return;
    _updateSelection(allowDeselect: true);
    // スクロールに伴い UI を更新（ラバーバンド描画位置が変わる）
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // ジェスチャ検出レイヤー（カスタム Recognizer で Arena 参加前にフィルタリング）
          Positioned.fill(
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: <Type, GestureRecognizerFactory>{
                _RubberBandPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        _RubberBandPanGestureRecognizer>(
                  () => _RubberBandPanGestureRecognizer(
                    canStartBand: _canStartBand,
                  ),
                  (_RubberBandPanGestureRecognizer instance) {
                    instance
                      ..canStartBand = _canStartBand
                      ..onStart = _handlePanStart
                      ..onUpdate = _handlePanUpdate
                      ..onEnd = _handlePanEnd
                      ..onCancel = _handlePanCancel;
                  },
                ),
              },
            ),
          ),
          // ラバーバンド矩形描画
          if (_bandStartLocal != null && _bandEndLocal != null)
            _buildBandRect(),
        ],
      ),
    );
  }

  /// PointerDown 位置でラバーバンドを開始可能かを判定する。
  ///
  /// Gesture Arena に参加する前にフィルタリングするため、
  /// ドラッグハンドルの Recognizer と競合しない。
  bool _canStartBand(Offset globalPosition) {
    // 自身の RenderBox でグローバル座標をローカル座標に変換
    final myRenderBox = context.findRenderObject() as RenderBox?;
    if (myRenderBox == null) return true;

    final localPosition = myRenderBox.globalToLocal(globalPosition);
    return !_isOnSelectedItem(localPosition);
  }

  void _handlePanStart(DragStartDetails details) {
    // Ctrl/Cmd が押されている場合、既存の選択を維持して追加選択
    if (_isMultiModifierPressed) {
      _selectionBeforeBand = Set<Key>.from(widget.selectionController.selected);
    } else {
      _selectionBeforeBand = {};
      widget.selectionController.clear();
    }

    _isBandDragging = true;
    _hitKeysDuringBand = {};
    _scrollOffsetAtBandStart = widget.getScrollOffset();

    setState(() {
      _bandStartLocal = details.localPosition;
      _bandEndLocal = details.localPosition;
    });

    // 自動スクロール開始
    _startAutoScroll();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_bandStartLocal == null) return;

    setState(() {
      _bandEndLocal = details.localPosition;
    });

    // AutoScroller にドラッグ位置を通知（ビューポート座標系に変換）
    if (_isAutoScrollAvailable) {
      final viewportPosition = _toViewportPosition(details.localPosition);
      _autoScroller?.updateDragPosition(viewportPosition);
    }

    // ユーザーがマウスを動かした場合は選択解除も許可
    _updateSelection(allowDeselect: true);
  }

  void _handlePanEnd(DragEndDetails details) {
    _finishBand();
  }

  void _handlePanCancel() {
    _finishBand();
  }

  void _finishBand() {
    _isBandDragging = false;
    _autoScroller?.stop();

    setState(() {
      _bandStartLocal = null;
      _bandEndLocal = null;
    });
    _selectionBeforeBand = {};
    _hitKeysDuringBand = {};
  }

  /// 自動スクロールを開始する。
  void _startAutoScroll() {
    if (!_isAutoScrollAvailable) return;

    final viewportSize = _getGridViewportSize();
    if (viewportSize == null) return;

    _autoScroller?.start(
      viewportSize: viewportSize,
      scrollDirection: Axis.vertical,
    );
  }

  /// ドラッグ位置をビューポート座標系に変換する。
  ///
  /// ラバーバンドがページレベルに配置されている場合、gridKey の RenderBox を基準に
  /// ビューポート座標に変換する。
  Offset _toViewportPosition(Offset localPosition) {
    final gridKey = widget.gridKey;

    if (gridKey != null) {
      final gridRenderBox =
          gridKey.currentContext?.findRenderObject() as RenderBox?;
      final myRenderBox = context.findRenderObject() as RenderBox?;

      if (gridRenderBox != null && myRenderBox != null) {
        final globalPos = myRenderBox.localToGlobal(localPosition);
        return gridRenderBox.globalToLocal(globalPos);
      }
    }

    return localPosition;
  }

  /// GridView のビューポートサイズを取得する。
  Size? _getGridViewportSize() {
    final gridKey = widget.gridKey;

    if (gridKey != null) {
      final gridRenderBox =
          gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (gridRenderBox != null) {
        return gridRenderBox.size;
      }
    }

    // gridKey がない場合は自身のサイズを使用
    final myRenderBox = context.findRenderObject() as RenderBox?;
    return myRenderBox?.size;
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

  /// 自身のローカル座標を指定されたスクロールオフセットでグリッドコンテンツ座標に変換する。
  ///
  /// [_localToGridContent] と同様だが、現在のスクロールオフセットではなく
  /// 引数で指定した [scroll] を使用する。
  /// ラバーバンド開始点のように「開始時のスクロール位置」で固定すべき場合に使う。
  Offset _localToGridContentWithScroll(Offset localPosition, Offset scroll) {
    final gridKey = widget.gridKey;

    if (gridKey != null) {
      final gridRenderBox =
          gridKey.currentContext?.findRenderObject() as RenderBox?;
      final myRenderBox = context.findRenderObject() as RenderBox?;

      if (gridRenderBox != null && myRenderBox != null) {
        final globalPos = myRenderBox.localToGlobal(localPosition);
        final gridLocal = gridRenderBox.globalToLocal(globalPos);
        return gridLocal + scroll;
      }
    }

    return localPosition + scroll;
  }

  /// 現在のラバーバンド矩形内にあるアイテムを選択する。
  ///
  /// [allowDeselect] が true の場合、矩形外に出たアイテムを累積セットから削除する。
  /// false の場合（スクロールによる呼び出し）は追加のみ行い、既存の選択を維持する。
  ///
  /// スクロールで bandRect のコンテンツ座標が変わると、画面座標上のバンドは
  /// 同じなのにコンテンツ座標での矩形が移動し、以前矩形内だったアイテムが
  /// 矩形外と判定される。これは「ユーザーがバンドを縮小した」のではなく
  /// 「スクロールで表示範囲が変わった」だけなので、選択を外すべきではない。
  void _updateSelection({required bool allowDeselect}) {
    final startLocal = _bandStartLocal;
    final endLocal = _bandEndLocal;
    if (startLocal == null || endLocal == null) return;

    // ラバーバンドのコンテンツ座標を計算。
    // 開始点は「開始時のスクロールオフセット」で変換する（コンテンツ上の固定位置）。
    // 終了点は「現在のスクロールオフセット」で変換する（現在のマウス位置）。
    final startGrid = _localToGridContentWithScroll(
      startLocal,
      _scrollOffsetAtBandStart,
    );
    final endGrid = _localToGridContent(endLocal);
    final bandRect = Rect.fromPoints(startGrid, endGrid);

    final childrenKeyMap = widget.getChildrenKeyMap();

    // 現在 childrenKeyMap に存在するアイテムのうち矩形内にあるものを取得
    final currentHitKeys = _getKeysInRect(bandRect);

    // 累積ヒットセットに追加
    _hitKeysDuringBand.addAll(currentHitKeys);

    // ユーザーがマウスを動かした場合のみ、矩形外のアイテムを選択解除する。
    // 正しい位置情報を持つ（size > 0）アイテムのうち、
    // 確実にバンド矩形外にあるものだけを削除対象とする。
    if (allowDeselect) {
      final keysOutsideBand = <Key>{};
      for (final entity in childrenKeyMap.values) {
        if (entity.size.width > 0 && entity.size.height > 0) {
          final itemRect = Rect.fromLTWH(
            entity.updatedOffset.dx,
            entity.updatedOffset.dy,
            entity.size.width,
            entity.size.height,
          );
          if (!bandRect.overlaps(itemRect)) {
            keysOutsideBand.add(entity.key);
          }
        }
      }
      _hitKeysDuringBand.removeWhere(
        (key) => keysOutsideBand.contains(key),
      );
    }

    // Ctrl/Cmd + ドラッグの場合は追加選択
    final newSelection = <Key>{..._selectionBeforeBand, ..._hitKeysDuringBand};

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
  ///
  /// スクロールが発生した場合、開始点をスクロール差分だけ移動させることで
  /// ラバーバンドがコンテンツに追従する。
  Widget _buildBandRect() {
    // スクロール差分を計算（開始時からどれだけスクロールしたか）
    final currentScrollOffset = widget.getScrollOffset();
    final scrollDelta = currentScrollOffset - _scrollOffsetAtBandStart;

    // 開始点はスクロール差分だけ画面上の位置をずらす（コンテンツ追従）
    final adjustedStart = _bandStartLocal! - scrollDelta;
    final rect = Rect.fromPoints(adjustedStart, _bandEndLocal!);

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

/// ラバーバンド選択専用の [PanGestureRecognizer]。
///
/// [addPointer] の段階で [canStartBand] を評価し、ラバーバンドを開始すべきでない
/// 位置（選択済みアイテム上など）では Gesture Arena に参加しない。
/// これにより、ドラッグハンドルの [ImmediateMultiDragGestureRecognizer] と
/// Arena で競合することを根本的に防ぐ。
class _RubberBandPanGestureRecognizer extends PanGestureRecognizer {
  /// PointerDown のグローバル位置でラバーバンド開始可能かを判定するコールバック。
  ///
  /// false を返した場合、この Recognizer は Gesture Arena に参加しない。
  bool Function(Offset globalPosition) canStartBand;

  _RubberBandPanGestureRecognizer({
    required this.canStartBand,
  });

  @override
  void addPointer(PointerDownEvent event) {
    if (!canStartBand(event.position)) {
      return;
    }
    super.addPointer(event);
  }
}
