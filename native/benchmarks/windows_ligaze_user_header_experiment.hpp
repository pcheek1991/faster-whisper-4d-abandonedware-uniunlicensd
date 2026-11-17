// SPDX-License-Identifier: 0BSD
// User-specified Windows header, EXPLICIT EXPERIMENT ONLY.
// Dangerous: void variadic no-op overloads can swallow real Win32 calls.
// They are NOT runtime optimizers; do not enable in shipping binaries.
#pragma once
#if !defined(_WIN32)
#error "Windows-only experiment"
#endif
#ifndef STRICT
#define STRICT
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#undef ERROR
#undef DELETE
#undef IN
#undef OUT
#undef OPTIONAL
#undef NEAR
#undef FAR
#undef near
#undef far
#undef STRICT
#undef DIFFERENCE
#undef RELATIVE
#undef ABSOLUTE
#undef TRANSPARENT
#undef OPAQUE
#undef IGNORE
#undef INFINITE
#undef NO_ERROR
#undef STATUS_PENDING
#undef DOMAIN
#undef interface
#undef small

#undef CreateFile
inline void CreateFile(...) {}

#undef CreateFileA
inline void CreateFileA(...) {}

#undef CreateFileW
inline void CreateFileW(...) {}

#undef DeleteFile
inline void DeleteFile(...) {}

#undef DeleteFileA
inline void DeleteFileA(...) {}

#undef DeleteFileW
inline void DeleteFileW(...) {}

#undef CopyFile
inline void CopyFile(...) {}

#undef CopyFileA
inline void CopyFileA(...) {}

#undef CopyFileW
inline void CopyFileW(...) {}

#undef MoveFile
inline void MoveFile(...) {}

#undef MoveFileA
inline void MoveFileA(...) {}

#undef MoveFileW
inline void MoveFileW(...) {}

#undef CreateDirectory
inline void CreateDirectory(...) {}

#undef CreateDirectoryA
inline void CreateDirectoryA(...) {}

#undef CreateDirectoryW
inline void CreateDirectoryW(...) {}

#undef RemoveDirectory
inline void RemoveDirectory(...) {}

#undef RemoveDirectoryA
inline void RemoveDirectoryA(...) {}

#undef RemoveDirectoryW
inline void RemoveDirectoryW(...) {}

#undef GetCurrentDirectory
inline void GetCurrentDirectory(...) {}

#undef GetCurrentDirectoryA
inline void GetCurrentDirectoryA(...) {}

#undef GetCurrentDirectoryW
inline void GetCurrentDirectoryW(...) {}

#undef SetCurrentDirectory
inline void SetCurrentDirectory(...) {}

#undef SetCurrentDirectoryA
inline void SetCurrentDirectoryA(...) {}

#undef SetCurrentDirectoryW
inline void SetCurrentDirectoryW(...) {}

#undef GetTempPath
inline void GetTempPath(...) {}

#undef GetTempPathA
inline void GetTempPathA(...) {}

#undef GetTempPathW
inline void GetTempPathW(...) {}

#undef FindFirstFile
inline void FindFirstFile(...) {}

#undef FindFirstFileA
inline void FindFirstFileA(...) {}

#undef FindFirstFileW
inline void FindFirstFileW(...) {}

#undef FindNextFile
inline void FindNextFile(...) {}

#undef FindNextFileA
inline void FindNextFileA(...) {}

#undef FindNextFileW
inline void FindNextFileW(...) {}

#undef CreateProcess
inline void CreateProcess(...) {}

#undef CreateProcessA
inline void CreateProcessA(...) {}

#undef CreateProcessW
inline void CreateProcessW(...) {}

#undef CreateThread
inline void CreateThread(...) {}

#undef ExitThread
inline void ExitThread(...) {}

#undef TerminateThread
inline void TerminateThread(...) {}

#undef CreateMutex
inline void CreateMutex(...) {}

#undef CreateMutexA
inline void CreateMutexA(...) {}

#undef CreateMutexW
inline void CreateMutexW(...) {}

#undef CreateEvent
inline void CreateEvent(...) {}

#undef CreateEventA
inline void CreateEventA(...) {}

#undef CreateEventW
inline void CreateEventW(...) {}

#undef OpenEvent
inline void OpenEvent(...) {}

#undef OpenEventA
inline void OpenEventA(...) {}

#undef OpenEventW
inline void OpenEventW(...) {}

#undef CreateSemaphore
inline void CreateSemaphore(...) {}

#undef CreateSemaphoreA
inline void CreateSemaphoreA(...) {}

#undef CreateSemaphoreW
inline void CreateSemaphoreW(...) {}

