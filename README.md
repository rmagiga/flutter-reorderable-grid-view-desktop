[日本語](README_JA.md) | [English](README.md)

![Pub Version](https://img.shields.io/pub/v/flutter_reorderable_grid_view_desktop?color=%23397ab6&style=flat-square)
![GitHub branch checks state](https://img.shields.io/github/checks-status/rmagiga/flutter-reorderable-grid-view-desktop/master?style=flat-square)

<p>
  <img src="https://github.com/rmagiga/flutter-reorderable-grid-view-desktop/blob/master/doc/animated_drag_and_drop.gif?raw=true"
    alt="An animated image of the iOS ReordableGridView UI" height="400"/>
<img src="https://github.com/rmagiga/flutter-reorderable-grid-view-desktop/blob/master/doc/animated_items.gif?raw=true"
    alt="An animated image of the iOS ReordableGridView UI" height="400"/>
</p>

Package for having animated Drag and Drop functionality for every type of `GridView` and to have animations when changing the size of children inside your `GridView`.

## Index
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Usage](#usage)
  - [Drag and Drop](#drag-and-drop)
  - [Scroll while dragging](#scroll-while-dragging)
  - [Animations](#animations)
  - [Multi-Selection](#multi-selection)
  - [Rubber Band Selection](#rubber-band-selection)
  - [Drag Handle](#drag-handle)
- [Supported Widgets](#supported-widgets)
- [Parameters](#parameters)
  - [AnimationConfig Parameters](#animationconfig-parameters)
  - [ReorderableRubberBandController](#reorderablerubberbandcontroller)
  - [ReorderableSelectionController](#reorderableselectioncontroller)
- [Road Map](#road-map)
- [Future Plans](#future-plans)


## Overview

Enhance your Flutter app with this package to:

- Enable animated drag-and-drop functionality:
  - Works seamlessly with any GridView.
  - For GridView.builder, use ReorderableBuilder.builder to implement drag-and-drop.
- Add smooth animations for adding, removing, or updating items in your grid.
- **Multi-selection with drag and drop**: Select multiple items and reorder them together.
- **Rubber band (marquee) selection**: Draw a rectangle to select multiple items at once (desktop).
- **Drag handle support**: Use a dedicated drag handle widget to initiate dragging.

## Getting started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view_desktop/widgets/widgets.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();
  
  var _fruits = <String>["apple", "banana", "strawberry"];

  @override
  Widget build(BuildContext context) {
    final generatedChildren = List.generate(
      _fruits.length,
              (index) => Container(
        key: Key(_fruits.elementAt(index)),
        color: Colors.lightBlue,
        child: Text(
          _fruits.elementAt(index),
        ),
      ),
    );

    return Scaffold(
      body: ReorderableBuilder(
        children: generatedChildren,
        scrollController: _scrollController,
        onReorder: (ReorderedListFunction reorderedListFunction) {
          setState(() {
            _fruits = reorderedListFunction(_fruits) as List<String>;
          });
        },
        builder: (children) {
          return GridView(
            key: _gridViewKey,
            controller: _scrollController,
            children: children,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 8,
            ),
          );
        },
      ),
    );
  }
}
```

## Usage
`ReorderableBuilder` provides two main functionalities: **Drag and Drop** and **Animations**.

To use this widget, wrap `ReorderableBuilder` around your `GridView`. For more details, refer to the [Getting Started](#getting-started) section.

**Important**: Ensure each child within the `GridView` has a unique key.

### ScrollController

When using a scrollable `GridView`, `ReorderableBuilder` requires a `ScrollController`. 
This means you must assign the `ScrollController` to both the scrollable widget and `ReorderableBuilder`. 

*For more details, check out the example in `inner_scrollable_example.dart`.*

If the parent is a scrollable widget, you should not assign a `ScrollController`.
In this case, the widget automatically looks up the `ScrollController`.
Assigning one manually can cause issues with drag-and-drop functionality.

*For more details, check out the example in `outer_scrollable_example.dart`.*

If no `ScrollController` is assigned and no `ScrollController` is found within the context, it indicates that the `GridView` is not scrollable.

*For more details, check out the example in `no_scrollable_example.dart`.*

### Drag and Drop
The drag-and-drop functionality is enabled by default.

To ensure proper reordering, you must implement the `onReorder` callback to update your list of children. 
Without this, the reorder operation will not work and may cause issues.

### Scroll while dragging
While dragging a child, moving it to the top or bottom of your `GridView` will trigger automatic scrolling. 

You can disable this behavior by setting `enableScrollingWhileDragging` to `false`.

### Animations
## Types of Animations

There are two types of animations:

**Drag and Drop**:

This animation ensures smooth positioning of the dragged child to any position (unless the position is locked).
While dragging, the movement of the other children is also animated.

**List Updates**:

These animations occur when updating your list of children by adding, removing, or modifying items.
For example, adding or removing a child at the beginning of the list affects the positions of all subsequent children (See the GIFs at the top of the page for examples).

### Multi-Selection

You can enable multi-selection to allow users to select multiple items and reorder them together as a group.

Set `enableMultiSelection: true` on `ReorderableBuilder` to enable this feature.

**Keyboard shortcuts (when an item is focused)**:
- **Click**: Single select (deselects others)
- **Ctrl/Cmd + Click**: Toggle selection
- **Shift + Click**: Range selection
- **Space / Enter**: Toggle selection of focused item
- **Escape**: Clear all selections
- **Ctrl/Cmd + A**: Select all (when `enableSelectAll` is `true`)

> On macOS, `Cmd` (Meta) key is used automatically instead of `Ctrl`.

```dart
ReorderableBuilder(
  children: generatedChildren,
  enableMultiSelection: true,
  onSelectionChanged: (Set<Key> selectedKeys) {
    setState(() {
      _selectedKeys = selectedKeys;
    });
  },
  selectedBuilder: (context, child, isSelected) {
    return Stack(children: [
      child,
      if (isSelected)
        Positioned(
          top: 4, right: 4,
          child: Icon(Icons.check_circle, color: Colors.blue),
        ),
    ]);
  },
  onReorder: (ReorderedListFunction reorderedListFunction) {
    setState(() {
      _fruits = reorderedListFunction(_fruits) as List<String>;
    });
  },
  builder: (children) => GridView(...),
)
```

To control the selection state externally (Controlled mode), pass a `ReorderableSelectionController`:

```dart
final _selectionController = ReorderableSelectionController();

ReorderableBuilder(
  selectionController: _selectionController,
  // ...
)

// External operations
_selectionController.selectAll(allKeys);
_selectionController.clear();
print(_selectionController.selected); // current selection set
```

*For more details, check out the example in `multi_selection_example.dart`.*

### Rubber Band Selection

Rubber band (marquee) selection lets users draw a rectangle by dragging to select multiple items at once. This is standard behavior on desktop file managers and is enabled only on desktop platforms by default.

There are two modes:

#### Inline Mode (within ReorderableBuilder)

The simplest option. The rubber band covers the area of the `ReorderableBuilder` widget. Set `enableRubberBandSelection: true` (requires `enableMultiSelection: true` or a `selectionController`):

```dart
ReorderableBuilder(
  enableMultiSelection: true,
  enableRubberBandSelection: true,
  // Optional: customize the rectangle appearance
  rubberBandConfiguration: RubberBandConfiguration(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      border: Border.all(color: Colors.blue, width: 1),
    ),
    desktopOnly: true, // disabled on mobile (default)
  ),
  onReorder: (reorderedListFunction) { /* ... */ },
  builder: (children) => GridView(/* ... */),
)
```

Note: In this mode, the rubber band can only start from within the grid area. If you need the rubber band to start from surrounding padding or empty space, use the page-level mode below.

#### Page-Level Mode (recommended for desktop apps)

Place the `ReorderableRubberBand` widget at a higher level in the widget tree (e.g., in a `Stack`) so that dragging can start from outside the grid (padding, margins, etc.). This matches the behavior of native desktop file managers.

Use `ReorderableRubberBandController` to expose grid item information to the external rubber band widget, and pass a `GlobalKey` to link the coordinate systems:

```dart
final _selectionController = ReorderableSelectionController();
final _rubberBandController = ReorderableRubberBandController();
final _gridKey = GlobalKey();
final _scrollController = ScrollController();

// In your build method:
Stack(
  children: [
    // Grid content (with padding — rubber band can start from here too)
    Padding(
      padding: const EdgeInsets.all(16),
      child: ReorderableBuilder(
        selectionController: _selectionController,
        rubberBandController: _rubberBandController,
        scrollController: _scrollController,
        onReorder: (reorderedListFunction) { /* ... */ },
        children: children,
        builder: (children) => GridView(
          key: _gridKey,
          controller: _scrollController,
          children: children,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    ),
    // Rubber band overlay (covers the entire Stack area)
    ReorderableRubberBand(
      selectionController: _selectionController,
      gridKey: _gridKey,
      getScrollOffset: () => _rubberBandController.scrollOffset,
      getChildrenKeyMap: () => _rubberBandController.childrenKeyMap,
      isDragging: _rubberBandController.isDragging,
      onSelectionChanged: (selectedKeys) {
        // Update your UI state here
      },
      // Optional: pass locked indices / predicate to prevent selecting certain items
      lockedIndices: const [0],
    ),
  ],
)
```

When `rubberBandController` is provided to `ReorderableBuilder`, the inline rubber band rendering is automatically skipped — the external `ReorderableRubberBand` takes full responsibility for drawing and hit-testing.

**Keyboard modifiers during rubber band:**
- **Drag**: Replace selection with items in the rectangle
- **Ctrl/Cmd + Drag**: Add items in the rectangle to existing selection

**Important notes:**
- The rubber band respects `lockedIndices` and `disabledSelectionPredicate` — those items cannot be selected via rubber band.
- During a reorder drag (`isDragging: true`), the rubber band is automatically disabled to avoid conflicts.
- On mobile platforms (`desktopOnly: true` by default), the rubber band is disabled.

*For more details, check out the example in `multi_selection_example.dart`.*

#### `ReorderableRubberBand` Parameters

| **Parameter**                  | **Description**                                                                                         | **Required** |
|:-------------------------------|:--------------------------------------------------------------------------------------------------------|:------------:|
| `selectionController`          | The `ReorderableSelectionController` managing the selection state.                                      |     Yes      |
| `getScrollOffset`              | Callback returning the current scroll offset of the grid.                                               |     Yes      |
| `getChildrenKeyMap`            | Callback returning the map of item keys to their `ReorderableEntity` (position and size).              |     Yes      |
| `configuration`                | `RubberBandConfiguration` for appearance and behavior. Defaults to a semi-transparent blue rectangle.  |      No      |
| `isDragging`                   | Whether a reorder drag is in progress. When `true`, the rubber band is disabled.                       |      No      |
| `onSelectionChanged`           | Callback called when the rubber band selection changes.                                                 |      No      |
| `lockedIndices`                | Indices of items that cannot be selected via rubber band.                                               |      No      |
| `disabledSelectionPredicate`   | Predicate to disable rubber band selection for specific items by index.                                 |      No      |
| `gridKey`                      | `GlobalKey` of the grid widget. Required for page-level mode to convert coordinates.                   |      No      |

#### `RubberBandConfiguration`

| **Parameter**  | **Description**                                                                                              | **Default** |
|:---------------|:-------------------------------------------------------------------------------------------------------------|:-----------:|
| `decoration`   | `BoxDecoration` for the rubber band rectangle. If null, a default semi-transparent blue rectangle is used.  |    null     |
| `desktopOnly`  | If true, rubber band is disabled on mobile platforms (Android/iOS).                                          |    true     |

### Drag Handle

By default, dragging can be initiated from anywhere on an item. You can restrict drag initiation to a specific handle widget by setting `buildDefaultDragHandles: false` and wrapping the handle with `ReorderableGridDragStartListener`.

```dart
ReorderableBuilder(
  buildDefaultDragHandles: false,
  children: List.generate(
    _fruits.length,
    (index) => Container(
      key: Key(_fruits[index]),
      child: Row(
        children: [
          // Only this handle initiates drag
          ReorderableGridDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          Text(_fruits[index]),
        ],
      ),
    ),
  ),
  // ...
)
```

### Supported Widgets

* Using `ReorderableBuilder` supports
    * `GridView`
    * `GridView.count`
    * `GridView.extent`


* Using `ReorderableBuilder.builder` supports
  * `GridView.builder`

### Parameters

| **Parameter**                  | **Description**                                                                                                           | **Default Value** |
|:-------------------------------|:--------------------------------------------------------------------------------------------------------------------------|:-----------------:|
| `children`                     | Displays all given children that are build inside a Wrap or GridView. Don't forget a unique key for every child.       |       **-**       |
| `childBuilder`                 | Enable support for [GridView.builder] using this function. Don't forget a unique key for every child.                   |       **-**       |
| `lockedIndices`                | Define all children that can't be moved while dragging. You need to add the index of this child in a list.              |    **<int>[]**    |
| `nonDraggableIndices`          | Specify indices for [children] that are not draggable.                                                                   |    **<int>[]**    |
| `animationConfig`              | Configuration for all child animations (fade in, position changes, drag feedback, release animation).                   | `const ReorderableAnimationConfig()` |
| `enableLongPress`              | Deprecated. Use `longPressDelay`; for immediate drag set `Duration.zero`.                                                |     **true**      |
| `longPressDelay`               | Specify the duration before dragging starts after long-pressing the widget.                                              |    **500 ms**     |
| `enableDraggable`              | Enables the drag and drop functionality.                                                                                 |     **true**      |
| `enableScrollingWhileDragging` | Enables the functionality to scroll while dragging a child to the top or bottom.                                         |     **true**      |
| `automaticScrollExtent`        | Defines the height of the top or bottom before the dragged child indicates a scrolling.                                  |    **150.0**      |
| `feedbackScaleFactor`          | Scale factor applied to the feedback widget during a drag operation. A value of 1.0 means no scaling.                   |    **1.05**       |
| `dragChildBoxDecoration`       | When a child is dragged, you can override the default BoxDecoration of the dragged child.                                |       **-**       |
| `reverse`                      | Handles the reversed order of your children. Ensure to add this flag to your scrollable and this widget.                |     **false**     |
| `builder`                      | It's required to use [ReorderableBuilder] to obtain updated [children].                                                  |       **-**       |
| `onReorder`                    | After releasing the dragged child, [onReorder] is called which contains a function as parameter to reorder all items.   |       **-**       |
| `onDragStarted`                | Callback when dragging starts with the index where it started.                                                           |       **-**       |
| `onDragEnd`                    | Callback when the dragged child was released with the index.                                                             |       **-**       |
| `onUpdatedDraggedChild`        | Called when the dragged child has updated his position while dragging.                                                   |       **-**       |
| `scrollController`             | `ScrollController` which should be also assigned to the scrollable widget. Don't forget this to prevent animation issues.|       **-**       |
| `enableMultiSelection`         | Enables multi-selection functionality. Automatically enabled when `selectionController` is provided.                     |     **false**     |
| `selectionController`          | Controller to manage selection state externally (Controlled mode). If not provided, an internal controller is created.  |       **-**       |
| `onSelectionChanged`           | Callback called when the selection state changes. The argument is the current set of selected `Key`s.                   |       **-**       |
| `selectedDecoration`           | `BoxDecoration` applied to selected items. Ignored when `selectedBuilder` is specified.                                 |       **-**       |
| `selectedBuilder`              | Custom builder for selected items. Takes priority over `selectedDecoration`. Allows custom UI like checkmarks or badges. |       **-**       |
| `enableSelectAll`              | Enables Ctrl/Cmd + A to select all items. Only effective when `enableMultiSelection` is true.                           |     **true**      |
| `disabledSelectionPredicate`   | Predicate to disable selection for specific items by index. Items in `lockedIndices` are also automatically disabled.   |       **-**       |
| `buildDefaultDragHandles`      | Whether to allow dragging from anywhere on an item. Set to false to use `ReorderableGridDragStartListener` instead.     |     **true**      |
| `enableRubberBandSelection`    | Enables rubber band (marquee) selection. Only effective when multi-selection is enabled.                                 |     **false**     |
| `rubberBandConfiguration`      | Configuration for the rubber band appearance and behavior. Used when `enableRubberBandSelection` is true.              |       **-**       |
| `rubberBandController`         | Controller to expose grid item info for page-level rubber band. When provided, inline rubber band rendering is skipped.|       **-**       |

### AnimationConfig Parameters

Use `animationConfig` to configure all animation durations and curves in one place.

| **Parameter**                       | **Description**                                                                                                  | **Default Value** |
|:------------------------------------|:-----------------------------------------------------------------------------------------------------------------|:-----------------:|
| `positionChangeDuration`            | Duration for item position changes outside active dragging.                                                      |    **200 ms**     |
| `draggingPositionChangeDuration`    | Duration for item position changes while dragging.                                                               |    **200 ms**     |
| `releasedItemDuration`              | Duration for the released dragged item to animate to its final position.                                        |    **150 ms**     |
| `fadeInDuration`                    | Duration for fade-in when a new child is added.                                                                  |    **500 ms**     |
| `dragFeedbackDuration`              | Duration for scaling the drag feedback widget.                                                                   |    **150 ms**     |
| `positionChangeCurve`               | Curve for `positionChangeDuration`. Falls back to `defaultAnimationCurve` when null.                            |       **-**       |
| `draggingPositionChangeCurve`       | Curve for `draggingPositionChangeDuration`. Falls back to `defaultAnimationCurve` when null.                    |       **-**       |
| `releasedItemCurve`                 | Curve for `releasedItemDuration`. Falls back to `defaultAnimationCurve` when null.                              |       **-**       |
| `fadeInCurve`                       | Curve for `fadeInDuration`. Falls back to `defaultAnimationCurve` when null.                                    |       **-**       |
| `dragFeedbackCurve`                 | Curve for `dragFeedbackDuration`. Falls back to `defaultAnimationCurve`, then to `Curves.linear` if still null.| `Curves.linear` |
| `defaultAnimationCurve`             | Global fallback curve for animation curve parameters when a specific curve is not provided.                      |       **-**       |
| `enableAnimations`                  | Enables or disables animations globally. If false, durations become `Duration.zero` and nullable curves resolve to null. |    **true**      |

### `CustomDraggable`

The `CustomDraggable` widget is a helper that can contain optional information to be added to `Draggable` or `LongPressDraggable`.

Ensure this widget wraps the child you intend to add to your `GridView`, as it should receive the unique key.

```dart
  CustomDraggable(
    // add your unique key here
    key: Key('unique'),
    // will be passed to `Draggable` or `LongPressDraggable`
    data: 'data',
    child: Placeholder(),
  ),
```

### `ReorderableRubberBandController`

`ReorderableRubberBandController` exposes the internal grid item information (positions, sizes, scroll offset) to an externally placed `ReorderableRubberBand` widget.

Pass it to `ReorderableBuilder`'s `rubberBandController` parameter. The controller is automatically attached on init and detached on dispose.

| **Property**       | **Description**                                                                        |
|:-------------------|:---------------------------------------------------------------------------------------|
| `childrenKeyMap`   | Map of all items' `ValueKey.value` to their `ReorderableEntity` (position and size).   |
| `scrollOffset`     | Current scroll offset of the grid.                                                     |
| `isDragging`       | Whether a reorder drag is currently in progress.                                       |

### `ReorderableSelectionController`

`ReorderableSelectionController` manages the selection state of items in a `GridView`.
Use it in the same pattern as `TextEditingController` or `ScrollController`.

Pass it to `ReorderableBuilder`'s `selectionController` parameter to control selection state externally (Controlled mode).
If not provided, `ReorderableBuilder` creates one internally (Uncontrolled mode).

| **Method / Property**       | **Description**                                                                 |
|:----------------------------|:--------------------------------------------------------------------------------|
| `selected`                  | The current set of selected `Key`s (read-only).                                 |
| `lastSelectedKey`           | The last selected `Key`, used as the anchor for Shift+click range selection.    |
| `isSelected(key)`           | Returns whether the given `key` is currently selected.                          |
| `select(key)`               | Selects the given `key`.                                                        |
| `deselect(key)`             | Deselects the given `key`.                                                      |
| `toggle(key)`               | Toggles the selection state of the given `key`.                                 |
| `selectAll(keys)`           | Selects all given `key`s.                                                       |
| `selectRange(...)`          | Selects a range of items between `startKey` and `endKey` based on `allKeys`.    |
| `clear()`                   | Clears all selections.                                                          |
| `removeStaleKeys(validKeys)`| Removes keys that are no longer valid (e.g., after item deletion).              |

### `ReorderableGridDragStartListener`

A widget that wraps a drag handle (e.g., a hamburger icon `≡`). When used together with `buildDefaultDragHandles: false`, dragging only starts when this handle is dragged.

```dart
ReorderableGridDragStartListener(
  index: index,
  child: const Icon(Icons.drag_handle),
)
```

`ReorderableGridDelayedDragStartListener` is a variant that behaves like long-press dragging (same as when `enableLongPress` is enabled on the parent).

## Road map for release of version `6.0.0`
* Code Refactoring for easier understanding!

* Support for `Wrap` 
  * with animation when adding or removing items
  * drag and drop
  * Github Issue [#28](https://github.com/karvulf/flutter-reorderable-grid-view-desktop/issues/28)

## Future Plans

If you have feature requests or have found any issues, please feel free to open an issue on the GitHub project repository.

Contributions are also highly appreciated! If you'd like to contribute a new feature or bug fix, 
opening a pull request is the way to go. This helps in getting updates and fixes out faster.

Thank you for using this package!
