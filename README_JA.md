[日本語] | [English](README.md)

![Pub Version](https://img.shields.io/pub/v/flutter_reorderable_grid_view_desktop?color=%23397ab6&style=flat-square)
![GitHub branch checks state](https://img.shields.io/github/checks-status/rmagiga/flutter-reorderable-grid-view-desktop/master?style=flat-square)

<p>
  <img src="https://github.com/rmagiga/flutter-reorderable-grid-view-desktop/blob/master/doc/animated_drag_and_drop.gif?raw=true"
    alt="An animated image of the iOS ReordableGridView UI" height="400"/>
  <img src="https://github.com/rmagiga/flutter-reorderable-grid-view-desktop/blob/master/doc/animated_items.gif?raw=true"
    alt="An animated image of the iOS ReordableGridView UI" height="400"/>
</p>

あらゆるタイプの `GridView` に対してアニメーション付きのドラッグ＆ドロップ機能を提供し、`GridView` 内のアイテムのサイズ変更時にアニメーションを提供するパッケージです。

## 目次
- [概要](#概要)
- [はじめに](#はじめに)
- [使用方法](#使用方法)
  - [ドラッグ＆ドロップ](#ドラッグ＆ドロップ)
  - [ドラッグ中のスクロール](#ドラッグ中のスクロール)
  - [アニメーション](#アニメーション)
  - [複数選択](#複数選択)
  - [ラバーバンド選択](#ラバーバンド選択)
  - [ドラッグハンドル](#ドラッグハンドル)
- [サポートされているウィジェット](#サポートされているウィジェット)
- [パラメータ](#パラメータ)
  - [AnimationConfig パラメータ](#animationconfig-パラメータ)
  - [ReorderableRubberBandController](#reorderablerubberbandcontroller)
  - [ReorderableSelectionController](#reorderableselectioncontroller)
- [ロードマップ](#ロードマップ)
- [今後の計画](#今後の計画)


## 概要

このパッケージを使用すると、Flutter アプリを以下のように強化できます：

- アニメーション付きドラッグ＆ドロップ機能の有効化：
  - 任意の `GridView` とシームレスに動作します。
  - `GridView.builder` の場合、ドラッグ＆ドロップの実装には `ReorderableBuilder.builder` を使用します。
- グリッド内のアイテムの追加、削除、更新時にスムーズなアニメーションを追加します。
- **複数選択＆ドラッグ＆ドロップ**：複数のアイテムを選択してまとめて並べ替えられます。
- **ラバーバンド（マーキー）選択**：矩形をドラッグして複数アイテムを一括選択できます（デスクトップ）。
- **ドラッグハンドル対応**：専用のハンドルウィジェットからのみドラッグを開始できます。

## はじめに

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

## 使用方法
`ReorderableBuilder` は主に **ドラッグ＆ドロップ** と **アニメーション** の2つの機能を提供します。

このウィジェットを使用するには、`GridView` を `ReorderableBuilder` でラップします。詳細については、[はじめに](#はじめに)セクションを参照してください。

**重要**: `GridView` 内の各子要素には、必ず一意のキー（`unique key`）を設定してください。

### ScrollController

スクロール可能な `GridView` を使用する場合、`ReorderableBuilder` は `ScrollController` を必要とします。 
これは、スクロール可能なウィジェットと `ReorderableBuilder` の両方に同じ `ScrollController` を割り当てる必要があることを意味します。 

*詳細については、`inner_scrollable_example.dart` の例を確認してください。*

親がスクロール可能なウィジェットである場合は、`ScrollController` を割り当ててはいけません。
この場合、ウィジェットは自動的に `ScrollController` を検索します。
手動で割り当てると、ドラッグ＆ドロップ機能で問題が発生する可能性があります。

*詳細については、`outer_scrollable_example.dart` の例を確認してください。*

`ScrollController` が割り当てられておらず、コンテキスト内でも `ScrollController` が見つからない場合は、`GridView` がスクロール可能ではないことを示します。

*詳細については、`no_scrollable_example.dart` の例を確認してください。*

### ドラッグ＆ドロップ
ドラッグ＆ドロップ機能はデフォルトで有効になっています。

並べ替えが正しく動作するように、`onReorder` コールバックを実装して子要素のリストを更新する必要があります。 
これを実装しないと、並べ替え操作が機能せず、問題が発生する可能性があります。

### ドラッグ中のスクロール
子要素をドラッグ中に、`GridView` の上部または下部に移動すると、自動スクロールがトリガーされます。 

この動作は、`enableScrollingWhileDragging` を `false` に設定することで無効にできます。

### アニメーション
## アニメーションの種類

アニメーションには以下の2つのタイプがあります：

**ドラッグ＆ドロップ**:

このアニメーションは、ドラッグされた子要素が（位置がロックされていない限り）任意の位置にスムーズに移動するようにします。
ドラッグ中、他の子要素の移動もアニメーション化されます。

**リストの更新**:

これらのアニメーションは、アイテムの追加、削除、または変更によって子要素のリストを更新するときに発生します。
たとえば、リストの先頭で子要素を追加または削除すると、それ以降のすべての子要素の位置に影響します（例については、ページ上部の GIF を参照してください）。

### 複数選択

`enableMultiSelection: true` を `ReorderableBuilder` に設定することで、複数アイテムを選択してまとめてドラッグ＆ドロップで並べ替えられます。

**キーボードショートカット（アイテムにフォーカスがある場合）**：
- **クリック**: 単一選択（他の選択は解除）
- **Ctrl/Cmd + クリック**: トグル選択
- **Shift + クリック**: 範囲選択
- **Space / Enter**: フォーカスアイテムの選択トグル
- **Escape**: 全選択解除
- **Ctrl/Cmd + A**: 全選択（`enableSelectAll` が `true` の場合）

> macOS では `Ctrl` の代わりに `Cmd` (Meta) キーが自動的に使用されます。

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

外部から選択状態を制御する場合（Controlled モード）は、`ReorderableSelectionController` を渡します：

```dart
final _selectionController = ReorderableSelectionController();

ReorderableBuilder(
  selectionController: _selectionController,
  // ...
)

// 外部からの操作
_selectionController.selectAll(allKeys);
_selectionController.clear();
print(_selectionController.selected); // 現在の選択セット
```

*詳細については、`multi_selection_example.dart` の例を確認してください。*

### ラバーバンド選択

ラバーバンド（マーキー）選択は、矩形をドラッグして描画することで複数のアイテムを一括選択する機能です。デスクトップのファイルマネージャーにおける標準的な操作であり、デフォルトではデスクトップ環境でのみ有効化されます。

2つのモードがあります：

#### インラインモード（ReorderableBuilder 内部）

最もシンプルな方法です。ラバーバンドは `ReorderableBuilder` ウィジェットの領域内で動作します。`enableRubberBandSelection: true` を設定します（`enableMultiSelection: true` または `selectionController` の指定が必要）：

```dart
ReorderableBuilder(
  enableMultiSelection: true,
  enableRubberBandSelection: true,
  // オプション: 矩形の外観をカスタマイズ
  rubberBandConfiguration: RubberBandConfiguration(
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      border: Border.all(color: Colors.blue, width: 1),
    ),
    desktopOnly: true, // モバイルでは無効（デフォルト）
  ),
  onReorder: (reorderedListFunction) { /* ... */ },
  builder: (children) => GridView(/* ... */),
)
```

注意: このモードでは、ラバーバンドはグリッド領域内からのみ開始できます。周囲の余白や空白エリアからもラバーバンドを開始したい場合は、以下のページレベルモードを使用してください。

#### ページレベルモード（デスクトップアプリ推奨）

`ReorderableRubberBand` ウィジェットをウィジェットツリーのより上位（例: `Stack` 内）に配置することで、グリッド外部（パディング・マージン等）からもドラッグを開始できます。ネイティブのデスクトップファイルマネージャーと同様の動作になります。

`ReorderableRubberBandController` を使ってグリッドのアイテム情報を外部のラバーバンドウィジェットに公開し、`GlobalKey` で座標系を連携させます：

```dart
final _selectionController = ReorderableSelectionController();
final _rubberBandController = ReorderableRubberBandController();
final _gridKey = GlobalKey();
final _scrollController = ScrollController();

// build メソッド内:
Stack(
  children: [
    // グリッドコンテンツ（パディング付き — ここからもラバーバンド開始可能）
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
    // ラバーバンドオーバーレイ（Stack 全体をカバー）
    ReorderableRubberBand(
      selectionController: _selectionController,
      scrollController: _scrollController,
      gridKey: _gridKey,
      getScrollOffset: () => _rubberBandController.scrollOffset,
      getChildrenKeyMap: () => _rubberBandController.childrenKeyMap,
      isDragging: _rubberBandController.isDragging,
      onSelectionChanged: (selectedKeys) {
        // UI 状態を更新
      },
      // オプション: 特定アイテムの選択を防止
      lockedIndices: const [0],
    ),
  ],
)
```

`rubberBandController` を `ReorderableBuilder` に渡すと、内部でのラバーバンドオーバーレイ描画は自動的にスキップされ、外部の `ReorderableRubberBand` が描画とヒットテストの全責任を担います。

**ラバーバンド中のキーボード修飾キー：**
- **ドラッグ**: 矩形内のアイテムで選択を置き換え
- **Ctrl/Cmd + ドラッグ**: 矩形内のアイテムを既存の選択に追加

**重要な注意点：**
- ラバーバンドは `lockedIndices` と `disabledSelectionPredicate` を尊重します — それらのアイテムはラバーバンドでは選択できません。
- リオーダードラッグ中（`isDragging: true`）は、衝突を避けるためラバーバンドは自動的に無効化されます。
- モバイルプラットフォームでは（`desktopOnly: true` がデフォルト）、ラバーバンドは無効です。

*詳細については、`multi_selection_example.dart` の例を確認してください。*

#### `ReorderableRubberBand` パラメータ

| **パラメータ**                  | **説明**                                                                                                | **必須** |
|:-------------------------------|:--------------------------------------------------------------------------------------------------------|:--------:|
| `selectionController`          | 選択状態を管理する `ReorderableSelectionController`。                                                    |    はい    |
| `getScrollOffset`              | グリッドの現在のスクロールオフセットを返すコールバック。                                                   |    はい    |
| `getChildrenKeyMap`            | アイテムキーから `ReorderableEntity`（位置・サイズ）へのマップを返すコールバック。                          |    はい    |
| `configuration`                | ラバーバンドの外観と動作設定。デフォルトは半透明の青い矩形。                                              |   いいえ   |
| `isDragging`                   | リオーダードラッグ中かどうか。`true` の場合、ラバーバンドは無効。                                         |   いいえ   |
| `onSelectionChanged`           | ラバーバンドによる選択が変化したときのコールバック。                                                       |   いいえ   |
| `lockedIndices`                | ラバーバンドで選択不可のアイテムインデックス。                                                            |   いいえ   |
| `disabledSelectionPredicate`   | 特定インデックスのアイテムのラバーバンド選択を無効にする述語。                                             |   いいえ   |
| `gridKey`                      | グリッドウィジェットの `GlobalKey`。ページレベルモードでの座標変換に必要。                                 |   いいえ   |
| `scrollController`             | GridView の `ScrollController`。指定すると、ラバーバンドドラッグ中にビューポート端付近で自動スクロールが有効になる。 |   いいえ   |
| `autoScroller`                 | 外部から注入する `AutoScroller` インスタンス（例: `ReorderableBuilder` と共有）。null の場合は内部で生成。   |   いいえ   |
| `autoScrollEdgeThreshold`      | 自動スクロールが開始されるビューポート端からの距離。デフォルト: `80.0`。                                     |   いいえ   |

#### `RubberBandConfiguration`

| **パラメータ**  | **説明**                                                                                                         | **デフォルト** |
|:---------------|:-----------------------------------------------------------------------------------------------------------------|:--------------:|
| `decoration`   | ラバーバンド矩形の `BoxDecoration`。null の場合はデフォルトの半透明青矩形が使用される。                            |    null        |
| `desktopOnly`  | true の場合、モバイル環境（Android / iOS）ではラバーバンドが無効化される。                                        |    true        |

### ドラッグハンドル

デフォルトでは、アイテムのどこからでもドラッグを開始できます。`buildDefaultDragHandles: false` を設定し、ハンドルとなるウィジェットを `ReorderableGridDragStartListener` でラップすることで、そのハンドル部分からのみドラッグを開始できるようになります。

```dart
ReorderableBuilder(
  buildDefaultDragHandles: false,
  children: List.generate(
    _fruits.length,
    (index) => Container(
      key: Key(_fruits[index]),
      child: Row(
        children: [
          // このハンドルのみドラッグを開始できる
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

### サポートされているウィジェット

* `ReorderableBuilder` の使用でサポートされるもの：
    * `GridView`
    * `GridView.count`
    * `GridView.extent`


* `ReorderableBuilder.builder` の使用でサポートされるもの：
  * `GridView.builder`

### パラメータ

| **パラメータ**                  | **説明**                                                                                                                  | **デフォルト値** |
|:-------------------------------|:--------------------------------------------------------------------------------------------------------------------------|:-----------------:|
| `children`                     | Wrap または GridView の内部にビルドされる、提供されたすべての子要素を表示します。各子要素に一意のキーを設定するのを忘れないでください。 |       **-**       |
| `childBuilder`                 | この関数を使用して `GridView.builder` のサポートを有効にします。各子要素に一意のキーを設定するのを忘れないでください。                     |       **-**       |
| `lockedIndices`                | ドラッグ中に移動できないすべての子要素を定義します。この子要素のインデックスをリストに追加する必要があります。                          |    **<int>[]**    |
| `nonDraggableIndices`          | ドラッグできない `children` のインデックスを指定します。                                                                     |    **<int>[]**    |
| `animationConfig`              | すべての子要素のアニメーション（フェードイン、位置変更、ドラッグフィードバック、リリースアニメーション）の設定。                   | `const ReorderableAnimationConfig()` |
| `enableLongPress`              | 非推奨。`longPressDelay` を使用してください。即座にドラッグを開始するには `Duration.zero` を設定します。                            |     **true**      |
| `longPressDelay`               | ウィジェットを長押しした後にドラッグが開始されるまでの時間を指定します。                                                          |    **500 ms**     |
| `enableDraggable`              | ドラッグ＆ドロップ機能を有効にします。                                                                                     |     **true**      |
| `enableScrollingWhileDragging` | 子要素を上部または下部にドラッグしたときにスクロールする機能を有効にします。                                                     |     **true**      |
| `automaticScrollExtent`        | ドラッグされた子要素がスクロールを示すまでの上部または下部の高さを定義します。                                              |    **150.0**      |
| `feedbackScaleFactor`          | ドラッグ中のフィードバックウィジェットに適用するスケール係数。1.0 はスケールなし。                                            |    **1.05**       |
| `dragChildBoxDecoration`       | 子要素がドラッグされているとき、ドラッグされた子要素のデフォルトの `BoxDecoration` をオーバーライドできます。                  |       **-**       |
| `reverse`                      | 子要素の順序を反転して処理します。スクロール可能ウィジェットとこのウィジェットの両方にこのフラグを追加してください。            |     **false**     |
| `builder`                      | 更新された `children` を取得するために `ReorderableBuilder` を使用する必要があります。                                      |       **-**       |
| `onReorder`                    | ドラッグされた子要素を離した後に呼び出されます。すべてのアイテムを並べ替えるための関数がパラメータとして含まれています。             |       **-**       |
| `onDragStarted`                | ドラッグが開始されたときに、開始されたインデックスとともに呼び出されるコールバック。                                               |       **-**       |
| `onDragEnd`                    | ドラッグされた子要素が離されたときに、そのインデックスとともに呼び出されるコールバック。                                           |       **-**       |
| `onUpdatedDraggedChild`        | ドラッグ中にドラッグされた子要素の位置が更新されたときに呼び出されます。                                                       |       **-**       |
| `scrollController`             | スクロール可能なウィジェットにも割り当てる必要がある `ScrollController`。アニメーションの問題を防ぐために、これを忘れないでください。 |       **-**       |
| `enableMultiSelection`         | 複数選択機能を有効にします。`selectionController` が渡された場合は自動的に有効になります。                                   |     **false**     |
| `selectionController`          | 外部から選択状態を管理するController（Controlledモード）。渡さない場合は内部で自動生成します（Uncontrolledモード）。           |       **-**       |
| `onSelectionChanged`           | 選択状態が変化したときに呼び出されるコールバック。引数は現在選択されている `Key` のセットです。                                |       **-**       |
| `selectedDecoration`           | 選択されたアイテムに適用する `BoxDecoration`。`selectedBuilder` が指定されている場合は無視されます。                         |       **-**       |
| `selectedBuilder`              | 選択されたアイテムのカスタムビルダー。`selectedDecoration` より優先されます。チェックマークやバッジなど自由にカスタマイズできます。 |       **-**       |
| `enableSelectAll`              | Ctrl/Cmd + A による全選択を有効にします。`enableMultiSelection` が `true` の場合のみ有効です。                              |     **true**      |
| `disabledSelectionPredicate`   | 特定のインデックスのアイテムを選択不可にする述語。`lockedIndices` のアイテムも自動的に選択不可になります。                      |       **-**       |
| `buildDefaultDragHandles`      | アイテムのどこからでもドラッグを開始できるかどうか。`false` にすると `ReorderableGridDragStartListener` のみで開始できます。  |     **true**      |
| `enableRubberBandSelection`    | ラバーバンド（矩形ドラッグ）選択を有効にする。複数選択が有効な場合のみ機能。                                                |     **false**     |
| `rubberBandConfiguration`      | ラバーバンドの外観・動作設定。`enableRubberBandSelection` が `true` の場合に使用。                                          |       **-**       |
| `rubberBandController`         | ページレベルのラバーバンド用Controller。指定すると内部のラバーバンド描画はスキップされる。                                   |       **-**       |

### AnimationConfig パラメータ

`animationConfig` を使用して、すべてのアニメーション期間（duration）とイージング（curve）を一箇所で設定します。

| **パラメータ**                       | **説明**                                                                                                         | **デフォルト値** |
|:------------------------------------|:-----------------------------------------------------------------------------------------------------------------|:-----------------:|
| `positionChangeDuration`            | アクティブなドラッグ以外でのアイテムの位置変更の期間。                                                           |    **200 ms**     |
| `draggingPositionChangeDuration`    | ドラッグ中のアイテムの位置変更の期間。                                                                           |    **200 ms**     |
| `releasedItemDuration`              | 離されたドラッグアイテムが最終位置にアニメーションする期間。                                                     |    **150 ms**     |
| `fadeInDuration`                    | 新しい子要素が追加されたときのフェードインの期間。                                                               |    **500 ms**     |
| `dragFeedbackDuration`              | ドラッグフィードバックウィジェットをスケーリングする期間。                                                        |    **150 ms**     |
| `positionChangeCurve`               | `positionChangeDuration` のイージング。null の場合は `defaultAnimationCurve` にフォールバックします。             |       **-**       |
| `draggingPositionChangeCurve`       | `draggingPositionChangeDuration` のイージング。null の場合は `defaultAnimationCurve` にフォールバックします。     |       **-**       |
| `releasedItemCurve`                 | `releasedItemDuration` のイージング. null の場合は `defaultAnimationCurve` にフォールバックします。               |       **-**       |
| `fadeInCurve`                       | `fadeInDuration` のイージング。null の場合は `defaultAnimationCurve` にフォールバックします。                       |       **-**       |
| `dragFeedbackCurve`                 | `dragFeedbackDuration` のイージング。null の場合は `defaultAnimationCurve` にフォールバックし、それでも null の場合は `Curves.linear` になります。 | `Curves.linear` |
| `defaultAnimationCurve`             | 特定のイージングが提供されていない場合の、アニメーションイージングパラメータのグローバルフォールバック。           |       **-**       |
| `enableAnimations`                  | アニメーションをグローバルに有効または無効にします。false の場合、期間は `Duration.zero` になり、null を許容するイージングは null に解決されます。 |    **true**      |

### `CustomDraggable`

`CustomDraggable` ウィジェットは、`Draggable` または `LongPressDraggable` に追加するオプションの情報を含めることができるヘルパーです。

このウィジェットが、`GridView` に追加する予定の子要素をラップしていることを確認してください。ユニークキーを受け取る必要があります。

```dart
  CustomDraggable(
    // ここにユニークキーを追加します
    key: Key('unique'),
    // `Draggable` または `LongPressDraggable` に渡されます
    data: 'data',
    child: Placeholder(),
  ),
```

### `ReorderableRubberBandController`

`ReorderableRubberBandController` は、`ReorderableBuilder` 内部のアイテム情報（位置・サイズ・スクロールオフセット）を外部に配置した `ReorderableRubberBand` ウィジェットに公開するコントローラーです。

`ReorderableBuilder` の `rubberBandController` パラメータに渡してください。コントローラーは初期化時に自動的に attach され、破棄時に detach されます。

| **プロパティ**       | **説明**                                                                          |
|:-------------------|:----------------------------------------------------------------------------------|
| `childrenKeyMap`   | 全アイテムの `ValueKey.value` から `ReorderableEntity`（位置・サイズ）へのマップ。   |
| `scrollOffset`     | グリッドの現在のスクロールオフセット。                                              |
| `isDragging`       | リオーダードラッグが進行中かどうか。                                               |

### `ReorderableSelectionController`

`ReorderableSelectionController` は `GridView` 内の子要素の選択状態を管理するコントローラーです。
`TextEditingController` や `ScrollController` と同じパターンで使用します。

`ReorderableBuilder` の `selectionController` パラメータに渡すことで、外部から選択状態を制御できます（Controlled モード）。
渡さない場合は `ReorderableBuilder` が内部で自動生成します（Uncontrolled モード）。

| **メソッド / プロパティ**           | **説明**                                                                          |
|:------------------------------------|:----------------------------------------------------------------------------------|
| `selected`                          | 現在選択されている `Key` のセット（読み取り専用）。                               |
| `lastSelectedKey`                   | Shift+クリックの範囲選択の起点となる、最後に選択した `Key`。                      |
| `isSelected(key)`                   | 指定した `key` が現在選択されているか判定します。                                  |
| `select(key)`                       | 指定した `key` を選択します。                                                     |
| `deselect(key)`                     | 指定した `key` の選択を解除します。                                               |
| `toggle(key)`                       | 指定した `key` の選択状態をトグルします。                                         |
| `selectAll(keys)`                   | 指定した全ての `key` を選択します。                                               |
| `selectRange(...)`                  | `allKeys` を基準に `startKey` から `endKey` までの範囲を選択します。               |
| `clear()`                           | 全ての選択を解除します。                                                          |
| `removeStaleKeys(validKeys)`        | 無効になったキー（アイテム削除後など）を選択セットから取り除きます。              |

### `ReorderableGridDragStartListener`

ドラッグハンドル（例：三本線アイコン `≡`）をラップするウィジェットです。`buildDefaultDragHandles: false` と組み合わせて使用することで、そのハンドル部分をドラッグしたときのみ並び替えが開始されます。

```dart
ReorderableGridDragStartListener(
  index: index,
  child: const Icon(Icons.drag_handle),
)
```

`ReorderableGridDelayedDragStartListener` は長押しドラッグと同様の動作をするバリアントです（親の `enableLongPress` が有効な場合と同様）。

## バージョン `6.0.0` リリースのロードマップ
* 理解しやすくするためのコードのリファクタリング！

* `Wrap` のサポート 
  * アイテムの追加・削除時のアニメーション
  * ドラッグ＆ドロップ
  * GitHub Issue [#28](https://github.com/karvulf/flutter-reorderable-grid-view/issues/28)

## 今後の計画

機能のリクエストや問題の発見がありましたら、GitHub プロジェクトリポジトリで気軽に Issue をオープンしてください。

貢献（コントリビューション）も大歓迎です！新しい機能の提供やバグ修正を行いたい場合は、プルリクエストを作成してください。アップデートや修正の迅速なリリースに繋がります。

このパッケージをご利用いただきありがとうございます！
