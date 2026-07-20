import 'package:flutter/widgets.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';

/// [ReorderableBuilder] のアイテム情報を外部のラバーバンドウィジェットに公開するController。
///
/// [ReorderableBuilder] の `rubberBandController` パラメータに渡すと、
/// [ReorderableBuilder] が内部の `childrenKeyMap` / `scrollOffset` / `isDragging`
/// を自動的にこのコントローラーに登録する。
///
/// 外部に配置した [ReorderableRubberBand] は、このコントローラー経由で
/// アイテム情報にアクセスできる。
///
/// ## 使用例
///
/// ```dart
/// final _rubberBandController = ReorderableRubberBandController();
/// final _selectionController = ReorderableSelectionController();
/// final _gridKey = GlobalKey();
///
/// // ページ側
/// Stack(
///   children: [
///     Padding(
///       padding: EdgeInsets.all(16),
///       child: ReorderableBuilder(
///         selectionController: _selectionController,
///         rubberBandController: _rubberBandController,
///         children: children,
///         builder: (children) => GridView(
///           key: _gridKey,
///           children: children,
///         ),
///       ),
///     ),
///     ReorderableRubberBand(
///       selectionController: _selectionController,
///       gridKey: _gridKey,
///       getScrollOffset: () => _rubberBandController.scrollOffset,
///       getChildrenKeyMap: () => _rubberBandController.childrenKeyMap,
///       isDragging: _rubberBandController.isDragging,
///     ),
///   ],
/// )
/// ```
class ReorderableRubberBandController extends ChangeNotifier {
  Map<dynamic, ReorderableEntity> Function()? _getChildrenKeyMap;
  Offset Function()? _getScrollOffset;
  bool Function()? _getIsDragging;

  /// [ReorderableBuilder] が内部情報のゲッターを登録する。
  ///
  /// アプリ側から呼び出す必要はない。
  void attach({
    required Map<dynamic, ReorderableEntity> Function() getChildrenKeyMap,
    required Offset Function() getScrollOffset,
    required bool Function() getIsDragging,
  }) {
    _getChildrenKeyMap = getChildrenKeyMap;
    _getScrollOffset = getScrollOffset;
    _getIsDragging = getIsDragging;
  }

  /// [ReorderableBuilder] が破棄される時に登録を解除する。
  void detach() {
    _getChildrenKeyMap = null;
    _getScrollOffset = null;
    _getIsDragging = null;
  }

  /// 現在のアイテムマップ。
  ///
  /// Key は各アイテムの ValueKey.value、Value は [ReorderableEntity]。
  Map<dynamic, ReorderableEntity> get childrenKeyMap {
    return _getChildrenKeyMap?.call() ?? {};
  }

  /// 現在のスクロールオフセット。
  Offset get scrollOffset {
    return _getScrollOffset?.call() ?? Offset.zero;
  }

  /// リオーダードラッグ中かどうか。
  bool get isDragging {
    return _getIsDragging?.call() ?? false;
  }
}
