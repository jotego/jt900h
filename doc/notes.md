# Register Access

## Arithmetic/boolean/load operations:
ADC, ADD, AND, CP, DIV, DIVS, EX, LD,
MUL, MULS, OR, SUB, XOR
- short/long format for source
- shot format for destination

## Fixed registers as source

MULA

## source embedded in op

-DEC, INC, RL, RLC, RLD, RR, RRC, RRD,
 SBC, SCC, SLA, SLL, SRA, SRL,

## Side effects

BC affected (-1,+1)
-CPD, CPDR, CPI, CPIR, LDD, LDDR, LDI, LDIR

## memory to memory

LDX

## Single register

short/long format
-CHG, CPL, DAA, EXTS, EXTZ, MDEC1, MDEC2, MDEC4,
 MINC1, MINC2, MINC4, MIRR, NEG, PAA, RES, SET

short format
-LDA, LDAR

## Spepcial Register as Source
-Carry flag: STCF
-Zero flag: ZCF

## Special Register as Destination

short/long format for source:
-Carry flag: ANDCF, LDCF, ORCF, RCF, SCF, XORCF
-Zero flag: BIT, TSET
-A register: BS1B, BS1F
-RFP: DECF, INCF, LDF
-Control register: LDC

no source:
-Carry flag: CCF

## Branching

-Alter and branch: DJNZ