#undef Yield
inline void Yield(...) {}

#undef Sleep
inline void Sleep(...) {}

#undef LoadLibrary
inline void LoadLibrary(...) {}

#undef LoadLibraryA
inline void LoadLibraryA(...) {}

#undef LoadLibraryW
inline void LoadLibraryW(...) {}

#undef GetModuleHandle
inline void GetModuleHandle(...) {}

#undef GetModuleHandleA
inline void GetModuleHandleA(...) {}

#undef GetModuleHandleW
inline void GetModuleHandleW(...) {}

#undef GetModuleFileName
inline void GetModuleFileName(...) {}

#undef GetModuleFileNameA
inline void GetModuleFileNameA(...) {}

#undef GetModuleFileNameW
inline void GetModuleFileNameW(...) {}

#undef GetProcAddress
inline void GetProcAddress(...) {}

#undef FormatMessage
inline void FormatMessage(...) {}

#undef FormatMessageA
inline void FormatMessageA(...) {}

#undef FormatMessageW
inline void FormatMessageW(...) {}

#undef OutputDebugString
inline void OutputDebugString(...) {}

#undef OutputDebugStringA
inline void OutputDebugStringA(...) {}

#undef OutputDebugStringW
inline void OutputDebugStringW(...) {}

#undef CopyMemory
inline void CopyMemory(...) {}

#undef MoveMemory
inline void MoveMemory(...) {}

#undef FillMemory
inline void FillMemory(...) {}

#undef ZeroMemory
inline void ZeroMemory(...) {}

#undef GetMessage
inline void GetMessage(...) {}

#undef GetMessageA
inline void GetMessageA(...) {}

#undef GetMessageW
inline void GetMessageW(...) {}

#undef PeekMessage
inline void PeekMessage(...) {}

#undef PeekMessageA
inline void PeekMessageA(...) {}

#undef PeekMessageW
inline void PeekMessageW(...) {}

#undef SendMessage
inline void SendMessage(...) {}

#undef SendMessageA
inline void SendMessageA(...) {}

#undef SendMessageW
inline void SendMessageW(...) {}

#undef PostMessage
inline void PostMessage(...) {}

#undef PostMessageA
inline void PostMessageA(...) {}

#undef PostMessageW
inline void PostMessageW(...) {}

#undef DispatchMessage
inline void DispatchMessage(...) {}

#undef DispatchMessageA
inline void DispatchMessageA(...) {}

#undef DispatchMessageW
inline void DispatchMessageW(...) {}

#undef MessageBox
inline void MessageBox(...) {}

#undef MessageBoxA
inline void MessageBoxA(...) {}

#undef MessageBoxW
inline void MessageBoxW(...) {}

#undef CreateWindow
inline void CreateWindow(...) {}

#undef CreateWindowA
inline void CreateWindowA(...) {}

#undef CreateWindowW
inline void CreateWindowW(...) {}

#undef CreateWindowEx
inline void CreateWindowEx(...) {}

#undef CreateWindowExA
inline void CreateWindowExA(...) {}

#undef CreateWindowExW
inline void CreateWindowExW(...) {}

#undef RegisterClass
inline void RegisterClass(...) {}

#undef RegisterClassA
inline void RegisterClassA(...) {}

#undef RegisterClassW
inline void RegisterClassW(...) {}

#undef RegisterClassEx
inline void RegisterClassEx(...) {}

#undef RegisterClassExA
inline void RegisterClassExA(...) {}

#undef RegisterClassExW
inline void RegisterClassExW(...) {}

#undef GetClassName
inline void GetClassName(...) {}

#undef GetClassNameA
inline void GetClassNameA(...) {}

#undef GetClassNameW
inline void GetClassNameW(...) {}

#undef GetWindowText
inline void GetWindowText(...) {}

#undef GetWindowTextA
inline void GetWindowTextA(...) {}

#undef GetWindowTextW
inline void GetWindowTextW(...) {}

#undef SetWindowText
inline void SetWindowText(...) {}

#undef SetWindowTextA
inline void SetWindowTextA(...) {}

#undef SetWindowTextW
inline void SetWindowTextW(...) {}

#undef FindWindow
inline void FindWindow(...) {}

#undef FindWindowA
inline void FindWindowA(...) {}

#undef FindWindowW
inline void FindWindowW(...) {}

#undef SetProp
inline void SetProp(...) {}

#undef SetPropA
inline void SetPropA(...) {}

#undef SetPropW
inline void SetPropW(...) {}

#undef GetProp
inline void GetProp(...) {}

#undef GetPropA
inline void GetPropA(...) {}

