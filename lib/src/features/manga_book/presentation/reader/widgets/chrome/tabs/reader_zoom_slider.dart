// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../../utils/extensions/custom_extensions.dart';
import '../../../controller/reader_zoom.dart';

/// Reader zoom control: a hand-drawn track instead of the stock Slider so the
/// 100% resting point can be marked and the whole row stays compact.
class ReaderZoomSlider extends StatelessWidget {
  const ReaderZoomSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: readerZoom,
      builder: (context, zoom, _) {
        final percent = (zoom * 100).round();
        return ListTile(
          leading: const Icon(FluentIcons.zoom_in_24_regular),
          title: Text(context.l10n.readerZoom),
          trailing: IconButton(
            tooltip: context.l10n.reset,
            onPressed: resetReaderZoom,
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: _ZoomTrack(
                  value: zoom,
                  onChanged: setReaderZoom,
                  trackColor: context.theme.colorScheme.surfaceContainerHighest,
                  activeColor: context.theme.colorScheme.primary,
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.end,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: zoom == 1.0
                        ? context.theme.colorScheme.onSurfaceVariant
                        : context.theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoomTrack extends StatelessWidget {
  const _ZoomTrack({
    required this.value,
    required this.onChanged,
    required this.trackColor,
    required this.activeColor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final Color trackColor;
  final Color activeColor;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void update(Offset localPosition) {
          final width = constraints.maxWidth;
          if (width <= 0) return;
          final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
          onChanged(kReaderZoomMin + ratio * (kReaderZoomMax - kReaderZoomMin));
        }

        return Semantics(
          slider: true,
          label: context.l10n.readerZoom,
          value: '${(value * 100).round()}%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => update(details.localPosition),
            onHorizontalDragStart: (details) => update(details.localPosition),
            onHorizontalDragUpdate: (details) => update(details.localPosition),
            child: CustomPaint(
              size: Size(constraints.maxWidth, _height),
              painter: _ZoomTrackPainter(
                value: value,
                trackColor: trackColor,
                activeColor: activeColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ZoomTrackPainter extends CustomPainter {
  const _ZoomTrackPainter({
    required this.value,
    required this.trackColor,
    required this.activeColor,
  });

  final double value;
  final Color trackColor;
  final Color activeColor;

  static const double _trackHeight = 6;
  static const double _thumbRadius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final left = _thumbRadius;
    final right = size.width - _thumbRadius;
    final centerY = size.height / 2;
    if (right <= left) return;

    final ratio = ((value - kReaderZoomMin) / (kReaderZoomMax - kReaderZoomMin))
        .clamp(0.0, 1.0);
    final thumbX = left + (right - left) * ratio;

    final trackPaint = Paint()..color = trackColor;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, centerY - _trackHeight / 2, right, centerY + _trackHeight / 2),
      const Radius.circular(_trackHeight / 2),
    );
    canvas.drawRRect(rect, trackPaint);

    final activePaint = Paint()..color = activeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          left,
          centerY - _trackHeight / 2,
          thumbX,
          centerY + _trackHeight / 2,
        ),
        const Radius.circular(_trackHeight / 2),
      ),
      activePaint,
    );

    // Mark 100% so the fit-to-screen point stays findable after zooming away.
    final restX = left + (right - left) * ((1 - kReaderZoomMin) / (kReaderZoomMax - kReaderZoomMin));
    if ((restX - thumbX).abs() > _thumbRadius) {
      canvas.drawLine(
        Offset(restX, centerY - 7),
        Offset(restX, centerY + 7),
        Paint()
          ..color = trackColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset(thumbX, centerY),
      _thumbRadius,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(_ZoomTrackPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.activeColor != activeColor;
}
