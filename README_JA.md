[日本語] | [English](README.md)

![Pub Version](https://img.shields.io/pub/v/flutter_reorderable_grid_view_desktop?color=%23397ab6&style=flat-square)
![GitHub branch checks state](https://img.shields.io/github/checks-status/rmagiga/flutter-reorderable-grid-view/master?style=flat-square)

<p>
  <img src="https://github.com/rmagiga/flutter-reorderable-grid-view/blob/master/doc/animated_drag_and_drop.gif?raw=true"
    alt="An animated image of the iOS ReordableGridView UI" height="400"/>
  <img src="https://github.com/rmagiga/flutter-reorderable-grid-view/blob/master/doc/animated_items.gif?raw=true"
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
- [サポートされているウィジェット](#サポートされているウィジェット)
- [パラメータ](#パラメータ)
  - [AnimationConfig パラメータ](#animationconfig-パラメータ)
- [ロードマップ](#ロードマップ)
- [今後の計画](#今後の計画)


## 概要

このパッケージを使用すると、Flutter アプリを以下のように強化できます：

- アニメーション付きドラッグ＆ドロップ機能の有効化：
  - 任意の `GridView` とシームレスに動作します。
  - `GridView.builder` の場合、ドラッグ＆ドロップの実装には `ReorderableBuilder.builder` を使用します。
- グリッド内のアイテムの追加、削除、更新時にスムーズなアニメーションを追加します。

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
| `dragChildBoxDecoration`       | 子要素がドラッグされているとき、ドラッグされた子要素のデフォルトの `BoxDecoration` をオーバーライドできます。                  |       **-**       |
| `reverse`                      | 子要素の順序を反転して処理します。スクロール可能ウィジェットとこのウィジェットの両方にこのフラグを追加してください。            |     **false**     |
| `builder`                      | 更新された `children` を取得するために `ReorderableBuilder` を使用する必要があります。                                      |       **-**       |
| `onReorder`                    | ドラッグされた子要素を離した後に呼び出されます。すべてのアイテムを並べ替えるための関数がパラメータとして含まれています。             |       **-**       |
| `onDragStarted`                | ドラッグが開始されたときに、開始されたインデックスとともに呼び出されるコールバック。                                               |       **-**       |
| `onDragEnd`                    | ドラッグされた子要素が離されたときに、そのインデックスとともに呼び出されるコールバック。                                           |       **-**       |
| `onUpdatedDraggedChild`        | ドラッグ中にドラッグされた子要素の位置が更新されたときに呼び出されます。                                                       |       **-**       |
| `scrollController`             | スクロール可能なウィジェットにも割り当てる必要がある `ScrollController`。アニメーションの問題を防ぐために、これを忘れないでください。 |       **-**       |

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
