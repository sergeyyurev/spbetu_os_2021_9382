TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H

STARTUP: JMP MAIN

PC_TYPE          DB      'Type: PC',                      0DH, 0AH, '$'
PC_XT_TYPE       DB      'Type: PC/XT',                   0DH, 0AH, '$'
AT_TYPE          DB      'Type: AT',                      0DH, 0AH, '$'
PS2_M30_TYPE     DB      'Type: PS2 M_30',                0DH, 0AH, '$'
PS2_M50_60_TYPE  DB      'Type: PS2 M_50 | M_60',         0DH, 0AH, '$'
PS2_M80_TYPE     DB      'Type: PS2 M_80',                0DH, 0AH, '$'
PС_JR_TYPE       DB      'Type: PСjr',                    0DH, 0AH, '$'
PC_CONV_TYPE     DB      'Type: PC Convertible',          0DH, 0AH, '$'
VERSION          DB      'MS-DOS:  .  ',                  0DH, 0AH, '$'
SERIAL           DB      'Serial OEM:  ',                 0DH, 0AH, '$'
USER             DB      'User number:       H',                    '$'


TETR_TO_HEX PROC NEAR
    AND AL, 0FH
    CMP AL, 09
    JBE NEXT
    ADD AL, 07

NEXT:
    ADD AL, 30H
    RET
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC NEAR
    PUSH CX
    MOV AH, AL
    CALL TETR_TO_HEX
    XCHG AL, AH
    MOV CL, 4
    SHR AL, CL
    CALL TETR_TO_HEX
    POP CX
    RET
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC NEAR
    PUSH BX
    MOV BH, AH
    CALL BYTE_TO_HEX
    MOV [DI], AH
    DEC DI
    MOV [DI], AL
    DEC DI
    MOV AL, BH
    CALL BYTE_TO_HEX
    MOV [DI], AH
    DEC DI
    MOV [DI], AL
    POP BX
    RET
WRD_TO_HEX ENDP


BYTE_TO_DEC PROC NEAR
    PUSH SI
    PUSH CX
    PUSH DX
    XOR AH, AH
    XOR DX, DX
    MOV CX, 10

LOOP_BD:
    DIV CX
    OR DL, 30H
    MOV [SI], DL
    DEC SI
    XOR DX, DX
    CMP AX, 10
    JAE LOOP_BD
    CMP AL, 00H
    JE END_L
    OR AL, 30H
    MOV [SI], AL

END_L:
    POP DX
    POP CX
    POP SI
    RET
BYTE_TO_DEC ENDP


WRITESTRING PROC NEAR
    MOV AH, 09H
    INT 21H
    RET
WRITESTRING ENDP


DEFINE_PC PROC NEAR
    MOV AX, 0F000H
    MOV ES, AX
    MOV AL, ES:[0FFFEH]

	CMP AL, 0FFH
	JE PC
	CMP AL, 0FEH
	JE XT
	CMP AL, 0FBH
	JE XT
	CMP AL, 0FCH
	JE AT
	CMP AL, 0FAH
	JE PS2_M30
	CMP AL, 0F8H
	JE PS2_M80
	CMP AL, 0FDH
	JE JR
	CMP AL, 0F9H
	JE CONV

PC:
    MOV DX, OFFSET PC_TYPE
    JMP OUTPUT_PC

XT:
    MOV DX, OFFSET PC_XT_TYPE
    JMP OUTPUT_PC

AT:
    MOV DX, OFFSET AT_TYPE
    JMP OUTPUT_PC

PS2_M30:
    MOV DX, OFFSET PS2_M30_TYPE
    JMP OUTPUT_PC

PS2_M50_60:
    MOV DX, OFFSET PS2_M50_60_TYPE
    JMP OUTPUT_PC

PS2_M80:
    MOV DX, OFFSET PS2_M80_TYPE
    JMP OUTPUT_PC

JR:
    MOV DX, OFFSET PС_JR_TYPE
    JMP OUTPUT_PC

CONV:
    MOV DX, OFFSET PC_CONV_TYPE
    JMP OUTPUT_PC

OUTPUT_PC:
    CALL WRITESTRING
    RET
DEFINE_PC ENDP


DEFINE_OS PROC NEAR
    MOV AH, 30H
    INT 21H
    PUSH AX

    MOV SI, OFFSET VERSION
    ADD SI, 8
    CALL BYTE_TO_DEC
    POP AX
    MOV AL, AH
    ADD SI, 2
    CALL BYTE_TO_DEC
    MOV DX, OFFSET VERSION
    CALL WRITESTRING

    MOV SI, OFFSET SERIAL
    ADD SI, 12
    MOV AL, BH
    CALL BYTE_TO_DEC
    MOV DX, OFFSET SERIAL
    CALL WRITESTRING

    MOV DI, OFFSET USER
    ADD DI, 18
    MOV AX, CX
    CALL WRD_TO_HEX
    MOV AL, BL
    CALL BYTE_TO_HEX
    SUB DI, 2
    MOV [DI], AX
    MOV DX, OFFSET USER
    CALL WRITESTRING
    RET
DEFINE_OS ENDP


MAIN:
    CALL DEFINE_PC
    CALL DEFINE_OS
    XOR AL, AL
    MOV AH, 4CH
    INT 21H


TESTPC ENDS
END STARTUP