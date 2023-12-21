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

| Byte 1                            | Byte 2                    |
| --------------------------------- | ------------------------- |
| destination register: **dst,op0** | 3-bit value (#3): **op1** |
| destination register: **dst,op0** | register (R): **src/op1** |
| destination register: **dst,op0** | A: **src/op1**            |
| destination register: **dst,op0** | DAA: **op1**              |
| destination register: **dst,op0** | CR:  **md/pc+=2**         |
| destination register: **dst,op0** | PAA: **op1=0**            |


## PC at Reset

The NeoGeo Pocket seems to start operation from FF1800, which does not agree with the TMP95C061 user guide or similar documents. The parameter `PC_RSTVAL` can be used in order to accomodate arbitrary reset values for the PC.

## Resource utilization

Compiled on MiSTer

| Version    | Usage                |
| ---------- | -------------------- |
| Old        | ~7000 LE and no BRAM |
| microcoded | TBD                  |
