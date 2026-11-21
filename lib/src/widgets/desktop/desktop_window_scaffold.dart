// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../routes/router_config.dart';
import '../../utils/desktop/window_fullscreen.dart';
import '../../utils/platform/platform_runtime.dart';
import 'desktop_title_bar.dart';
import 'desktop_top_bar.dart';
import 'linux_window_frame.dart';

/// Native title strip appears only without a displayed merged bar; reserve its height above content.
/// Fullscreen drops the strip entirely — window buttons are window chrome, not content.
class DesktopWindowScaffold extends ConsumerWidget {
  const DesktopWindowScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktopPlatform) return child;
    final mergedBarVisible = ref.watch(mergedTopBarRegistryProvider) > 0;
    // Keep Router mounted: re-parsing route info loses non-JSON extras on resize.
    final showTitleBar = !(showsMergedTopBar(context) && mergedBarVisible);
    final routes = ref.watch(routerConfigProvider);

    return _FullscreenHotkey(
      child: ValueListenableBuilder<bool>(
        valueListenable: desktopWindowFullscreen,
        builder: (context, fullscreen, _) {
          final content = Column(
            children: [
              if (showTitleBar && !fullscreen)
                ListenableBuilder(
                  listenable: routes.routerDelegate,
                  builder: (context, _) =>
                      DesktopTitleBar(hideBrand: _isOnboarding(routes)),
                )
              else
                const SizedBox.shrink(),
              Expanded(child: child),
            ],
          );
          return !kIsWeb && defaultTargetPlatform == TargetPlatform.linux
              ? LinuxWindowFrame(child: content)
              : content;
        },
      ),
    );
  }
}

/// F12 toggles fullscreen app-wide, independent of which widget holds focus.
class _FullscreenHotkey extends StatefulWidget {
  const _FullscreenHotkey({required this.child});

  final Widget child;

  @override
  State<_FullscreenHotkey> createState() => _FullscreenHotkeyState();
}

class _FullscreenHotkeyState extends State<_FullscreenHotkey> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.f12) return false;
    toggleDesktopWindowFullscreen();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _isOnboarding(GoRouter routes) {
  try {
    final configuration = routes.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return false;
    return configuration.matches.last.matchedLocation ==
        const OnboardingRoute().location;
  } catch (_) {
    return false;
  }
}
