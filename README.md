# JT900H

Verilog module compatible with Toshiba TLCS900/H CPU.

You can show your appreciation through
* [Patreon](https://patreon.com/jotego), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

(c) Jose Tejada 2021

## Folder Description

* [doc](doc) contains relevant documentation, both original and specific to this project
* [hdl](hdl) verilog files to instantiate the module. The top level cell is called **jt900h**
* [model](model) C files of DPI model
* [ver](ver) verification files, ver/top for top-level verification

Only source files are included in this repository. Binary files can be obtained by compiling the sources.

## Decoding

- procedures linked to a decoding step (_op_ element in [the YAML file](hdl/900h.yaml)) assume that the 4 bytes in MD are valid and that the PC points to the first byte
- each procedure that consumes a byte must move the PC forward

### Memory Addressing

**Group 2: R,mem and mem,R**
First OP byte is a memory addressing (page 43 of 900H_CPU_BOOK_CP3.pdf):

- **ea** contains the memory address calculated
- **op1** contains the data at that memory address
- **md** contains 4 valid bytes starting at PC

Second OP byte contains a register selection:

- **dst** points to the register
- **op0** contains the register value

**Group 1: R,#3**

| Byte 1                            | Byte 2                       |
| --------------------------------- | ---------------------------- |
| mem, **ea,op1**                   | R, **dst,op0=dst,op1=(mem)** |
| destination register: **dst,op0** | 3-bit value (#3): **op1**    |
| destination register: **dst,op0** | register (R): **src/op1**    |
| destination register: **dst,op0** | A: **src/op1**               |
| destination register: **dst,op0** | DAA: **op1**                 |
| destination register: **dst,op0** | CR:  **md/pc+=2**            |
| destination register: **dst,op0** | PAA: **op1=0**               |

###  1?11'???? Series

| Instruction         | Encoding                |
| ------------------- | ----------------------- |
| RET cc              | 1011'0000 - 1111'cccc   |
| LDAR                | 1111'0011 - 0001'0011   |
| JP cc,mem           | 1m11'mmmm - 1101'cccc   |
| LD (mem),R          | 1m11'mmmm - 01zz'0RRR   |
| LD<W> (mem),#       | 1m11'mmmm - 0000'00z0   |
| LD<W> (mem),(#16)   | 1m11'mmmm - 0001'01z0   |
| LDA R,mem           | 1m11'mmmm - 001s'0RRR   |
| CALL cc,mem         | 1m11'mmmm - 1110'cccc   |
| POP<W> (mem)        | 1m11'mmmm - 0000'01z0   |
| ANDCF  A,(mem)      | 1m11'mmmm - 0010'1000   |
| LDCF   A,(mem)      | 1m11'mmmm - 0010'1011   |
| ORCF   A,(mem)      | 1m11'mmmm - 0010'1001   |
| XORCF  A,(mem)      | 1m11'mmmm - 0010'1010   |
| STCF   A,(mem)      | 1m11'mmmm - 0010'1100   |
| BIT   #3,(mem)      | 1m11'mmmm - 1100'1~3~   |
| ANDCF #3,(mem)      | 1m11'mmmm - 1000'0~3~   |
| LDCF  #3,(mem)      | 1m11'mmmm - 1001'1~3~   |
| ORCF  #3,(mem)      | 1m11'mmmm - 1000'1~3~   |
| XORCF #3,(mem)      | 1m11'mmmm - 1001'0~3~   |
| STCF  #3,(mem)      | 1m11'mmmm - 1010'0~3~   |
| CHG   #3,(mem)      | 1m11'mmmm - 1100'0~3~   |
| RES   #3,(mem)      | 1m11'mmmm - 1011'0~3~   |
| SET   #3,(mem)      | 1m11'mmmm - 1011'1~3~   |
| TSET  #3,(mem)      | 1m11'mmmm - 1010'1~3~   |





- How to enter LDAR instruction

## PC at Reset

The NeoGeo Pocket seems to start operation from FF1800, which does not agree with the TMP95C061 user guide or similar documents. The parameter `PC_RSTVAL` can be used in order to accomodate arbitrary reset values for the PC.

## Resource utilization

Compiled on MiSTer

| Version    | Usage                |
| ---------- | -------------------- |
| Old        | ~7000 LE and no BRAM |
| microcoded | TBD                  |
