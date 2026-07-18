import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_builder_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_drag_and_drop_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_item_builder_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_selection_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/released_reorderable_entity.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorder_update_entity.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_animation_config.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';
import 'package:flutter_reorderable_grid_view_desktop/utils/reorderable_scrollable.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/reorderable_builder_item.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/reorderable_scrolling_listener.dart';

typedef DraggableBuilder = Widget Function(
  List<Widget> children,
);

typedef ReorderedListFunction<T> = List<T> Function(List<T>);
typedef OnReorderCallback<T> = void Function(ReorderedListFunction<T>);
typedef OnReorderPositions = void Function(List<ReorderUpdateEntity>);
typedef ItemCallback = void Function(int index);
typedef ChildBuilderFunction = Widget Function(
  Widget Function(Widget child, int index) itemBuilder,
);

/// Enables animated drag and drop behaviour for built widgets in [builder].
///
/// Be sure not to replace, add or remove your children while you are dragging
/// because this can lead to an unexpected behavior.
///
/// The generic type [T] defines the list type after reordering with
/// [ReorderedListFunction] in [onReorder].
class ReorderableBuilder<T> extends StatefulWidget {
  static const _defaultLockedIndices = <int>[];
  static const _defaultNonDraggableIndices = <int>[];
  static const _defaultEnableLongPress = true;
  static const _defaultLongPressDelay = kLongPressTimeout;
  static const _defaultEnableDraggable = true;
  static const _defaultAutomaticScrollExtent = 150.0;
  static const _defaultEnableScrollingWhileDragging = true;
  static const _defaultFeedbackScaleFactor = 1.05;
  static const _defaultReverse = false;
  static const _defaultAnimationConfig = ReorderableAnimationConfig();
  static const _defaultEnableMultiSelection = false;
  static const _defaultEnableSelectAll = true;
  static const _defaultBuildDefaultDragHandles = true;

  /// Defines the children that will be displayed for drag and drop.
  final List<Widget>? children;

  /// Enable support for [GridView.builder] using this function.
  ///
  /// This function allows rendering all children using a builder.
  /// Make sure your [GridView.builder] calls [childBuilder] to return
  /// widgets that support animations and drag-and-drop functionality.
  final ChildBuilderFunction? childBuilder;

  /// Configuration for child animations.
  ///
  /// Includes the durations and curves for fade-in, position change,
  /// released-item movement, and drag feedback.
  final ReorderableAnimationConfig animationConfig;

  /// The length of items that are rendered through [ReorderableBuilder.builder].
  ///
  /// This count ensures that the drag and drop only happens the items in a
  /// valid range and ignores any other item out of this range.
  final int? itemCount;

  /// Specify indices for [children] that should not be draggable or movable.
  ///
  /// If you have e.g. [0, 1, 2], then it means that your [children] on the
  /// first, second and third position cannot be dragged. Furthermore if
  /// you drag and drop, they won't change their position.
  ///
  /// Default value: &lt;int&gt;&#91;&#93;
  final List<int> lockedIndices;

  /// Specify indices for [children] that are not draggable.
  ///
  /// If you have e.g. [3, 4], then it means that your [children] on the
  /// third and fourth cannot be used for dragging.
  /// Compared to [lockedIndices], these [children] can change their position
  /// while dragging.
  ///
  /// Default value: &lt;int&gt;&#91;&#93;
  final List<int> nonDraggableIndices;

  /// The drag of a child will be started with a long press.
  ///
  /// Default value: true
  final bool enableLongPress;

  /// Specify the [Duration] for the pressed child before starting the dragging.
  ///
  /// Default value: kLongPressTimeout
  final Duration longPressDelay;

  /// When disabling draggable, the drag and drop behavior is not working.
  ///
  /// When [enableDraggable] is true, [onReorder] must not be null.
  ///
  /// Default value: true
  final bool enableDraggable;

