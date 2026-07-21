import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// ドラッグ操作中の自動スクロールを管理する共通コンポーネント。
///
/// リオーダードラッグとラバーバンド選択の両方から利用される。
/// ScrollController の所有権は利用側にあり、本クラスはドラッグ中のみ
/// [jumpTo] を呼び出して協調的にスクロールを制御する。
///
/// ## 設計方針
///
/// - 通常時はスクロールに一切干渉しない
/// - ドラッグ操作中のみ自動スクロールを行う（Cooperative パターン）
/// - ScrollController が null の場合、自動スクロールは無効
/// - リオーダードラッグとラバーバンドドラッグは排他的であり、同時に開始されない
class AutoScroller {
  /// 利用側が所有する ScrollController。
  ///
  /// null の場合でも [_scrollFunction] が設定されていれば自動スクロール可能。
  ScrollController? _scrollController;

  /// カスタムのスクロール実行関数。
  ///
  /// ScrollController が使えない場合（outer scrollable パターン）に使用する。
  /// 引数は delta（スクロール量）。
  /// [start] 呼び出し前に設定し、[stop] で自動的にクリアされる。
  void Function(double delta)? _scrollFunction;

  /// 自動スクロールが有効かどうか。
  bool _isActive = false;

  /// 最後に記録されたドラッグ位置（ビューポート座標系）。
  Offset? _lastDragPosition;

  /// ビューポートのサイズ。
  Size? _viewportSize;

  /// スクロール方向。
  Axis _scrollDirection = Axis.vertical;

  /// 自動スクロールを繰り返すタイマー。
  Timer? _scrollTimer;

  /// ビューポート端からのスクロール開始しきい値。
  ///
  /// インスタンス生成後は変更不可。動的に変更する場合は新しいインスタンスを生成すること。
  final double edgeThreshold;

  /// 最大スクロール速度（px/tick）。
  ///
  /// UX に合わせてチューニング可能。
  final double maxScrollSpeed;

  /// reverse モード（スクロール方向が反転）。
  bool reverse;

  /// スクロール位置変化時のコールバック。
  ///
  /// ドラッグ中にスクロールが発生した際、選択矩形の再計算などに使用する。
  VoidCallback? onScrollChanged;

  AutoScroller({
    this.edgeThreshold = 80.0,
    this.maxScrollSpeed = 10.0,
    this.reverse = false,
    this.onScrollChanged,
  });

  /// カスタムのスクロール実行関数を設定する。
  ///
  /// ScrollController が使えない場合（outer scrollable パターン）に、
  /// [start] 呼び出し前に設定する。[stop] 時に自動的にクリアされる。
  // ignore: use_setters_to_change_properties
  void setScrollFunction(void Function(double delta)? fn) {
    _scrollFunction = fn;
  }

  /// ScrollController を設定する。
  ///
  /// [initState] で呼び出し、[dispose] で [detach] する。
  void attach(ScrollController? controller) {
    if (_scrollController == controller) return;
    _detachListener();
    _scrollController = controller;
    _attachListener();
  }

  /// ScrollController との接続を解除する。
  void detach() {
    stop();
    _detachListener();
    _scrollController = null;
  }

  /// ScrollController が差し替わった場合に呼ぶ。
  ///
  /// [didUpdateWidget] で使用する。
  void updateController(ScrollController? newController) {
    if (_scrollController == newController) return;
    _detachListener();
    _scrollController = newController;
    _attachListener();
  }

  /// 自動スクロールを開始する。
  ///
  /// [viewportSize] はスクロール対象のビューポートサイズ。
  /// [scrollDirection] はスクロールの軸方向。
  void start({
    required Size viewportSize,
    Axis scrollDirection = Axis.vertical,
  }) {
    if (_scrollController == null && _scrollFunction == null) return;

    _isActive = true;
    _viewportSize = viewportSize;
    _scrollDirection = scrollDirection;

    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => _tick(),
    );
  }

  /// 自動スクロールを停止する。
  void stop() {
    _isActive = false;
    _lastDragPosition = null;
    _viewportSize = null;
    _scrollFunction = null;
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  /// ドラッグ位置を更新する。
  ///
  /// [position] はビューポート座標系でのドラッグ位置。
  void updateDragPosition(Offset position) {
    _lastDragPosition = position;
  }

  /// 自動スクロールが現在アクティブかどうか。
  bool get isActive => _isActive;

  /// ScrollController のリスナーを登録する。
  ///
  /// 常時登録し、ドラッグ中のみ処理する。
  void _attachListener() {
    _scrollController?.addListener(_handleScrollChanged);
  }

  /// ScrollController のリスナーを解除する。
  void _detachListener() {
    _scrollController?.removeListener(_handleScrollChanged);
  }

  /// スクロール位置変化ハンドラ。
  ///
  /// ドラッグ中のみコールバックを呼び出す。
  void _handleScrollChanged() {
    if (!_isActive) return;
    onScrollChanged?.call();
  }

  /// タイマーの毎フレーム処理。
  ///
  /// ドラッグ位置がビューポート端に近い場合、スクロールを実行する。
  void _tick() {
    if (!_isActive) return;

    final position = _lastDragPosition;
    final viewportSize = _viewportSize;

    if (position == null || viewportSize == null) return;
    if (_scrollController == null && _scrollFunction == null) return;

    final delta = _computeScrollDelta(
      position: position,
      viewportSize: viewportSize,
    );

    if (delta != 0.0) {
      _scrollBy(delta);
    }
  }

  /// ドラッグ位置とビューポートサイズからスクロール量を計算する。
  ///
  /// ビューポート端との距離に応じて加速する。
  double _computeScrollDelta({
    required Offset position,
    required Size viewportSize,
  }) {
    final double extent;
    final double maxExtent;

    if (_scrollDirection == Axis.vertical) {
      extent = position.dy;
      maxExtent = viewportSize.height;
    } else {
      extent = position.dx;
      maxExtent = viewportSize.width;
    }

    // 上端（または左端）に近い場合
    if (extent < edgeThreshold) {
      final t = 1.0 - (extent / edgeThreshold);
      final speed = _applySpeedCurve(t);
      return reverse ? speed : -speed;
    }

    // 下端（または右端）に近い場合
    if (maxExtent - extent < edgeThreshold) {
      final t = 1.0 - ((maxExtent - extent) / edgeThreshold);
      final speed = _applySpeedCurve(t);
      return reverse ? -speed : speed;
    }

    return 0.0;
  }

  /// 距離の比率からスクロール速度を算出する。
  ///
  /// 端に近いほど速くスクロールする。
  /// 最大速度は UX に合わせてチューニング可能。
  double _applySpeedCurve(double t) {
    final clamped = t.clamp(0.0, 1.0);
    // 距離に比例した線形スケーリング。最大速度は maxScrollSpeed。
    return lerpDouble(0, maxScrollSpeed, clamped)!;
  }

  /// 指定量だけスクロールする。
  void _scrollBy(double delta) {
    // カスタムスクロール関数が設定されている場合はそちらを使用
    if (_scrollFunction != null) {
      _scrollFunction!(delta);
      return;
    }

    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (next != position.pixels) {
      controller.jumpTo(next);
    }
  }
}
