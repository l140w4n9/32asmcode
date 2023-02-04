.586
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include shell32.inc

includelib kernel32.lib
includelib user32.lib
includelib shell32.lib

UnInstallHook proto
InstallHook proto

.data
	g_szShell32 db "shell32", 0
	g_szShellAboutW db "ShellAboutW", 0
	g_szNewTip	dw "c", "r", "4", "4", 0
	g_szText dw "b", "y", " ", "k", "r", 0
	g_pDstAddr dd 0
	g_szTip db "hello", 0
	g_szMyText db "hello man", 0

.code
HOOK:
	pushad
	pushfd
	
	mov eax, offset g_szNewTip
	mov [esp + 2ch], eax
	
	mov eax, offset g_szText
	mov [esp + 30h], eax
	
	invoke UnInstallHook
	
	invoke ShellAbout,NULL, offset g_szTip, offset g_szMyText, NULL
	
	invoke InstallHook
	
	popfd
	popad
	
	; 执行被破坏的指令
	push ebp
	mov ebp, esp
	jmp g_pDstAddr
	
InstallHook proc
	LOCAL @hShell32:HANDLE
	LOCAL @pfnShellAboutW:DWORD
	LOCAL @nOldProt:DWORD

	; 获取要hook的api地址
	invoke GetModuleHandle, offset g_szShell32
	mov @hShell32, eax
	
	invoke GetProcAddress, @hShell32, offset g_szShellAboutW
	mov @pfnShellAboutW, eax
	
	; 修改api
	invoke VirtualProtect, @pfnShellAboutW, 1, PAGE_EXECUTE_READWRITE, addr @nOldProt
	
	mov eax, @pfnShellAboutW
	
	mov byte ptr [eax], 0e9h
	
	mov ecx, offset HOOK
	sub ecx, @pfnShellAboutW
	sub ecx, 5
	mov dword ptr[eax + 1], ecx
	
	add eax, 5
	mov g_pDstAddr, eax
	
	invoke VirtualProtect, @pfnShellAboutW, 1, @nOldProt, addr @nOldProt

    ret
InstallHook endp

UnInstallHook proc
	LOCAL @hShell32:HANDLE
	LOCAL @pfnShellAboutW:DWORD
	LOCAL @nOldProt:DWORD

	; 获取要hook的api地址
	invoke GetModuleHandle, offset g_szShell32
	mov @hShell32, eax
	
	invoke GetProcAddress, @hShell32, offset g_szShellAboutW
	mov @pfnShellAboutW, eax
	
	; 修改api
	invoke VirtualProtect, @pfnShellAboutW, 1, PAGE_EXECUTE_READWRITE, addr @nOldProt
	
	mov eax, @pfnShellAboutW
	
	mov byte ptr [eax], 08bh
	mov byte ptr [eax + 1], 0ffh
	mov byte ptr [eax + 2], 055h
	mov byte ptr [eax + 3], 08bh
	mov byte ptr [eax + 4], 0ech
	
	invoke VirtualProtect, @pfnShellAboutW, 1, @nOldProt, addr @nOldProt
	
	ret

UnInstallHook endp

DllMain proc  hinstDLL:HINSTANCE, fdwReason:DWORD , lpvReserved:LPVOID
	
	.if fdwReason == DLL_PROCESS_ATTACH
		invoke InstallHook
	.endif
	
	mov eax, TRUE
	ret

DllMain endp

end DllMain
