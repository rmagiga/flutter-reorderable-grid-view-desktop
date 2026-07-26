import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/reorderable_draggable.dart';

/// ドラッグハンドルとなる子ウィジェットをラップするためのウィジェット。
///
/// このウィジェットで三本線アイコン（`≡`）などをラップすると、
/// そのアイコンをドラッグしたときのみ並び替えが開始されます。
/// `buildDefaultDragHandles: false` と併せて使用してください。
class ReorderableGridDragStartListener extends StatefulWidget {
  /// ドラッグハンドルとして表示するウィジェット
  final Widget child;

  /// アイテムのインデックス（現状のAPI互換性のために保持。内部ではBuildContextから先祖を辿るため使用しません）
  final int index;

  /// ドラッグ開始を有効にするかどうか
  final bool enabled;

  const ReorderableGridDragStartListener({
    required this.child,
    required this.index,
    this.enabled = true,
    super.key,
  });

  @override
  State<ReorderableGridDragStartListener> createState() =>
      _ReorderableGridDragStartListenerState();
}

class _ReorderableGridDragStartListenerState
    extends State<ReorderableGridDragStartListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _register();
    });
  }

  @override
  void didUpdateWidget(ReorderableGridDragStartListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  void _register() {
    if (!mounted) return;
    final state = ReorderableDraggableProvider.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    state?.registerDragHandle(renderBox);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        debugPrint('[DragStartListener] onTapDown 発生 (吸収)');
      },
      onTap: () {
        debugPrint('[DragStartListener] onTap 発生 (吸収)');
      },
      onLongPress: () {
        debugPrint('[DragStartListener] onLongPress 発生 (吸収)');
      },
      child: widget.child,
    );
  }
}

/// [ReorderableGridDragStartListener] の長押し遅延版。
///
/// 親の `enableLongPress` が有効な場合と同様の動作をします。
class ReorderableGridDelayedDragStartListener
    extends ReorderableGridDragStartListener {
  const ReorderableGridDelayedDragStartListener({
    required super.child,
    required super.index,
    super.enabled,
    super.key,
  });
}
