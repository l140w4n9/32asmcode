.586
.model flat, stdcall
option casemap :none

include windows.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

.data
	g_szText1 db "异常已处理", 0
	g_szText2 db "异常未处理", 0
	g_szText3 db "程序正常执行", 0

.code


MyUnhandledExceptionFilter proc ExceptionInfo:ptr EXCEPTION_POINTERS
	mov esi, ExceptionInfo
	assume esi:ptr EXCEPTION_POINTERS
	mov edi, [esi].ContextRecord
	assume edi:ptr CONTEXT
	mov esi, [esi].pExceptionRecord
	assume esi:ptr EXCEPTION_RECORD
	
	.if [esi].ExceptionCode == EXCEPTION_ACCESS_VIOLATION
		
		; 处理异常，返回继续执行
		mov eax, [edi].regEip
		add eax, 2
		mov [edi].regEip, eax
		invoke MessageBox,NULL, NULL, offset g_szText1, MB_OK
		
		mov eax, EXCEPTION_CONTINUE_EXECUTION
		ret
	.endif
	
	; 异常未处理直接退出
	invoke MessageBox,NULL, NULL, offset g_szText2, MB_OK
	mov eax, EXCEPTION_EXECUTE_HANDLER
	ret
MyUnhandledExceptionFilter endp

START:
	
	invoke SetUnhandledExceptionFilter, MyUnhandledExceptionFilter
	
	
	mov eax, 555
	mov [eax], eax
	
	invoke MessageBox,NULL, NULL, offset g_szText3, MB_OK
	
	invoke ExitProcess, 0

end START
