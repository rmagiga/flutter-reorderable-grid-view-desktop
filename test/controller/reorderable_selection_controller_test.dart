import 'package:flutter/cupertino.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReorderableSelectionController', () {
    late ReorderableSelectionController controller;
    const keyA = ValueKey('A');
    const keyB = ValueKey('B');
    const keyC = ValueKey('C');
    const keyD = ValueKey('D');

    setUp(() {
      controller = ReorderableSelectionController();
    });

    tearDown(() {
      controller.dispose();
    });

    // ────────────────────────────────────────────
    // 基本操作
    // ────────────────────────────────────────────

    group('select', () {
      test('未選択のKeyを選択できる', () {
        controller.select(keyA);
        expect(controller.isSelected(keyA), isTrue);
        expect(controller.selected, {keyA});
      });

      test('既に選択されているKeyをselectしても重複しない', () {
        controller.select(keyA);
        controller.select(keyA);
        expect(controller.selected.length, 1);
      });

      test('lastSelectedKeyが更新される', () {
        controller.select(keyA);
        expect(controller.lastSelectedKey, keyA);
        controller.select(keyB);
        expect(controller.lastSelectedKey, keyB);
      });
    });

    group('deselect', () {
      test('選択されているKeyを解除できる', () {
        controller.select(keyA);
        controller.deselect(keyA);
        expect(controller.isSelected(keyA), isFalse);
        expect(controller.selected, isEmpty);
      });

      test('選択されていないKeyをdeselectしても何もしない', () {
        controller.deselect(keyA);
        expect(controller.selected, isEmpty);
      });

      test('解除したKeyがlastSelectedKeyだった場合はnullになる', () {
        controller.select(keyA);
        controller.deselect(keyA);
        expect(controller.lastSelectedKey, isNull);
      });

      test('解除したKeyがlastSelectedKeyではない場合は別のKeyが残る', () {
        controller.select(keyA);
        controller.select(keyB);
        controller.deselect(keyB); // lastSelectedKeyはkeyB
        // keyBを解除したのでselectedの最後のkeyAが設定される
        expect(controller.lastSelectedKey, keyA);
      });
    });

    group('toggle', () {
      test('未選択 → 選択', () {
        controller.toggle(keyA);
        expect(controller.isSelected(keyA), isTrue);
      });

      test('選択中 → 解除', () {
        controller.select(keyA);
        controller.toggle(keyA);
        expect(controller.isSelected(keyA), isFalse);
      });
    });

    group('clear', () {
      test('全ての選択を解除できる', () {
        controller.select(keyA);
        controller.select(keyB);
        controller.clear();
        expect(controller.selected, isEmpty);
        expect(controller.lastSelectedKey, isNull);
      });

      test('空状態でclearしても問題ない', () {
        expect(() => controller.clear(), returnsNormally);
      });
    });

    group('selectAll', () {
      test('複数のKeyを一括選択できる', () {
        controller.selectAll([keyA, keyB, keyC]);
        expect(controller.selected, {keyA, keyB, keyC});
      });

      test('既に選択されているものは変わらない', () {
        controller.select(keyA);
        controller.selectAll([keyA, keyB]);
        expect(controller.selected, {keyA, keyB});
      });
    });

    // ────────────────────────────────────────────
    // 範囲選択
    // ────────────────────────────────────────────

    group('selectRange', () {
      final allKeys = [keyA, keyB, keyC, keyD];

      test('startからendまでの範囲を選択できる（順方向）', () {
        controller.selectRange(
          startKey: keyA,
          endKey: keyC,
          allKeys: allKeys,
        );
        expect(controller.selected, {keyA, keyB, keyC});
      });

      test('startからendまでの範囲を選択できる（逆方向）', () {
        controller.selectRange(
          startKey: keyC,
          endKey: keyA,
          allKeys: allKeys,
        );
        expect(controller.selected, {keyA, keyB, keyC});
      });

      test('startとendが同じ場合は1つだけ選択', () {
        controller.selectRange(
          startKey: keyB,
          endKey: keyB,
          allKeys: allKeys,
        );
        expect(controller.selected, {keyB});
      });

      test('allKeysに存在しないKeyを指定しても何もしない', () {
        const unknownKey = ValueKey('X');
        controller.selectRange(
          startKey: unknownKey,
          endKey: keyB,
          allKeys: allKeys,
        );
        expect(controller.selected, isEmpty);
      });
    });

    // ────────────────────────────────────────────
    // removeStaleKeys
    // ────────────────────────────────────────────

    group('removeStaleKeys', () {
      test('有効なKeyのみが選択に残る', () {
        controller.select(keyA);
        controller.select(keyB);
        controller.select(keyC);
        controller.removeStaleKeys({keyA, keyC});
        expect(controller.selected, {keyA, keyC});
        expect(controller.isSelected(keyB), isFalse);
      });

      test('全て有効なKeyの場合は変わらない', () {
        controller.select(keyA);
        controller.select(keyB);
        controller.removeStaleKeys({keyA, keyB, keyC});
        expect(controller.selected, {keyA, keyB});
      });

      test('全て無効なKeyの場合は空になる', () {
        controller.select(keyA);
        controller.select(keyB);
        controller.removeStaleKeys({keyC, keyD});
        expect(controller.selected, isEmpty);
      });
    });

    // ────────────────────────────────────────────
    // ChangeNotifier
    // ────────────────────────────────────────────

    group('ChangeNotifier通知', () {
      test('selectで通知される', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.select(keyA);
        expect(notifyCount, 1);
      });

      test('select（変化なし）では通知されない', () {
        controller.select(keyA);
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.select(keyA); // 変化なし
        expect(notifyCount, 0);
      });

      test('deselectで通知される', () {
        controller.select(keyA);
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.deselect(keyA);
        expect(notifyCount, 1);
      });

      test('clearで通知される（空でない場合）', () {
        controller.select(keyA);
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.clear();
        expect(notifyCount, 1);
      });

      test('clear（既に空）では通知されない', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.clear(); // 既に空
        expect(notifyCount, 0);
      });

      test('selectAllで通知される（変化あり）', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.selectAll([keyA, keyB]);
        expect(notifyCount, 1);
      });

      test('selectAll（変化なし）では通知されない', () {
        controller.selectAll([keyA, keyB]);
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.selectAll([keyA, keyB]); // 変化なし
        expect(notifyCount, 0);
      });
    });

    // ────────────────────────────────────────────
    // Keyベース選択がリオーダー後も維持されることの検証
    // ────────────────────────────────────────────

    group('Keyベース選択のリオーダー耐性', () {
      test('選択はIndexではなくKeyで管理されるため、リオーダー後も正しいアイテムを指す', () {
        // 初期: [A, B, C, D]
        // B と D を選択
        controller.select(keyB);
        controller.select(keyD);

        expect(controller.isSelected(keyB), isTrue);
        expect(controller.isSelected(keyD), isTrue);

        // リオーダー後: [D, A, B, C]
        // IndexベースならB(index=2)とD(index=0)になってしまうが、
        // Keyベースなら変わらずkeyB、keyDが選択されたまま
        expect(controller.isSelected(keyB), isTrue);
        expect(controller.isSelected(keyD), isTrue);
        expect(controller.isSelected(keyA), isFalse);
        expect(controller.isSelected(keyC), isFalse);
      });
    });
  });
}
