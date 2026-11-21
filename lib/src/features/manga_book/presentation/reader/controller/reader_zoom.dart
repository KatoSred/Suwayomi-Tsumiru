// Copyright (c) 2026 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';

/// Session-only reader zoom, 1.0 being fit-to-screen.
///
/// Deliberately not persisted: leaving the reader resets it, so no DB key and
/// no server meta are involved. Paged mode additionally resets it on every
/// page turn, see `PagedReaderViewport`.
const double kReaderZoomMin = 0.5;
const double kReaderZoomMax = 3.0;

/// One Ctrl + wheel notch.
const double kReaderZoomWheelStep = 0.05;

/// Shared by the reader content, the settings slider and the Ctrl + wheel
/// handler. Every writer clamps through [clampReaderZoom].
final ValueNotifier<double> readerZoom = ValueNotifier<double>(1.0);

double clampReaderZoom(double value) =>
    value.clamp(kReaderZoomMin, kReaderZoomMax).toDouble();

void setReaderZoom(double value) => readerZoom.value = clampReaderZoom(value);

void stepReaderZoom(double delta) => setReaderZoom(readerZoom.value + delta);

void resetReaderZoom() {
  if (readerZoom.value != 1.0) readerZoom.value = 1.0;
}

/// True when two zooms differ enough to be worth propagating. Views apply the
/// external value and report their own scale back to the same notifier, so
/// every hops needs a dead zone or the two ping-pong forever.
bool readerZoomDiffers(double a, double b) => (a - b).abs() > 0.001;
