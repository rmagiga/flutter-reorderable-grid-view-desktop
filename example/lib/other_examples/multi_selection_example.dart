import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/widgets.dart';

/// 複数選択デモ
///
/// - Ctrl/Cmd + クリック: トグル選択
/// - Shift + クリック: 範囲選択
/// - Ctrl/Cmd + A: 全選択
/// - Escape: 全選択解除
class MultiSelectionExample extends StatefulWidget {
  const MultiSelectionExample({super.key});

  @override
  State<MultiSelectionExample> createState() => _MultiSelectionExampleState();
}

class _MultiSelectionExampleState extends State<MultiSelectionExample> {
  static const _itemCount = 20;

  // Controlled モード: 外部からControllerを渡す
  final _selectionController = ReorderableSelectionController();
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();

  List<int> _items = List.generate(_itemCount, (index) => index);

  @override
  void dispose() {
    _selectionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('複数選択デモ'),
        actions: [
          // 選択件数バッジ
          ListenableBuilder(
            listenable: _selectionController,
            builder: (context, _) {
              final count = _selectionController.selected.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    count > 0 ? '$count 件選択中' : '未選択',
                    style: TextStyle(
                      color: count > 0
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight:
                          count > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          // 全選択解除ボタン
          ListenableBuilder(
            listenable: _selectionController,
            builder: (context, _) {
              return IconButton(
                onPressed: _selectionController.selected.isNotEmpty
                    ? () => _selectionController.clear()
                    : null,
                icon: const Icon(Icons.deselect),
                tooltip: '選択解除',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作説明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              'Ctrl/Cmd+クリック: トグル選択  |  Shift+クリック: 範囲選択  |  Ctrl/Cmd+A: 全選択  |  Escape: 全選択解除',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // GridView
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReorderableBuilder<int>(
                // Controlled モード: 外部Controllerを渡す
                selectionController: _selectionController,
                // 選択デコレーション
                selectedDecoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                ),
                // lockedIndicesは選択不可
                lockedIndices: const [0],
                onReorder: (reorderedListFunction) {
                  setState(() {
                    _items = reorderedListFunction(_items);
                  });
                  // ドロップ後も選択維持（デフォルト動作）
                },
                onSelectionChanged: (selectedKeys) {
                  // 選択変更のログ（任意）
                  debugPrint('選択中: ${selectedKeys.length}件');
                },
                scrollController: _scrollController,
                children: _buildChildren(),
                builder: (children) {
                  return GridView(
                    key: _gridViewKey,
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    children: children,
                  );
                },
              ),
            ),
          ),
          // 選択アイテム一覧
          ListenableBuilder(
            listenable: _selectionController,
            builder: (context, _) {
              final selected = _selectionController.selected;
              if (selected.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 60,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '選択中のKey: ${selected.map((k) => (k as ValueKey).value).toList()}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectionController.clear(),
                      child: const Text('解除'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChildren() {
    return List<Widget>.generate(_items.length, (index) {
      final value = _items[index];
      final isLocked = index == 0;
      return CustomDraggable(
        key: ValueKey(value),
        child: Container(
          decoration: BoxDecoration(
            color: isLocked
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
