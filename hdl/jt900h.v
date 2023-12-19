/*  This file is part of JT900H.
    JT900H program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT900H program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT900H.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. https://patreon.com/jotego
    Version: 1.0
    Date: 17-12-2023 */

module jt900h(
    input             rst,
    input             clk,
    input             cen,

    output     [23:1] addr,
    input      [15:0] din,
    output     [15:0] dout,
    output     [ 1:0] we,
    input             busy,

    // interrupt processing
    input             irq,
    output            irq_ack,
    input      [ 2:0] intrq,      // interrupt request

    // set to zero to use the regular interrupt vectors at FFFF00
    // or set to one and pass the interrupt vector lower 8 bits
    input             inta_en,    // the external device sets the vector address
    input      [ 7:0] int_addr,
    // Register dump
    output            buserror,
    input      [ 7:0] dmp_addr,     // dump
    output     [ 7:0] dmp_dout,
    // Debug
    input      [ 7:0] st_addr,
    output     [ 7:0] st_dout,
    output            op_start      // high when OP's 1st byte is decoded
);

endmodule