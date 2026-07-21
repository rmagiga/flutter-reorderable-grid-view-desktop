import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_animation_config.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/custom_draggable.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/draggable_feedback.dart';

/// Enables drag and drop behaviour for [child].
///
/// Important methods: [onCreated] and [onBuilding].
///
/// [onCreated] is called after widget was built to return [_globalKey]
/// for calculating position and size.
///
/// [onBuilding] is always called if [isBuilding] of [reorderableEntity] is true.
/// That means, that there was an update in the position, usually a new position.
class ReorderableDraggable extends StatefulWidget {
  final Widget child;
  final ReorderableEntity reorderableEntity;
  final bool enableLongPress;
  final Duration longPressDelay;
  final bool enableDraggable;
  final double feedbackScaleFactor;
  final BoxDecoration? dragChildBoxDecoration;
  final ReorderableAnimationConfig animationConfig;

  final VoidCallback onDragStarted;
  final void Function(Offset? globalOffset) onDragEnd;
  final VoidCallback onDragCanceled;

  final ReorderableEntity? currentDraggedEntity;
  final bool isGhost;
  final int draggedSelectedCount;
  final bool buildDefaultDragHandles;

  const ReorderableDraggable({
    required this.child,
    required this.reorderableEntity,
    required this.enableLongPress,
    required this.longPressDelay,
    required this.enableDraggable,
    required this.feedbackScaleFactor,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragCanceled,
    required this.currentDraggedEntity,
    required this.animationConfig,
    this.dragChildBoxDecoration,
    this.isGhost = false,
    this.draggedSelectedCount = 0,
    this.buildDefaultDragHandles = true,
    Key? key,
  }) : super(key: key);

  @override
  State<ReorderableDraggable> createState() => ReorderableDraggableState();
}

