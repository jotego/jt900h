# JT900H

Verilog module compatible with Toshiba TLCS900/H CPU.

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

(c) Jose Tejada 2021

## Folder Description

* [doc](doc) contains relevant documentation, both original and specific to this project
* [hdl](hdl) verilog files to instantiate the module. The top level cell is called **jt900h**
* [model](model) C files of DPI model
* [ver](ver) verification files, ver/top for top-level verification

Only source files are included in this repository. Binary files can be obtained by compiling the sources.

## RAM controller

The RAM controller always reads 4 bytes now, it should be optimised to read 2 bytes when only 2 bytes are needed

The PUSH operation takes an extra cycle to cater for the case when the XSP is at an odd address. It should be optimised to either check the RAM controller status and finish early, or check XSP LSB and add the extra cycle only if needed