  /// Enables the functionality to scroll while dragging a child to the top or bottom.
  ///
  /// Combined with the value of [automaticScrollExtent], an automatic scroll starts,
  /// when you drag the child and the widget of [builder] is scrollable.
  ///
  /// Default value: true
  final bool enableScrollingWhileDragging;

  /// Defines the height of the top or bottom before the dragged child indicates a scrolling.
  ///
  /// Default value: 80.0
  final double automaticScrollExtent;

  /// The scale factor applied to the feedback widget during a drag operation.
  ///
  /// This determines how much the feedback widget (the visual representation
  /// of the widget being dragged) will grow or shrink when the drag starts.
  /// A value of 1.0 means no scaling, while a value greater than 1.0 enlarges
  /// the feedback widget.
  /// For example, a value of 1.5 will increase the size by 50%.
  ///
  /// Default value: 1.05 (feedback widget grows by 5%)
  final double feedbackScaleFactor;

  /// Manages the case where the order of [children] is reversed.
  ///
  /// If the [children] list is in reverse order, set this flag to true to ensure
  /// the widget behaves as expected. Failing to update this flag when the
  /// order is reversed will result in incorrect behavior.
  ///
  /// Default value: `false`
  final bool reverse;

  /// [BoxDecoration] for the child that is dragged around.
  final BoxDecoration? dragChildBoxDecoration;

  // --- 複数選択 パラメータ ---

  /// 複数選択機能の有効/無効。
  ///
  /// [selectionController] が渡された場合は自動的に true として扱われます。
  ///
  /// Default: false
  final bool enableMultiSelection;

  /// 選択状態を管理するController。
  ///
  /// [TextEditingController] や [ScrollController] と同じパターンです。
  /// 渡さなければ内部で自動生成します（Uncontrolled モード）。
  /// 渡した場合は外部から選択状態を制御できます（Controlled モード）。
  final ReorderableSelectionController? selectionController;

  /// 選択状態が変化した時のコールバック。
  ///
  /// Controlled / Uncontrolled どちらのモードでも呼ばれます。
  /// 引数は現在選択されている [Key] のセットです。
  final void Function(Set<Key> selectedKeys)? onSelectionChanged;

  /// 選択されたアイテムに適用する [BoxDecoration]。
  ///
  /// [selectedBuilder] が指定されている場合は無視されます。
  /// 未指定の場合はデフォルトの青色ボーダーが適用されます。
  final BoxDecoration? selectedDecoration;

  /// 選択されたアイテムのカスタムビルダー。
  ///
  /// [selectedDecoration] より優先されます。
  /// チェックマーク、バッジ等の自由なカスタマイズが可能です。
  ///
  /// ```dart
  /// selectedBuilder: (context, child, isSelected) {
  ///   return Stack(children: [
  ///     child,
  ///     if (isSelected)
  ///       Positioned(top: 4, right: 4,
  ///         child: Icon(Icons.check_circle, color: Colors.blue)),
  ///   ]);
  /// },
  /// ```
  final Widget Function(BuildContext context, Widget child, bool isSelected)?
      selectedBuilder;

  /// Ctrl/Cmd + A による全選択を有効にするか。
  ///
  /// [enableMultiSelection] が true の場合のみ有効です。
  ///
  /// Default: true
  final bool enableSelectAll;

  /// 特定のアイテムを選択不可にする述語。
  ///
  /// true を返したインデックスのアイテムはクリックしても選択されません。
  /// [lockedIndices] のアイテムも自動的に選択不可になります。
  final bool Function(int index)? disabledSelectionPredicate;

  /// ドラッグハンドル機能を使用するかどうか。
  ///
  /// false に設定した場合、[ReorderableDragStartListener] が配置された
  /// ハンドル部分をドラッグしたときのみドラッグを開始できます。
  final bool buildDefaultDragHandles;

  /// It's required to use [ReorderableBuilder] to obtain updated [children].
  ///
  /// This function returns the [children] containing all necessary widgets
  /// for animations and drag-and-drop functionality. Ensure to use the children
  /// returned by this function for proper integration.
  final DraggableBuilder? builder;

