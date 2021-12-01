<<<<<<< HEAD
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

    Author: Jose Tejada Gomez. https://patreon.com/topapate
    Version: 1.0
    Date: 29-11-2021 */

module jt900h;
=======
module jt900h(
    input           rst,
    input           clk,
    input           cen,
    output          cpu_cen,

    input    [15:0] din,
    output   [15:0] dout,
    output   [23:0] addr,
    output          rd,
    output          wr,
    output   [ 1:0] dsn,    // active low
);


>>>>>>> a18573ba14e797ee7ee18980e5661fde9451b4a1

endmodule