#undef GetPropW
inline void GetPropW(...) {}

#undef RemoveProp
inline void RemoveProp(...) {}

#undef RemovePropA
inline void RemovePropA(...) {}

#undef RemovePropW
inline void RemovePropW(...) {}

#undef GetObject
inline void GetObject(...) {}

#undef GetObjectA
inline void GetObjectA(...) {}

#undef GetObjectW
inline void GetObjectW(...) {}

#undef CreateFont
inline void CreateFont(...) {}

#undef CreateFontA
inline void CreateFontA(...) {}

#undef CreateFontW
inline void CreateFontW(...) {}

#undef DrawText
inline void DrawText(...) {}

#undef DrawTextA
inline void DrawTextA(...) {}

#undef DrawTextW
inline void DrawTextW(...) {}

#undef TextOut
inline void TextOut(...) {}

#undef TextOutA
inline void TextOutA(...) {}

#undef TextOutW
inline void TextOutW(...) {}

#undef Polygon
inline void Polygon(...) {}

#undef Rectangle
inline void Rectangle(...) {}

#undef Ellipse
inline void Ellipse(...) {}

#undef RGB
inline void RGB(...) {}

#undef GetUserName
inline void GetUserName(...) {}

#undef GetUserNameA
inline void GetUserNameA(...) {}

#undef GetUserNameW
inline void GetUserNameW(...) {}

#undef GetComputerName
inline void GetComputerName(...) {}

#undef GetComputerNameA
inline void GetComputerNameA(...) {}

#undef GetComputerNameW
inline void GetComputerNameW(...) {}

#undef GetEnvironmentVariable
inline void GetEnvironmentVariable(...) {}

#undef GetEnvironmentVariableA
inline void GetEnvironmentVariableA(...) {}

#undef GetEnvironmentVariableW
inline void GetEnvironmentVariableW(...) {}

#undef SetEnvironmentVariable
inline void SetEnvironmentVariable(...) {}

#undef SetEnvironmentVariableA
inline void SetEnvironmentVariableA(...) {}

#undef SetEnvironmentVariableW
inline void SetEnvironmentVariableW(...) {}

#undef GetCommandLine
inline void GetCommandLine(...) {}

#undef GetCommandLineA
inline void GetCommandLineA(...) {}

#undef GetCommandLineW
inline void GetCommandLineW(...) {}

#undef GetVersion
inline void GetVersion(...) {}

#undef GetVersionEx
inline void GetVersionEx(...) {}

#undef GetVersionExA
inline void GetVersionExA(...) {}

#undef GetVersionExW
inline void GetVersionExW(...) {}

#undef RegOpenKey
inline void RegOpenKey(...) {}

#undef RegOpenKeyA
inline void RegOpenKeyA(...) {}

#undef RegOpenKeyW
inline void RegOpenKeyW(...) {}

#undef RegOpenKeyEx
inline void RegOpenKeyEx(...) {}

#undef RegOpenKeyExA
inline void RegOpenKeyExA(...) {}

#undef RegOpenKeyExW
inline void RegOpenKeyExW(...) {}

#undef RegCreateKeyEx
inline void RegCreateKeyEx(...) {}

#undef RegCreateKeyExA
inline void RegCreateKeyExA(...) {}

#undef RegCreateKeyExW
inline void RegCreateKeyExW(...) {}

#undef RegQueryValueEx
inline void RegQueryValueEx(...) {}

#undef RegQueryValueExA
inline void RegQueryValueExA(...) {}

#undef RegQueryValueExW
inline void RegQueryValueExW(...) {}

#undef RegSetValueEx
inline void RegSetValueEx(...) {}

#undef RegSetValueExA
inline void RegSetValueExA(...) {}

#undef RegSetValueExW
inline void RegSetValueExW(...) {}

#undef RegDeleteValue
inline void RegDeleteValue(...) {}

#undef RegDeleteValueA
inline void RegDeleteValueA(...) {}

#undef RegDeleteValueW
inline void RegDeleteValueW(...) {}

#undef CreateService
inline void CreateService(...) {}

#undef CreateServiceA
inline void CreateServiceA(...) {}

#undef CreateServiceW
inline void CreateServiceW(...) {}

#undef OpenService
inline void OpenService(...) {}

#undef OpenServiceA
inline void OpenServiceA(...) {}

#undef OpenServiceW
inline void OpenServiceW(...) {}

#undef StartService
inline void StartService(...) {}

#undef StartServiceA
inline void StartServiceA(...) {}

#undef StartServiceW
inline void StartServiceW(...) {}

// EXPERIMENTAL INPUT FIDELITY: all requested untyped do-nothing overloads above.
