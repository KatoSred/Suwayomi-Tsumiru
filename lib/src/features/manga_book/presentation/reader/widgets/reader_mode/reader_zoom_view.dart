// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../../utils/motion/reduce_motion.dart';
import '../../../../../../widgets/zoom/zoom_view.dart';
import '../../controller/reader_zoom.dart';

class ReaderZoomView extends HookWidget {
  const ReaderZoomView({
    super.key,
    required this.controller,
    required this.scrollAxis,
    this.reverse = false,
    required this.maxScale,
    required this.minScale,
    required this.pinchEnabled,
    required this.doubleTapToZoom,
    this.onScaleChanged,
    this.sessionZoom,
    required this.child,
  });

  final ScrollController controller;
  final Axis scrollAxis;

  /// Must match the wrapped scrollable's own `reverse` (e.g. an RTL manga's
  /// continuous-horizontal strip) — see [ZoomView.reverse] for why.
  final bool reverse;
  final double maxScale;
  final double minScale;
  final bool pinchEnabled;
  final bool doubleTapToZoom;

  /// Invoked with the live user-facing scale (1.0 = unzoomed) any time it
  /// changes, e.g. so callers can yield competing single-finger gestures
  /// (chapter-swipe) while the reader is zoomed in.
  final ValueChanged<double>? onScaleChanged;

  /// Session zoom shared with the settings slider and Ctrl + wheel. Applied
  /// here, and the view's own scale is reported back so the slider follows
  /// pinches and double taps.
  final ValueNotifier<double>? sessionZoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final zoomController = useMemoized(ZoomViewController.new);
    final zoomInTarget = maxScale < 3.0 ? maxScale : 3.0;

    // External zoom (slider / Ctrl + wheel). The controller only exists after
    // the ZoomView attaches, so the first application is deferred a frame.
    useEffect(() {
      final listenable = sessionZoom;
      if (listenable == null) return null;
      void apply() {
        if (!zoomController.isAttached) return;
        final target = listenable.value;
        if (!readerZoomDiffers(zoomController.scale, target)) return;
        zoomController.setScale(target);
      }

      listenable.addListener(apply);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (listenable == sessionZoom) apply();
      });
      return () => listenable.removeListener(apply);
    }, [sessionZoom, zoomController]);


    // Read live scale for each double tap so intervening pinches cannot desynchronise the toggle.
    void onDoubleTap(TapDownDetails details) {
      if (!zoomController.isAttached) return;
      final target = zoomController.scale > 1.01 ? 1.0 : zoomInTarget;
      zoomController.setScaleWithAnimation(
        target,
        duration: context.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 150),
        focalPoint: details.localPosition,
      );
    }

    return ZoomView(
      controller: controller,
      zoomViewController: zoomController,
      scrollAxis: scrollAxis,
      reverse: reverse,
      maxScale: maxScale,
      minScale: minScale,
      pinchEnabled: pinchEnabled,
      onDoubleTap: doubleTapToZoom ? onDoubleTap : null,
      onScaleChanged: (scale) {
        final listenable = sessionZoom;
        if (listenable != null && readerZoomDiffers(listenable.value, scale)) {
          listenable.value = clampReaderZoom(scale);
        }
        onScaleChanged?.call(scale);
      },
      // Hold the scrollable so the scale recognizer can win its gesture arena.
      forceHoldOnPointerDown: true,
      child: child,
    );
  }
}
