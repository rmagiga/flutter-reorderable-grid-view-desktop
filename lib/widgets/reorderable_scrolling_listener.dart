import 'package:flutter/cupertino.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/auto_scroller.dart';

/// ドラッグ中のポインタ移動を検知し、自動スクロール機能を提供する。
///
/// [Listener] でポインタ移動を監視し、[AutoScroller] を利用して
/// ビューポート端に近付いたときに自動スクロールを行う。
class ReorderableScrollingListener extends StatefulWidget {
  /// [child] added to build method.
  final Widget child;

  /// Indicator if the user is using drag and drop.
  final bool isDragging;

  /// Indicator when the scrolling should start.
  ///
  /// The scrolling can be triggered earlier. That means if the dragged item
  /// is almost in the end of the visible area, the scroll would start.
  /// If [automaticScrollExtent] has a higher value, the scroll would start earlier.
  final double automaticScrollExtent;

  /// Enables the functionality to scroll while dragging a child to the top or bottom.
  final bool enableScrollingWhileDragging;

  /// Callback when the offset of the tapped area is changing.
  final PointerMoveEventListener onDragUpdate;

  /// Manages the case where the order of children is reversed.
  final bool reverse;

  /// Should be the key of the added [GridView].
  final GlobalKey? reorderableChildKey;

  /// Should be the [ScrollController] of the [GridView].
  final ScrollController? scrollController;

  /// 外部から注入する [AutoScroller]。
  ///
  /// 指定された場合はこのインスタンスを使用する。
  /// null の場合は内部で生成する（後方互換性のため）。
  final AutoScroller? autoScroller;

  const ReorderableScrollingListener({
    required this.child,
    required this.isDragging,
    required this.enableScrollingWhileDragging,
    required this.automaticScrollExtent,
    required this.reverse,
    required this.onDragUpdate,
    required this.reorderableChildKey,
    required this.scrollController,
    this.autoScroller,
    Key? key,
  }) : super(key: key);

  @override
  State<ReorderableScrollingListener> createState() =>
      _ReorderableScrollingListenerState();
}

class _ReorderableScrollingListenerState
    extends State<ReorderableScrollingListener> {
  /// 内部で生成した AutoScroller（外部注入されなかった場合のみ使用）。
  AutoScroller? _internalAutoScroller;

  /// 使用する AutoScroller のインスタンス。
  AutoScroller get _autoScroller {
    if (widget.autoScroller != null) return widget.autoScroller!;
    return _internalAutoScroller!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoScroller == null) {
      // 内部生成の場合は attach
      _internalAutoScroller = AutoScroller(
        edgeThreshold: widget.automaticScrollExtent,
        reverse: widget.reverse,
      );
      _internalAutoScroller!.attach(widget.scrollController);
    }
  }

  @override
  void didUpdateWidget(covariant ReorderableScrollingListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 内部 AutoScroller の場合のみ Controller 差し替えに対応
    if (widget.autoScroller == null) {
      if (widget.scrollController != oldWidget.scrollController) {
        _internalAutoScroller?.updateController(widget.scrollController);
      }
      _internalAutoScroller?.reverse = widget.reverse;
    }

    if (widget.isDragging != oldWidget.isDragging) {
      if (!widget.isDragging) {
        _autoScroller.stop();
      }
    }
  }

  @override
  void dispose() {
    _internalAutoScroller?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // fix for android release mode, otherwise dragging won't work correctly (since flutter 3.22.0)
      behavior: HitTestBehavior.deferToChild,
      onPointerMove: (details) {
        if (widget.isDragging) {
          _handleDragUpdate(details);
        }
      },
      child: widget.child,
    );
  }

  /// ドラッグ開始時に AutoScroller を起動する。
  void _startAutoScroll() {
    if (!widget.enableScrollingWhileDragging) return;
    if (widget.reorderableChildKey == null) return;

    final viewportSize = _getViewportSize();
    if (viewportSize == null) return;

    final scrollDirection = _getScrollDirection();
    if (scrollDirection == null) return;

    // ScrollController がない場合（outer scrollable パターン）は
    // 親の Scrollable から ScrollPosition を取得して scrollFunction を設定
    if (widget.scrollController == null) {
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;

      _autoScroller.setScrollFunction((delta) {
        final position = scrollable.position;
        final next = (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if (next != position.pixels) {
          position.jumpTo(next);
        }
      });
    }

    _autoScroller.start(
      viewportSize: viewportSize,
      scrollDirection: scrollDirection,
    );
  }

  /// ドラッグ中のポインタ移動ハンドラ。
  void _handleDragUpdate(PointerMoveEvent details) {
    if (widget.enableScrollingWhileDragging &&
        widget.reorderableChildKey != null) {
      // AutoScroller が未起動なら開始する（既存と同じタイミング）
      if (!_autoScroller.isActive) {
        _startAutoScroll();
      }

      // ビューポート座標に変換してから AutoScroller に渡す
      final viewportPosition = _toViewportPosition(details.localPosition);
      _autoScroller.updateDragPosition(viewportPosition);
    }

    widget.onDragUpdate(details);
  }

  /// ポインタ位置をビューポート座標系に変換する。
  Offset _toViewportPosition(Offset localPosition) {
    final childOffset = _getChildOffset();
    return localPosition + childOffset;
  }

  /// GridView ビューポートのサイズを取得する。
  Size? _getViewportSize() {
    final currentContext = widget.reorderableChildKey?.currentContext;
    final renderBox = currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return null;

    // GridView が unbounded（親がスクロール可能）の場合
    if (renderBox.constraints.biggest.isInfinite) {
      final dimension = Scrollable.of(context).position.viewportDimension;
      return Size(dimension, dimension);
    }

    return renderBox.size;
  }

  /// GridView のオフセットを取得する。
  Offset _getChildOffset() {
    final currentContext = widget.reorderableChildKey?.currentContext;
    final renderBox = currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return Offset.zero;

    if (renderBox.constraints.biggest.isInfinite) {
      return renderBox.localToGlobal(Offset.zero);
    }

    return Offset.zero;
  }

  /// スクロール方向を取得する。
  Axis? _getScrollDirection() {
    final controller = widget.scrollController;
    if (controller != null && controller.hasClients) {
      return controller.position.axis;
    }
    return Scrollable.maybeOf(context)?.position.axis;
  }
}
