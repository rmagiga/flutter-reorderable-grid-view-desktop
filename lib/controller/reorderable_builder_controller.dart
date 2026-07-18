import 'package:flutter/cupertino.dart';
import 'package:flutter_reorderable_grid_view_desktop/controller/reorderable_drag_and_drop_controller.dart';
import 'package:flutter_reorderable_grid_view_desktop/entities/reorderable_entity.dart';

/// Handles logic to set all [ReorderableEntity] that are related to the children.
///
/// Every child gets a [ReorderableEntity] that contains information about
/// the position, the size and so on. This is need for calculations later when
/// the children are moving or changing their position.
class ReorderableBuilderController extends ReorderableDragAndDropController {
  /// Adds [ReorderableEntity] for all [children] to two maps.
  ///
  /// This is called when the [children] are created for the first time.
  void initChildren({required List<Widget> children}) {
    var index = 0;

    for (final child in children) {
      assert(child.key != null, 'Add a unique key to every child');
      final key = child.key! as ValueKey;
      assert(!childrenKeyMap.containsKey(key.value), "Key is duplicated!");
      final reorderableEntity = ReorderableEntity.create(
        key: key,
        updatedOrderId: index,
      );
      // ReorderableEntity.create では originalOrderId=-1 のため、
      // updatedOrderId (=index) をキーとして使う
      super.childrenOrderMap[index] = reorderableEntity;
      super.childrenKeyMap[reorderableEntity.key.value] = reorderableEntity;
      index++;
    }
  }

  /// Iterates through [children] and updates [childrenKeyMap] and [childrenOrderMap].
  ///
  /// The update should always be called when the children are changing.
  /// With this update, it is possible to have correct animations later to move
  /// the [children] visually.
  void updateChildren({required List<Widget> children}) {
    var updatedChildrenKeyMap = <dynamic, ReorderableEntity>{};
    var updatedChildrenOrderMap = <int, ReorderableEntity>{};

    // === 調査ログ: updateChildren 前の状態 ===
    final sortedBefore = childrenOrderMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    debugPrint('[updateChildren] Before: childrenOrderMap order = ${sortedBefore.map((e) => "${e.key}:${e.value.key}").toList()}');
    debugPrint('[updateChildren] Input children keys = ${children.map((c) => c.key).toList()}');

    var index = 0;
    for (final child in children) {
      final reorderableEntity = getReorderableEntity(
        key: child.key as ValueKey,
        index: index,
      );
      // isNew (originalOrderId=-1) の場合は updatedOrderId (=index) をキーに使う。
      // originalOrderId を使うと複数の新規アイテムが -1 に衝突して消滅するため。
      final orderId = reorderableEntity.isNew
          ? reorderableEntity.updatedOrderId
          : reorderableEntity.originalOrderId;
      updatedChildrenOrderMap[orderId] = reorderableEntity;
      updatedChildrenKeyMap[reorderableEntity.key.value] = reorderableEntity;
      index++;
    }

    // === 調査ログ: updateChildren 後の状態 ===
    final sortedAfter = updatedChildrenOrderMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    debugPrint('[updateChildren] After: updatedChildrenOrderMap order = ${sortedAfter.map((e) => "${e.key}:${e.value.key}(orig=${e.value.originalOrderId},upd=${e.value.updatedOrderId})").toList()}');

    replaceMaps(
      updatedChildrenKeyMap: updatedChildrenKeyMap,
      updatedChildrenOrderMap: updatedChildrenOrderMap,
    );
  }
}
