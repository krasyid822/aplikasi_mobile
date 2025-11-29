#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"
#include <fstream>
#include <sstream>
#include <string>

// Try to create a DispatcherQueueController on Win32 so components that
// require a DispatcherQueue (like WebView2 offscreen rendering) succeed.
static IUnknown* g_dispatcher_queue_controller = nullptr;

static void DebugLog(const std::wstring& msg) {
  // Output to the debugger output
  ::OutputDebugStringW(msg.c_str());

  // Also append to a file in the user's temp directory for easier inspection
  wchar_t temp_path[MAX_PATH] = {0};
  if (::GetTempPathW(MAX_PATH, temp_path)) {
    std::wstring path = temp_path;
    path += L"dispatcher_debug.txt";
    std::wofstream f;
    f.open(path, std::ios::out | std::ios::app);
    if (f) {
      f << msg << L"\r\n";
      f.close();
    }
  }
}

static void DebugLogFormat(const wchar_t* fmt, ...) {
  va_list args;
  va_start(args, fmt);
  wchar_t buf[1024];
  vswprintf_s(buf, fmt, args);
  va_end(args);
  DebugLog(std::wstring(buf));
}

static bool EnsureDispatcherQueueController() {
  if (g_dispatcher_queue_controller) return true;

  DebugLog(L"EnsureDispatcherQueueController: start\n");

  // Load CoreMessaging.dll which exports CreateDispatcherQueueController
  HMODULE core = ::LoadLibraryW(L"CoreMessaging.dll");
  if (!core) {
    DebugLog(L"EnsureDispatcherQueueController: CoreMessaging.dll not found, trying lowercase name\n");
    core = ::LoadLibraryW(L"coremessaging.dll");
    if (!core) {
      DWORD err = ::GetLastError();
      DebugLogFormat(L"EnsureDispatcherQueueController: LoadLibrary failed, GetLastError=0x%08X\n", err);
      return false;
    }
  }

  DebugLog(L"EnsureDispatcherQueueController: CoreMessaging loaded successfully\n");

  typedef HRESULT(WINAPI* PFNCreateDispatcherQueueController)(void* options, IUnknown** controller);
  auto fn = reinterpret_cast<PFNCreateDispatcherQueueController>(::GetProcAddress(core, "CreateDispatcherQueueController"));
  if (!fn) {
    DWORD err = ::GetLastError();
    DebugLogFormat(L"EnsureDispatcherQueueController: GetProcAddress failed, GetLastError=0x%08X\n", err);
    return false;
  }

  DebugLog(L"EnsureDispatcherQueueController: Found CreateDispatcherQueueController symbol\n");

  // Minimal options struct (matches DispatcherQueueOptions layout)
  struct DispatcherQueueOptions {
    unsigned int dwSize;
    unsigned int threadType;
    unsigned int apartmentType;
  } options;

  options.dwSize = sizeof(options);
  // DQTHREAD_CURRENT (2) / DQTAT_COM_NONE (1) are the values used by samples
  options.threadType = 2;
  options.apartmentType = 1;

  IUnknown* controller = nullptr;
  HRESULT hr = fn(&options, &controller);
  DebugLogFormat(L"EnsureDispatcherQueueController: CreateDispatcherQueueController returned HRESULT=0x%08X\n", hr);
  if (SUCCEEDED(hr) && controller) {
    // Keep a reference for the lifetime of the process so dispatcher stays alive
    controller->AddRef();
    g_dispatcher_queue_controller = controller;
    DebugLog(L"EnsureDispatcherQueueController: dispatcher controller created and stored\n");
    return true;
  }

  // If controller is non-null but SUCCEEDED didn't hold, still release safely
  if (controller) {
    controller->Release();
  }

  DebugLog(L"EnsureDispatcherQueueController: failed to create dispatcher controller\n");
  return false;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Ensure DispatcherQueueController exists for WebView2 and related components.
  EnsureDispatcherQueueController();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Aplikasi Mobile", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
