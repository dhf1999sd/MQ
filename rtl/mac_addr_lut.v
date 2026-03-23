`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2023/11/14
// Module Name:     mac_addr_lut
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     MAC address lookup table - improved version
//////////////////////////////////////////////////////////////////////////////////

module mac_addr_lut (
    input             clk,
    input             reset,
    input             src_lut_flag,
    input      [47:0] dst_mac,
    input      [47:0] src_mac,
    input      [15:0] se_portmap,
    input      [ 8:0] se_hash,
    input             se_req,
    output reg        se_ack,
    output reg        se_nak,
    output reg [ 3:0] search_result,
    input             aging_req,
    output reg        aging_ack
);

    parameter LIVE_TH = 10'd300;
    parameter PORT_0  = 16'h0000;
    parameter PORT_1  = 16'h0001;
    parameter PORT_2  = 16'h0002;
    parameter PORT_3  = 16'h0003;

    reg  [3:0] state;
    reg        clear_op;
    reg        hit;
    wire       item_valid;
    wire [9:0] live_time;
    wire       not_outlive;
    reg        ram_wr;
    reg  [8:0] ram_addr;
    reg  [79:0] ram_din;
    wire [79:0] ram_dout;
    reg  [79:0] ram_dout_reg;

    reg  [8:0] aging_addr;
    reg  [47:0] hit_mac;

    reg  [47:0] dst_mac_reg;
    reg  [47:0] src_mac_reg;
    reg         se_req_reg;
    reg  [8:0] se_hash_reg;
    reg  [15:0] se_portmap_reg;

    localparam IDLE        = 4'h0,
               DST_LOOKUP1 = 4'h1,
               DST_LOOKUP2 = 4'h2,
               DST_LOOKUP3 = 4'h3,
               DST_RESULT  = 4'h4,
               SRC_LOOKUP1 = 4'h5,
               SRC_LOOKUP2 = 4'h6,
               SRC_LOOKUP3 = 4'h7,
               SRC_CHECK   = 4'h8,
               SRC_ADD     = 4'h9,
               SRC_UPDATE  = 4'hA,
               AGING_READ  = 4'hB,
               AGING_PROC1 = 4'hC,
               AGING_PROC2 = 4'hD,
               FINISH      = 4'hE,
               CLEAR_RAM   = 4'hF;

    always @(posedge clk) begin
        if (reset) begin
            state         <= IDLE;
            clear_op      <= 1;
            ram_wr        <= 0;
            ram_addr      <= 0;
            ram_din       <= 0;
            se_ack        <= 0;
            se_nak        <= 0;
            aging_ack     <= 0;
            aging_addr    <= 0;
            hit_mac       <= 0;
            src_mac_reg   <= 0;
            dst_mac_reg   <= 0;
            search_result <= 0;
            se_req_reg    <= 0;
            se_hash_reg   <= 0;
            se_portmap_reg <= 0;
            ram_dout_reg  <= 0;
        end else begin
            ram_dout_reg <= ram_dout;
            ram_wr       <= 0;
            se_ack       <= 0;
            se_nak       <= 0;
            aging_ack    <= 0;

            dst_mac_reg    <= dst_mac;
            src_mac_reg    <= src_lut_flag ? src_mac : src_mac_reg;
            se_req_reg     <= se_req;
            se_hash_reg    <= se_hash;
            se_portmap_reg <= se_portmap;

            case (state)
                IDLE: begin
                    if (clear_op) begin
                        ram_addr <= 0;
                        ram_wr   <= 1;
                        ram_din  <= 0;
                        state    <= CLEAR_RAM;
                    end else if (se_req_reg) begin
                        ram_addr <= se_hash_reg;
                        hit_mac  <= dst_mac_reg;
                        state    <= DST_LOOKUP1;
                    end else if (aging_req) begin
                        if (aging_addr < 9'h1ff) aging_addr <= aging_addr + 1;
                        else begin
                            aging_addr <= 0;
                            aging_ack  <= 1;
                        end
                        ram_addr <= aging_addr;
                        state    <= AGING_READ;
                    end
                end

                DST_LOOKUP1: state <= DST_LOOKUP2;
                DST_LOOKUP2: state <= DST_LOOKUP3;
                DST_LOOKUP3: state <= DST_RESULT;

                DST_RESULT: begin
                    state <= SRC_LOOKUP1;
                    case (hit)
                        1'b0: begin
                            se_ack <= 0;
                            se_nak <= 1;
                            case (se_portmap_reg[15:0])
                                PORT_0:  search_result <= 4'b1110;
                                PORT_1:  search_result <= 4'b1101;
                                PORT_2:  search_result <= 4'b1011;
                                PORT_3:  search_result <= 4'b0111;
                                default: search_result <= 4'b1111;
                            endcase
                        end
                        1'b1: begin
                            se_nak <= 0;
                            se_ack <= 1;
                            case (ram_dout_reg[15:0])
                                PORT_0:  search_result <= 4'b0001;
                                PORT_1:  search_result <= 4'b0010;
                                PORT_2:  search_result <= 4'b0100;
                                PORT_3:  search_result <= 4'b1000;
                                default: search_result <= 4'b0000;
                            endcase
                        end
                    endcase
                    ram_addr <= se_hash_reg;
                    hit_mac  <= src_mac_reg;
                end

                SRC_LOOKUP1: state <= SRC_LOOKUP2;
                SRC_LOOKUP2: state <= SRC_LOOKUP3;
                SRC_LOOKUP3: state <= SRC_CHECK;

                SRC_CHECK: begin
                    if (hit == 1'b0) state <= SRC_ADD;
                    else             state <= SRC_UPDATE;
                end

                SRC_ADD: begin
                    state <= FINISH;
                    if (!item_valid) begin
                        ram_din <= {1'b1, 5'b0, LIVE_TH, src_mac_reg[47:0], se_portmap_reg[15:0]};
                        ram_wr  <= 1;
                    end
                end

                SRC_UPDATE: begin
                    state <= FINISH;
                    if (hit) begin
                        ram_din <= {1'b1, 5'b0, LIVE_TH, src_mac_reg[47:0], se_portmap_reg[15:0]};
                        ram_wr  <= 1;
                    end
                end

                AGING_READ:  state <= AGING_PROC1;
                AGING_PROC1: state <= AGING_PROC2;

                AGING_PROC2: begin
                    state <= FINISH;
                    if (not_outlive && item_valid) begin
                        ram_din[79]     <= 1'b1;
                        ram_din[78:74]  <= 5'b0;
                        ram_din[73:64]  <= live_time - 10'd1;
                        ram_din[63:0]   <= ram_dout_reg[63:0];
                        ram_wr          <= 1;
                    end else begin
                        ram_din[79:0] <= 80'b0;
                        ram_wr        <= 1;
                    end
                end

                FINISH: begin
                    ram_wr      <= 0;
                    se_ack      <= 0;
                    se_nak      <= 0;
                    aging_ack   <= 0;
                    clear_op    <= 0;
                    state       <= IDLE;
                end

                CLEAR_RAM: begin
                    if (ram_addr < 9'h1ff) begin
                        ram_addr <= ram_addr + 1;
                        ram_wr   <= 1;
                        ram_din  <= 0;
                    end else begin
                        ram_addr <= 0;
                        ram_wr   <= 0;
                        clear_op <= 0;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    always @(*) begin
        hit = (hit_mac == ram_dout_reg[63:16]) & ram_dout_reg[79];
    end

    assign item_valid  = ram_dout_reg[79];
    assign live_time  = ram_dout_reg[73:64];
    assign not_outlive = (live_time > 0);

    bram_hash u_sram (
        .clka  (clk),
        .wea   (ram_wr),
        .addra (ram_addr),
        .dina  (ram_din),
        .douta (ram_dout)
    );

endmodule
