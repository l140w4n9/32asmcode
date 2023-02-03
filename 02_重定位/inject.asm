.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Injectwinmine.inc

.data
	g_szWinTip db "扫雷",0
	g_szUser32 db "user32", 0
	g_szMessageBox db "MessageBoxA", 0

.code
INJECT_START:
	; int 3
	jmp INJECT_CODE
	g_szText db "Hello Man", 0
	g_szTip db "hello", 0,0
	g_pFnMessageBox dd 0
	
INJECT_CODE:
	call NEXT
NEXT:
	pop ebx
	sub ebx, offset NEXT
	
	push MB_OK
	
	mov eax, offset g_szTip
	add eax, ebx
	push eax
	
	mov eax, offset g_szText
	add eax, ebx
	push eax
	
	push NULL
	
	mov eax, offset g_pFnMessageBox
	add eax, ebx
	call dword ptr[eax]
	
	
	; invoke MessageBox, NULL, offset g_szText, offset g_szTip, MB_OK
	
	ret
	
INJECT_END:


Inject proc
	LOCAL @hWin:HWND
	LOCAL @nPID:DWORD
	LOCAL @hProc:DWORD
	LOCAL @pAddr:LPVOID
	LOCAL @nWriteBytes:DWORD
	LOCAL @hUser32:DWORD
	LOCAL @pFnOld:DWORD
	LOCAL @pFnMessageBox:DWORD
	
	; 准备工作
	invoke GetModuleHandle, offset g_szUser32
	mov @hUser32, eax
	invoke GetProcAddress, @hUser32, offset g_szMessageBox
	mov @pFnMessageBox, eax
	
	invoke VirtualProtect, offset g_pFnMessageBox, 1, PAGE_EXECUTE_READWRITE, addr @pFnOld
	mov eax, @pFnMessageBox
	mov g_pFnMessageBox, eax
	invoke VirtualProtect, offset g_pFnMessageBox, 1, @pFnOld, addr @pFnOld
	
	; 获取窗口句柄
	invoke FindWindow, NULL, offset g_szWinTip
	mov @hWin, eax
	
	; 获取进程ID
	invoke GetWindowThreadProcessId, @hWin, addr @nPID
	
	; 获取进程句柄
	invoke OpenProcess, PROCESS_ALL_ACCESS, FALSE, @nPID
	mov @hProc, eax
	
	; 申请内存
	invoke VirtualAllocEx, @hProc, NULL, 1, MEM_COMMIT, PAGE_EXECUTE_READWRITE
	mov @pAddr, eax
	
	; 写入代码
	invoke WriteProcessMemory, @hProc, @pAddr, offset INJECT_START, offset INJECT_END - offset INJECT_START, addr @nWriteBytes
	
	; 开启远程线程
	invoke CreateRemoteThread, @hProc, NULL, 0, @pAddr, NULL, NULL, NULL
	
	
	
	ret

Inject endp

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################


DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND
		mov eax, wParam
		.if ax == BTN_INJECT
			invoke Inject
		.endif

	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