  /// After releasing the dragged child, [onReorder] or [onReorderPositions] is called.
  ///
  /// Ensure [enableDraggable] is set to true for this callback to trigger.
  /// This function takes a [ReorderedListFunction] as a parameter, which will
  /// reorder a list of items. Make sure to pass your list to this function
  /// and cast it afterward to your specific list type.
  /// This mechanism ensures that your list is correctly updated. You can then
  /// use the updated items returned by this function.
  final OnReorderCallback<T>? onReorder;

  /// After releasing the dragged child, [onReorderPositions] is called.
  ///
  /// Ensure [enableDraggable] is set to true for this callback to trigger.
  /// This function returns a list of updated positions
  final OnReorderPositions? onReorderPositions;

  /// Callback when dragging starts with the index where it started.
  ///
  /// Prevent updating your children while you are dragging because this can lead
  /// to an unexpected behavior.
  /// [index] is the position of the child where the dragging started.
  final ItemCallback? onDragStarted;

  /// Callback when the dragged child was released with the index.
  ///
  /// [index] is the position of the child where the dragging ended.
  /// Important: This is called before [onReorder].
  final ItemCallback? onDragEnd;

  /// Called when the dragged child has updated his position while dragging.
  ///
  /// [index] is the new position of the dragged child. While this callback
  /// you should not update your [children] by yourself to ensure a correct
  /// behavior while dragging.
  final ItemCallback? onUpdatedDraggedChild;

  /// [ScrollController] to get the current scroll position. Important for calculations!
  ///
  /// This controller has to be assigned if the returned widget of [builder] is
  /// scrollable. Every [GridView] is scrollable by default.
  ///
  /// You have assign the controller to the [ReorderableBuilder]
  /// and to your [GridView].
  ///
  /// If the scrollable widget is outside [ReorderableBuilder], then you don't
  /// add [scrollController] to this widget because the calculations also works
  /// by using the scroll value in the context.
  final ScrollController? scrollController;

  const ReorderableBuilder({
    required this.children,
    required this.builder,
    this.scrollController,
    this.onReorder,
    this.onReorderPositions,
    this.animationConfig = _defaultAnimationConfig,
    this.lockedIndices = _defaultLockedIndices,
    this.nonDraggableIndices = _defaultNonDraggableIndices,
    @Deprecated("This parameter is no longer needed.\n"
        "To disable the long press and initiate the drag immediately, "
        "set [longPressDelay] to [Duration.zero].")
    this.enableLongPress = _defaultEnableLongPress,
    this.longPressDelay = _defaultLongPressDelay,
    this.enableDraggable = _defaultEnableDraggable,
    this.automaticScrollExtent = _defaultAutomaticScrollExtent,
    this.enableScrollingWhileDragging = _defaultEnableScrollingWhileDragging,
    this.feedbackScaleFactor = _defaultFeedbackScaleFactor,
    this.reverse = _defaultReverse,
    this.dragChildBoxDecoration,
    this.onDragStarted,
    this.onDragEnd,
    this.onUpdatedDraggedChild,
    // 複数選択パラメータ
    this.enableMultiSelection = _defaultEnableMultiSelection,
    this.selectionController,
    this.onSelectionChanged,
    this.selectedDecoration,
    this.selectedBuilder,
    this.enableSelectAll = _defaultEnableSelectAll,
    this.disabledSelectionPredicate,
    this.buildDefaultDragHandles = _defaultBuildDefaultDragHandles,
    Key? key,
  })  : assert((enableDraggable &&
                (onReorder != null || onReorderPositions != null)) ||
            !enableDraggable),
        childBuilder = null,
        itemCount = null,
        super(key: key);

