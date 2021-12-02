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
    Date: 30-11-2021 */

module jt900h_ctrl(
    input             rst,
    input             clk,

    output reg [23:0] idx_offset
);

wire mem_idx_easy, mem_idx_off8;
wire [15:0] cur_op;
reg  [15:0] last_op;

assign cur_op = parse[1] ? last_op : op;
assign mem_idx_easy = !op[6];
assign mem_idx_off8 = !op[6] && op[3];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        illegal <= 0;
    end else begin
        st_reg   <= streg_dly;
        load_mem <= 0;
        last_op  <= op;
        if( grab_addr8 ) begin
            idx_offset[23:8] <= { {8{op[7]}}, op };
            grab_addr8 <= 0;
        end
        if( !load_mem ) begin
            casez( cur_op[7:0] )
                8'b10??_????,
                8'b11??_0???: begin // LD R,(mem)
                    if( parse[0] ) begin
                        zz <= op[5:4];
                        if( mem_idx_easy ) begin
                            reg_sel0 <= idx_regsel;
                            load_mem <= 1;
                            if( mem_idx_off8 ) begin
                                idx_offset <= { {16{op[15]}}, op[15:8] };
                                parse <= 2;
                            end else begin
                                streg_dly <= 1;
                                dst_sel  <= full_name( op[10:8] );
                                illegal  <= op[15:11] != 5'b00100;
                            end
                        end
                        if( mem_idx_addr )  begin
                            reg_sel0 <= NULL;
                            load_mem <= 1;
                            streg_dly <= 1;
                            idx_offset <= { {16{op[15]}}, op[15:8] };
                            grab_addr8  <= op[1:0] == 1;
                            grab_addr16 <= op[1:0] == 2;
                        end
                    end
                    if( parse[1] ) begin
                        streg_dly <= 1;
                        dst_sel  <= full_name( op[2:0] );
                        illegal  <= op[7:3] != 5'b00100;
                    end
                end

            endcase
        end
    end
end

endmodule