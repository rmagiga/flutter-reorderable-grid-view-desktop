import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/widgets.dart';

void main() {
  testWidgets(
      'ReorderableRubberBand clears selection when tapping outside items',
      (WidgetTester tester) async {
    final controller = ReorderableSelectionController();
    final gridKey = GlobalKey();

    final itemKey1 = const ValueKey(1);

    final childrenKeyMap = <dynamic, ReorderableEntity>{
      1: ReorderableEntity.create(
        key: itemKey1,
        updatedOrderId: 0,
        offset: const Offset(0, 0),
        size: const Size(200, 200),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                ReorderableRubberBand(
                  selectionController: controller,
                  gridKey: gridKey,
                  getScrollOffset: () => Offset.zero,
                  getChildrenKeyMap: () => childrenKeyMap,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // アイテム1を選択状態にする
    controller.select(itemKey1);
    expect(controller.selected, contains(itemKey1));

    // 余白（Offset(700, 500) は itemKey1 (0,0, 200,200) の範囲外）をタップ
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();

    // 選択がクリアされることを確認
    expect(controller.selected, isEmpty);
  });

  testWidgets(
      'ReorderableRubberBand does NOT clear selection when tapping inside an item',
      (WidgetTester tester) async {
    final controller = ReorderableSelectionController();
    final gridKey = GlobalKey();

    final itemKey1 = const ValueKey(1);

    final childrenKeyMap = <dynamic, ReorderableEntity>{
      1: ReorderableEntity.create(
        key: itemKey1,
        updatedOrderId: 0,
        offset: const Offset(0, 0),
        size: const Size(200, 200),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                ReorderableRubberBand(
                  selectionController: controller,
                  gridKey: gridKey,
                  getScrollOffset: () => Offset.zero,
                  getChildrenKeyMap: () => childrenKeyMap,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // アイテム1を選択状態にする
    controller.select(itemKey1);
    expect(controller.selected, contains(itemKey1));

    // アイテム内 (Offset(100, 100)) をタップ
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    // 選択状態が維持されることを確認
    expect(controller.selected, contains(itemKey1));
  });
}