  const ReorderableBuilder.builder({
    required ChildBuilderFunction this.childBuilder,
    required int this.itemCount,
    this.scrollController,
    this.onReorder,
    this.onReorderPositions,
    this.animationConfig = _defaultAnimationConfig,
    this.lockedIndices = _defaultLockedIndices,
    this.nonDraggableIndices = _defaultNonDraggableIndices,
    @Deprecated("This parameter is no longer needed.\n"
        "To disable the long press and initiate the drag immediately, "
        "set [longPressDelay] to [Duration.zero].")
    this.enableLongPress = _defaultEnableLongPress,
    this.longPressDelay = _defaultLongPressDelay,
    this.enableDraggable = _defaultEnableDraggable,
    this.automaticScrollExtent = _defaultAutomaticScrollExtent,
    this.enableScrollingWhileDragging = _defaultEnableScrollingWhileDragging,
    this.feedbackScaleFactor = _defaultFeedbackScaleFactor,
    this.reverse = _defaultReverse,
    this.dragChildBoxDecoration,
    this.onDragStarted,
    this.onDragEnd,
    this.onUpdatedDraggedChild,
    // 複数選択パラメータ
    this.enableMultiSelection = _defaultEnableMultiSelection,
    this.selectionController,
    this.onSelectionChanged,
    this.selectedDecoration,
    this.selectedBuilder,
    this.enableSelectAll = _defaultEnableSelectAll,
    this.disabledSelectionPredicate,
    this.buildDefaultDragHandles = _defaultBuildDefaultDragHandles,
    Key? key,
  })  : assert((enableDraggable &&
                (onReorder != null || onReorderPositions != null)) ||
            !enableDraggable),
        children = null,
        builder = null,
        super(key: key);


  @override
  State<ReorderableBuilder<T>> createState() => _ReorderableBuilderState();
}

