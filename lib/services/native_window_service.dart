import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'fullscreen_state_manager.dart';

/// Windows-only native window wrapper for behavior that lives in the Win32
/// runner (windows/runner/flutter_window.cpp): a monitor-aware fullscreen
/// implementation that works around window_manager's multi-monitor fullscreen
/// bug (edde746/plezy#880), and a frame theme the app controls, which
/// window_manager cannot set darker than the OS app theme.
///
/// No-op on non-Windows platforms — callers should keep using
/// `MacOSWindowService` on macOS and `window_manager` on Linux.
class NativeWindowService {
  static const _channel = MethodChannel('plezy/window');
  static bool _initialized = false;
  static final _thumbButtonEvents = StreamController<MediaControlEvent>.broadcast();

  /// Clicks on the taskbar thumbnail toolbar, as the media control events the
  /// OS session would send for the same buttons.
  static Stream<MediaControlEvent> get thumbButtonEvents => _thumbButtonEvents.stream;

  /// Hook the native → Dart callback that keeps [FullscreenStateManager] in
  /// sync with OS-driven fullscreen transitions. Safe to call more than once.
  static void initialize() {
    if (!Platform.isWindows || _initialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFullScreenChanged') {
      final value = call.arguments;
      if (value is bool) {
        FullscreenStateManager().setFullscreen(value);
      }
    } else if (call.method == 'onThumbButton') {
      final event = switch (call.arguments) {
        'previous' => const PreviousTrackEvent(),
        'playPause' => const TogglePlayPauseEvent(),
        'next' => const NextTrackEvent(),
        _ => null,
      };
      if (event != null) _thumbButtonEvents.add(event);
    }
  }

  /// Enter or exit native fullscreen on the current monitor.
  static Future<void> setFullScreen(bool isFullScreen) async {
    if (!Platform.isWindows) return;
    await _channel.invokeMethod('setFullScreen', {'isFullScreen': isFullScreen});
  }

  /// Query the native fullscreen state. Returns false off-Windows.
  static Future<bool> isFullScreen() async {
    if (!Platform.isWindows) return false;
    return await _channel.invokeMethod<bool>('isFullScreen') ?? false;
  }

  /// Theme the window frame (title bar) dark or light. The runner follows the
  /// OS app theme until the first call.
  static Future<void> setDarkMode(bool dark) async {
    if (!Platform.isWindows) return;
    await _channel.invokeMethod<void>('setDarkMode', dark);
  }

  /// Update the taskbar thumbnail toolbar. [playing] null hides the buttons.
  static Future<void> setThumbButtons({
    required bool? playing,
    required bool canPlayPause,
    required bool canPrevious,
    required bool canNext,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    await _channel.invokeMethod<void>('setThumbButtons', {
      'playing': playing,
      'canPlayPause': canPlayPause,
      'canPrevious': canPrevious,
      'canNext': canNext,
    });
  }
}