class ReorderableDraggableState extends State<ReorderableDraggable>
    with TickerProviderStateMixin {
  late final AnimationController _decoratedBoxAnimationController;
  late final DecorationTween _decorationTween;

  bool isDragging = false;
  final _draggableFeedbackGlobalKey = GlobalKey();
  RenderBox? _dragHandleRenderBox;

  /// Default [BoxDecoration] for dragged child.
  final _defaultBoxDecoration = BoxDecoration(
    boxShadow: <BoxShadow>[
      BoxShadow(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(0.2),
        spreadRadius: 5,
        blurRadius: 6,
        offset: const Offset(0, 3), // changes position of shadow
      ),
    ],
  );

  @override
  void initState() {
    super.initState();

    _decoratedBoxAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    final beginDragBoxDecoration = widget.dragChildBoxDecoration?.copyWith(
      color: Colors.transparent,
      boxShadow: [],
    );
    _decorationTween = DecorationTween(
      begin: beginDragBoxDecoration ?? const BoxDecoration(),
      end: widget.dragChildBoxDecoration ?? _defaultBoxDecoration,
    );
  }

  void registerDragHandle(RenderBox? renderBox) {
    _dragHandleRenderBox = renderBox;
  }

  bool _shouldStartDrag(Offset globalPosition) {
    if (widget.buildDefaultDragHandles) {
      return true;
    }
    if (_dragHandleRenderBox == null) {
      return false;
    }
    if (!_dragHandleRenderBox!.attached) {
      return false;
    }

    try {
      final localPosition = _dragHandleRenderBox!.globalToLocal(globalPosition);
      final size = _dragHandleRenderBox!.size;
      final allowed = localPosition.dx >= 0 &&
          localPosition.dy >= 0 &&
          localPosition.dx <= size.width &&
          localPosition.dy <= size.height;
      return allowed;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _decoratedBoxAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reorderableEntity = widget.reorderableEntity;
    var child = widget.child;

    Widget feedbackChild = child;
    if (widget.draggedSelectedCount > 1) {
      feedbackChild = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Center(
                child: Text(
                  '+${widget.draggedSelectedCount - 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final feedback = DraggableFeedback(
      key: _draggableFeedbackGlobalKey,
      size: reorderableEntity.size,
      decoration: _decorationTween.animate(_decoratedBoxAnimationController),
      feedbackScaleFactor: widget.feedbackScaleFactor,
      animationConfig: widget.animationConfig,
      onDeactivate: widget.onDragCanceled,
      child: feedbackChild,
    );

    final currentDraggedEntity = widget.currentDraggedEntity;
    final updatedOrderId = reorderableEntity.updatedOrderId;
    final visible = (currentDraggedEntity?.updatedOrderId != updatedOrderId) &&
        !widget.isGhost;

    final data = _getData();

    if (!widget.enableDraggable) {
      return child;
    }

    late final Widget draggable;

    if (widget.buildDefaultDragHandles) {
      // if delay is Duration.zero, LongPressDraggable breaks onTap for [child]
      if (!widget.enableLongPress || widget.longPressDelay == Duration.zero) {
        draggable = Draggable(
          onDragStarted: _handleDragStarted,
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            _handleDragEnd(offset);
          },
          onDragCompleted: _handleDragCompleted,
          feedback: feedback,
          data: data,
          child: child,
        );
      } else {
        draggable = LongPressDraggable(
          delay: widget.longPressDelay,
          onDragStarted: _handleDragStarted,
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            _handleDragEnd(offset);
          },
          onDragCompleted: _handleDragCompleted,
          feedback: feedback,
          data: data,
          child: child,
        );
      }
    } else {
      // ドラッグハンドル使用時は、親が長押し設定であってもハンドルを掴んだ瞬間に即時ドラッグを開始させる
      draggable = _CustomDraggable(
        shouldStartDrag: _shouldStartDrag,
        onDragStarted: _handleDragStarted,
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          _handleDragEnd(offset);
        },
        onDragCompleted: _handleDragCompleted,
        feedback: feedback,
        data: data,
        child: child,
      );
    }

    return ReorderableDraggableProvider(
      state: this,
      child: Visibility(
        visible: visible,
        maintainAnimation: true,
        maintainSize: true,
        maintainState: true,
        child: widget.currentDraggedEntity != null ? child : draggable,
      ),
    );
  }

  /// Called after dragging started.
  void _handleDragStarted() {
    isDragging = true;
    widget.onDragStarted();
    _decoratedBoxAnimationController.forward();
  }

  /// Called when the draggable is dropped and accepted by a [DragTarget].
  ///
  /// This callback doesn't receive any positions which means that the position
  /// will be calculated throughout the [DraggableFeedback].
  void _handleDragCompleted() {
    Offset? offset;

    final currentContext = _draggableFeedbackGlobalKey.currentContext;
    final renderBox = currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      offset = renderBox.localToGlobal(Offset.zero);
    }

    _handleDragEnd(offset);
  }

  /// Called after dragging ends.
  ///
  /// Important: This can also be called after the widget was disposed but
  /// is still dragged. This has to be done to finish the drag and drop.
  void _handleDragEnd(Offset? offset) {
    if (mounted) {
      isDragging = false;
      _decoratedBoxAnimationController.reset();
    }

    widget.onDragEnd(offset);
  }

  Object? _getData() {
    final child = widget.child;

    if (child is CustomDraggable) {
      return child.data;
    } else {
      return null;
    }
  }
}

class ReorderableDraggableProvider extends InheritedWidget {
  final ReorderableDraggableState state;

  const ReorderableDraggableProvider({
    required this.state,
    required super.child,
    super.key,
  });

  static ReorderableDraggableState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ReorderableDraggableProvider>()
        ?.state;
  }

  @override
  bool updateShouldNotify(ReorderableDraggableProvider oldWidget) => true;
}

class _CustomDraggable extends Draggable {
  final bool Function(Offset position) shouldStartDrag;

  const _CustomDraggable({
    required this.shouldStartDrag,
    required super.child,
    required super.feedback,
    super.data,
    super.onDragStarted,
    super.onDraggableCanceled,
    super.onDragCompleted,
  });

  @override
  ImmediateMultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) {
    final recognizer = _CustomImmediateMultiDragGestureRecognizer(
      shouldStartDrag: shouldStartDrag,
      debugOwner: this,
    );
    recognizer.onStart = onStart;
    return recognizer;
  }
}

class _CustomImmediateMultiDragGestureRecognizer
    extends ImmediateMultiDragGestureRecognizer {
  final bool Function(Offset position) shouldStartDrag;

  _CustomImmediateMultiDragGestureRecognizer({
    required this.shouldStartDrag,
    super.debugOwner,
  });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final allowed = shouldStartDrag(event.position);
    if (allowed) {
      super.addAllowedPointer(event);
    }
  }
}
