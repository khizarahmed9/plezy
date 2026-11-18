#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <memory>
#include <optional>

#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;

  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> window_channel_;

  // Fullscreen state tracking for monitor-aware native fullscreen.
  // Maximize state lives inside `placement_before_fullscreen_.showCmd`.
  bool is_fullscreen_ = false;
  WINDOWPLACEMENT placement_before_fullscreen_{};
  LONG_PTR style_before_fullscreen_ = 0;
  LONG_PTR ex_style_before_fullscreen_ = 0;

  // Taskbar thumbnail toolbar (previous / play-pause / next), driven by
  // setThumbButtons on the window channel. No value in thumb_playing_ means
  // nothing is playing and the buttons are hidden.
  const UINT taskbar_button_created_message_ = ::RegisterWindowMessageW(L"TaskbarButtonCreated");
  Microsoft::WRL::ComPtr<ITaskbarList3> taskbar_;
  std::optional<bool> thumb_playing_;
  bool thumb_can_play_pause_ = false;
  bool thumb_can_previous_ = false;
  bool thumb_can_next_ = false;

  void RegisterWindowChannel();
  void ApplyThumbButtons(bool add);
  void SetNativeFullScreen(bool fullscreen);
  void NotifyFullScreenChanged();
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
