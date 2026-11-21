// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../platform/platform_runtime.dart';

/// True while the desktop window has been enlarged over the whole monitor.
///
/// window_manager's own `setFullScreen` only resizes windows that still have a
/// native frame (`if (!is_frameless_)` in its Windows implementation), and this
/// app is frameless on Windows — calling it does nothing there. So fullscreen is
/// done by hand: cover the monitor rect and stay on top, which is also what
/// hides the taskbar.
final ValueNotifier<bool> desktopWindowFullscreen = ValueNotifier<bool>(false);

bool get supportsWindowFullscreen => !kIsWeb && isDesktopPlatform;

Rect? _restoreBounds;
bool _restoreMaximized = false;

Future<Rect?> _monitorRect() async {
  final displays = await screenRetriever.getAllDisplays();
  if (displays.isEmpty) return null;
  final bounds =
      await windowManager.getBounds().catchError((_) => Rect.zero);
  final center = bounds.center;

  Display? chosen;
  for (final display in displays) {
    final origin = display.visiblePosition ?? Offset.zero;
    final rect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      display.size.width,
      display.size.height,
    );
    if (rect.contains(center)) {
      chosen = display;
      break;
    }
  }
  final display = chosen ?? await screenRetriever.getPrimaryDisplay();
  final origin = display.visiblePosition ?? Offset.zero;
  return Rect.fromLTWH(
    origin.dx,
    origin.dy,
    display.size.width,
    display.size.height,
  );
}

Future<void> _enter() async {
  final rect = await _monitorRect();
  if (rect == null) return;
  // Set the flag first: the geometry listener must not record the in-between
  // sizes while the window is being resized.
  desktopWindowFullscreen.value = true;
  _restoreMaximized = await windowManager.isMaximized();
  _restoreBounds = await windowManager.getBounds();
  // A maximized window ignores setBounds, so drop back to normal size first.
  if (_restoreMaximized) await windowManager.unmaximize();
  await windowManager.setAlwaysOnTop(true);
  await windowManager.setBounds(rect);
}

Future<void> _exit() async {
  await windowManager.setAlwaysOnTop(false);
  final restore = _restoreBounds;
  if (_restoreMaximized) {
    await windowManager.maximize();
  } else if (restore != null) {
    await windowManager.setBounds(restore);
  }
  // Cleared last so the restore itself is not written to the saved geometry.
  desktopWindowFullscreen.value = false;
}

Future<void> toggleDesktopWindowFullscreen() async {
  if (!supportsWindowFullscreen) return;
  try {
    if (desktopWindowFullscreen.value) {
      await _exit();
    } else {
      await _enter();
    }
  } catch (_) {
    // Never leave the flag claiming a state the window is not in.
    desktopWindowFullscreen.value = false;
  }
}

/// Leaving the reader must not trap the user in a taskbar-less window.
Future<void> exitDesktopWindowFullscreen() async {
  if (!supportsWindowFullscreen) return;
  if (!desktopWindowFullscreen.value) return;
  try {
    await _exit();
  } catch (_) {
    desktopWindowFullscreen.value = false;
  }
}