class _ReorderableBuilderState<T> extends State<ReorderableBuilder<T>>
    with WidgetsBindingObserver {
  late final ReorderableBuilderController reorderableBuilderController;
  late final ReorderableItemBuilderController reorderableItemBuilderController;

  /// 選択状態を管理するController。
  ///
  /// [widget.selectionController] が指定されていればそれを使用（Controlled）。
  /// 指定されていなければ内部で生成（Uncontrolled）。
  late final ReorderableSelectionController _selectionController;

  /// Uncontrolledモード時に内部で生成したかどうか。
  /// dispose時に内部生成のもののみ廃棄する。
  bool _isInternalSelectionController = false;

  /// ドラッグ終了処理の多重割り込みを防ぐガードフラグ。
  bool _isFinishingDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    reorderableBuilderController = ReorderableBuilderController();
    reorderableItemBuilderController = ReorderableItemBuilderController();

    // SelectionControllerの初期化
    final externalController = widget.selectionController;
    if (externalController != null) {
      // Controlledモード: 外部のControllerを使用
      _selectionController = externalController;
      _isInternalSelectionController = false;
    } else {
      // Uncontrolledモード: 内部で生成
      _selectionController = ReorderableSelectionController();
      _isInternalSelectionController = true;
    }

    // 選択状態変更時にsetStateでUIを再ビルド
    if (widget.enableMultiSelection || widget.selectionController != null) {
      _selectionController.addListener(_handleSelectionChanged);
    }

    final children = widget.children;
    if (children == null) return;
    reorderableBuilderController.initChildren(children: children);
  }

  @override
  void didUpdateWidget(covariant ReorderableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final children = widget.children;
    if (children == null || children == oldWidget.children) return;

    reorderableBuilderController.updateChildren(children: children);
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final orientationBefore = MediaQuery.orientationOf(context);
    final screenSizeBefore = MediaQuery.sizeOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final orientationAfter = MediaQuery.orientationOf(context);
      final screenSizeAfter = MediaQuery.sizeOf(context);

      if (orientationBefore != orientationAfter ||
          screenSizeBefore != screenSizeAfter) {
        _reorderableController.handleDeviceOrientationChanged();
        _reorderableController.scrollOffset == _scrollOffset;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    if (widget.enableMultiSelection || widget.selectionController != null) {
      _selectionController.removeListener(_handleSelectionChanged);
    }
    // Uncontrolledモード時のみ内部コントローラーを廃棄
    if (_isInternalSelectionController) {
      _selectionController.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleSelectionChanged() {
    widget.onSelectionChanged?.call(_selectionController.selected);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    late Widget child;

    final builder = widget.builder;
    if (builder == null) {
      child = widget.childBuilder!(_buildItem);
    } else {
      child = builder(_wrapChildren());
    }

    return ReorderableScrollingListener(
      isDragging: _reorderableController.draggedEntity != null,
      reorderableChildKey: child.key as GlobalKey?,
      scrollController: widget.scrollController,
      automaticScrollExtent: widget.automaticScrollExtent,
      enableScrollingWhileDragging: widget.enableScrollingWhileDragging,
      reverse: widget.reverse,
      onDragUpdate: _handleDragUpdate,
      child: child,
    );
  }

  Widget _buildItem(Widget child, int index) {
    assert(
      child.key is ValueKey,
      'You have to provide a unique ValueKey to every child!',
    );
    final reorderableEntity = reorderableItemBuilderController.buildItem(
      key: child.key as ValueKey,
      index: index,
    );
    final reorderableController = _reorderableController;
    final draggedEntity = reorderableController.draggedEntity;

    return _wrapChild(
      child: child,
      reorderableEntity: reorderableEntity,
      currentDraggedEntity: draggedEntity,
      index: index,
    );
  }

  List<Widget> _wrapChildren() {
    final children = widget.children;
    if (children == null) return <Widget>[];

    final updatedChildren = <Widget>[];

    final reorderableController = _reorderableController;
    final childrenKeyMap = reorderableController.childrenKeyMap;
    final draggedEntity = reorderableController.draggedEntity;
    var index = 0;

    for (final child in children) {
      final key = (child.key as ValueKey);
      final reorderableEntity = childrenKeyMap[key.value]!;

      updatedChildren.add(
        _wrapChild(
          child: child,
          reorderableEntity: reorderableEntity,
          currentDraggedEntity: draggedEntity,
          index: index++,
        ),
      );
    }
    return updatedChildren;
  }

  /// Helper function to wrap [child] with required widgets for this package.
  ///
  /// [index] should be the position of the [child] in [widget.children] and
  /// is required to know if the [child] cannot be dragged.
  Widget _wrapChild({
    required Widget child,
    required ReorderableEntity reorderableEntity,
    required ReorderableEntity? currentDraggedEntity,
    required int index,
  }) {
    bool isDraggable = !widget.nonDraggableIndices.contains(index) &&
        !widget.lockedIndices.contains(index);

    // 選択機能の有効判定: enableMultiSelectionまたはselectionControllerが渡された場合
    final isMultiSelectionEnabled =
        widget.enableMultiSelection || widget.selectionController != null;

    // 選択不可判定: lockedIndicesまたはdisabledSelectionPredicateによる
    final isSelectionDisabled = widget.lockedIndices.contains(index) ||
        (widget.disabledSelectionPredicate?.call(index) ?? false);

    // 現在の選択状態を確認（Keyベース）
    final isSelected = isMultiSelectionEnabled &&
        _selectionController.isSelected(child.key!);

    // Shift+クリック用の全Keyリストを構範
    final allKeys = _getAllKeys();

    return ReorderableBuilderItem(
      reorderableEntity: reorderableEntity,
      animationConfig: widget.animationConfig,
      onOpacityFinished: _handleOpacityFinished,
      onMovingFinished: _handleMovingFinished,
      onCreated: _handleCreatedChild,
      releasedReorderableEntity:
          _reorderableController.releasedReorderableEntity,
      scrollOffset: _scrollOffset,
      enableDraggable: widget.enableDraggable && isDraggable,
      currentDraggedEntity: currentDraggedEntity,
      enableLongPress: widget.enableLongPress,
      longPressDelay: widget.longPressDelay,
      dragChildBoxDecoration: widget.dragChildBoxDecoration,
      feedbackScaleFactor: widget.feedbackScaleFactor,
      onDragStarted: _handleDragStarted,
      onDragEnd: _handleDragEnd,
      onDragCanceled: _handleDragCanceled,
      // 選択機能パラメータ
      selectionController: isMultiSelectionEnabled ? _selectionController : null,
      isSelected: isSelected,
      isSelectionDisabled: isSelectionDisabled,
      enableMultiSelection: isMultiSelectionEnabled,
      enableSelectAll: widget.enableSelectAll,
      allKeys: allKeys,
      onSelectionChanged: (selectedKeys) {
        widget.onSelectionChanged?.call(selectedKeys);
      },
      selectedDecoration: widget.selectedDecoration,
      selectedBuilder: widget.selectedBuilder,
      buildDefaultDragHandles: widget.buildDefaultDragHandles,
      child: child,
    );
  }

  /// 現在のGridViewに表示されている全アイテムのKeyリストを返す。
  ///
  /// Shift+クリックの範囲選択で使用する。
  List<Key> _getAllKeys() {
    final children = widget.children;
    if (children != null) {
      return children.map((c) => c.key!).toList();
    }
    // builderモード: childrenKeyMapから順序付きで取得
    final keyMap = _reorderableController.childrenOrderMap;
    final sortedKeys = keyMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sortedKeys.map((e) => e.value.key).toList();
  }

  ///
  /// Drag and Drop part
  ///

  void _handleDragStarted(ReorderableEntity reorderableEntity) {
    final isMultiSelectionEnabled = widget.enableMultiSelection || widget.selectionController != null;
    final key = reorderableEntity.key;
    final isSelected = _selectionController.isSelected(key);
    
    if (isMultiSelectionEnabled && !isSelected) {
      _selectionController.clear();
    }

    _reorderableController.handleDragStarted(
      reorderableEntity: reorderableEntity,
      currentScrollOffset: _scrollOffset,
      lockedIndices: widget.lockedIndices,
      isScrollableOutside: _isScrollOutside,
      itemCount: widget.itemCount,
      selectedKeys: isMultiSelectionEnabled ? _selectionController.selected : <Key>{},
    );
    widget.onDragStarted?.call(reorderableEntity.updatedOrderId);

    setState(() {});
  }

  void _handleDragUpdate(PointerMoveEvent pointerMoveEvent) {
    final hasUpdated = _reorderableController.handleDragUpdate(
      pointerMoveEvent: pointerMoveEvent,
    );

    if (hasUpdated) {
      // this fixes the issue when the user scrolls while dragging to get the updated scroll value
      _reorderableController.scrollOffset = _scrollOffset;

      // notifying about the new position of the dragged child
      final orderId = _reorderableController.draggedEntity!.updatedOrderId;
      widget.onUpdatedDraggedChild?.call(orderId);

      setState(() {});
    }
  }

  /// Called after dragged item was released.
  ///
  /// The offset will be translated to the local position of this widget
  ///
  /// If the scrollable part is outside the widget then the scroll offset
  /// has to be subtracted to get the correct position.
  void _handleDragEnd(
    ReorderableEntity reorderableEntity,
    Offset? globalOffset,
  ) {
    if (globalOffset != null) {
      var globalRenderObject = context.findRenderObject() as RenderBox;
      var offset = globalRenderObject.globalToLocal(globalOffset);

      // scrollable part is outside this widget
      if (_isScrollOutside) {
        offset -= _scrollOffset;
      }

      // call to ensure animation to dropped item
      _reorderableController.updateReleasedReorderableEntity(
        releasedReorderableEntity: ReleasedReorderableEntity(
          dropOffset: offset,
          reorderableEntity: reorderableEntity,
        ),
      );
    }
    setState(() {});

    _finishDragging();

    // important to update the dragged entity which should be null at this point
    setState(() {});
  }

  /// Called after the dragged child was canceled, e.g. deleted.
  ///
  /// Finishes dragging without doing any animation for the dragged entity.
  void _handleDragCanceled(ReorderableEntity reorderableEntity) {
    _finishDragging();
  }

  void _finishDragging() {
    if (_isFinishingDragging) {
      return;
    }
    _isFinishingDragging = true;

    try {
      final draggedEntity = _reorderableController.draggedEntity;
      if (draggedEntity == null) {
        return;
      }

      final draggedKey = draggedEntity.key;
      final controllerSelectedKeys = _reorderableController.selectedKeys;
      final isMultiSelection = controllerSelectedKeys.contains(draggedKey);
      final oldIndex = draggedEntity.originalOrderId;
      final newIndex = draggedEntity.updatedOrderId;

      widget.onDragEnd?.call(newIndex);

      final reorderUpdateEntities = _reorderableController.handleDragEnd();

      if (reorderUpdateEntities != null) {
        assert((widget.onReorder != null) ^ (widget.onReorderPositions != null),
            'One of either onReorder or onReorderPositions must be provided');

        widget.onReorderPositions?.call(reorderUpdateEntities);

        if (isMultiSelection) {
          widget.onReorder?.call((items) => _reorderableController.reorderListMulti(
                items: items,
                selectedKeys: _reorderableController.selectedKeys,
                oldIndex: oldIndex,
                newIndex: newIndex,
              ));
        } else {
          widget.onReorder?.call((items) => _reorderableController.reorderList(
                items: items,
                reorderUpdateEntities: reorderUpdateEntities,
              ));
        }
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isFinishingDragging = false;
      });
    }
  }

  ///
  /// Animation part
  ///

  ReorderableEntity _handleMovingFinished(ReorderableEntity reorderableEntity) {
    return _reorderableController.handleMovingFinished(
      reorderableEntity: reorderableEntity,
    );
  }

  ReorderableEntity _handleOpacityFinished(
    ReorderableEntity reorderableEntity,
  ) {
    return _reorderableController.handleOpacityFinished(
      reorderableEntity: reorderableEntity,
    );
  }

  /// Creates [ReorderableEntity] that contains all required values for animations.
  ///
  /// When the child was created, the offset and size is calculated (with [key]).
  /// The offset is a bit more tricky and has to be translated to the local
  /// offset in this widget.
  /// At this way the offset will always be correct for calculations even though
  /// this widget is appearing in animated way (e.g. within a BottomModalSheet).
  ReorderableEntity _handleCreatedChild(
    ReorderableEntity reorderableEntity,
    GlobalKey key,
  ) {
    final reorderableController = _reorderableController;
    final offsetMap = reorderableController.offsetMap;

    Offset? offset;
    Size size = reorderableEntity.size;

    var index = reorderableEntity.updatedOrderId;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      size = renderBox.size;

      // should only add offset if it is not existing to prevent wrong animations
      if (offsetMap[index] == null) {
        // translating global offset to the local offset in this widget
        var parentRenderObject = context.findRenderObject() as RenderBox;
        offset = parentRenderObject.globalToLocal(
          renderBox.localToGlobal(Offset.zero),
        );
        offset += _scrollOffset;
      }
    }

    return reorderableController.handleCreatedChild(
      offset: offset,
      reorderableEntity: reorderableEntity,
      size: size,
    );
  }

  ReorderableDragAndDropController get _reorderableController {
    if (widget.children == null) {
      return reorderableItemBuilderController;
    } else {
      return reorderableBuilderController;
    }
  }

  Offset get _scrollOffset {
    return _reorderableScrollable.getScrollOffset(
      reverse: widget.reverse,
    );
  }

  bool get _isScrollOutside {
    return _reorderableScrollable.isScrollOutside;
  }

  ReorderableScrollable get _reorderableScrollable => ReorderableScrollable.of(
        context,
        scrollController: widget.scrollController,
      );
}
