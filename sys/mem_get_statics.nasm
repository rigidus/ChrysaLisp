%include "func.inc"
%include "heap.inc"

	fn_function "sys/mem_get_statics"
		;outputs
		;r0 = statics

		vp_lea [rel statics], r0
		vp_ret

		align 8, db 0
	statics:
		times HP_HEAP_SIZE db 0	;0x0000000000000400	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000000800	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000001000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000002000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000004000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000008000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000010000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000020000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000040000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000080000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000100000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000200000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000400000	byte blocks
		times HP_HEAP_SIZE db 0	;0x0000000000800000	byte blocks

	fn_function_end
