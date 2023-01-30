.386
.model flat, stdcall
option casemap:NONE

include windows.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

.data
	g_szWindowClass db "first masm32 window class", 0
	g_szTitle db "CR44 第一个汇编窗口", 0

	g_bTimerState dw 0
	g_szTime db 255 dup(0)
	g_TimeFormat db "%d-%d-%d,%d:%d:%d", 0

.code

; 过程函数
WndProc proc hWnd:HWND, message:UINT, wParam:WPARAM, lParam:LPARAM
	local @ps:PAINTSTRUCT
	local @hdc:HDC
	local @st:SYSTEMTIME
	local @rc:RECT
	local @nLen:DWORD


	; 初始化局部变量
	invoke RtlZeroMemory, addr @ps, size @ps
	invoke RtlZeroMemory, addr @st, size @st
	invoke RtlZeroMemory, addr @rc, size @rc
	mov @hdc, 0

	; 手工设置全区位无效区
	.IF message == WM_TIMER
		invoke InvalidateRect, hWnd, NULL, TRUE
	
	; 绘制时间
	.ELSEIF message == WM_PAINT
		; 创建DC
		invoke BeginPaint, hWnd, addr @ps
		mov @hdc, eax

		;获取当前系统时间
		invoke GetLocalTime, addr @st

		;以本地时间格式
		invoke wsprintf, offset g_szTime, offset g_TimeFormat, @st.wYear, \
		@st.wMonth, @st.wDay, @st.wHour, @st.wMinute, @st.wSecond

		; 显示范围
		invoke GetClientRect, hWnd, addr @rc

		; 获取字符串长度
		invoke lstrlen, offset g_szTime
		mov @nLen, eax

		; 绘制文本
		invoke DrawText, @hdc, offset g_szTime, @nLen, addr @rc, \
		DT_CENTER or DT_VCENTER or DT_SINGLELINE

		; 开启定时器
		.if g_bTimerState == 0
			invoke SetTimer, hWnd, 1, 1000, NULL
			mov g_bTimerState, 1
		.endif

	; 退出消息循环
	.ELSEIF message == WM_DESTROY
		invoke PostQuitMessage, 0
	.else
		invoke DefWindowProc, hWnd, message, wParam, lParam
		ret
	.endif



	xor eax, eax
	ret
WndProc endp

WinMain proc hInstance:HINSTANCE
	local @wc:WNDCLASS
	local @hWnd:HWND
	local @msg:MSG

	; 初始化局部变量
	invoke RtlZeroMemory, addr @wc, size @wc
	invoke RtlZeroMemory, addr @msg, size @msg
	mov @hWnd, 0

	; 注册窗口类
	mov @wc.style, CS_HREDRAW or CS_VREDRAW
	mov @wc.lpfnWndProc, offset WndProc
	mov eax, hInstance
	mov @wc.hInstance, eax
	invoke LoadIcon, NULL, IDI_APPLICATION
	mov @wc.hIcon, eax
	invoke LoadCursor, NULL, IDC_ARROW
	mov @wc.hCursor, eax
	mov @wc.hbrBackground, COLOR_GRAYTEXT + 1
	mov @wc.lpszClassName, offset g_szWindowClass

	invoke RegisterClass, addr @wc

	; 创建窗口实例
	invoke CreateWindowEx, 0, offset g_szWindowClass, offset g_szTitle, \
	WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL
	mov @hWnd, eax

	; 显示窗口
	invoke ShowWindow, @hWnd, SW_SHOW
	invoke UpdateWindow, @hWnd

	; 消息循环
	.WHILE TRUE
		invoke GetMessage, addr @msg, NULL, 0, 0
		.break .if eax == 0

		invoke TranslateMessage, addr @msg
		invoke DispatchMessage, addr @msg

	.ENDW

	ret
WinMain endp

ENTRY:
	; 获取主模块实例句柄
	invoke GetModuleHandle, NULL

	; 调用WinMain
	invoke WinMain, eax

	; 退出进程
	invoke ExitProcess, 0

end ENTRY
