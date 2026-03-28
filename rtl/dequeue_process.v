`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2025/05/15
// Module Name:     dequeue_process
// Project Name:    MQ
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     Dequeue process module for DFQ CAM system with FSM control
//////////////////////////////////////////////////////////////////////////////////

module dequeue_process #(
    parameter DATA_WIDTH = 20,
    parameter ADDR_WIDTH = 10
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start_dequeue,
    input  wire [DATA_WIDTH-1:0]  head_ptr_in,
    input  wire [DATA_WIDTH-1:0]  ptr_ram_dout,
    input  wire                     pcp_queue_full,
    output reg  [ADDR_WIDTH-1:0]  ptr_ram_addr,
    output reg  [DATA_WIDTH-1:0]  pcp_queue_din,
    output reg                      pcp_queue_wr,
    output reg  [DATA_WIDTH-1:0]  new_head,
    output reg                      dequeue_done,
    output reg  [15:0]             rd_depth_cell
);

    localparam ST_IDLE         = 4'd0;
    localparam ST_START        = 4'd1;
    localparam ST_CHECK        = 4'd2;
    localparam ST_READ         = 4'd3;
    localparam ST_PUSH         = 4'd4;
    localparam ST_PUSH_LOOP    = 4'd5;
    localparam ST_PUSH_DONE    = 4'd6;
    localparam ST_REFRESH      = 4'd7;
    localparam ST_REFRESH_DONE = 4'd8;
    localparam ST_EXIT         = 4'd9;
    localparam ST_CAM_REFRESH  = 4'd10;
    localparam ST_CAM_WAIT     = 4'd11;
    localparam ST_FINAL        = 4'd12;
    localparam ST_EXIT2        = 4'd13;
    localparam ST_NEXT         = 4'd14;
    localparam ST_WAIT         = 4'd15;

    reg [3:0]             current_state;
    reg [DATA_WIDTH-1:0] rd_head_reg;

    wire is_cell_1    = head_ptr_in[15] && head_ptr_in[14];
    wire is_last_cell = ptr_ram_dout[15];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= ST_IDLE;
            pcp_queue_wr <= 1'b0;
            ptr_ram_addr <= {ADDR_WIDTH{1'b0}};
            pcp_queue_din <= {DATA_WIDTH{1'b0}};
            dequeue_done <= 1'b0;
            new_head <= {DATA_WIDTH{1'b0}};
            rd_head_reg <= {DATA_WIDTH{1'b0}};
            rd_depth_cell <= {16{1'b0}};
        end else begin
            pcp_queue_wr <= 1'b0;
            dequeue_done <= 1'b0;

            case (current_state)
                ST_IDLE: begin
                    if (start_dequeue) begin
                        current_state <= ST_START;
                        rd_depth_cell <= 16'b0;
                    end
                end

                ST_START: begin
                    pcp_queue_din <= head_ptr_in;
                    pcp_queue_wr  <= 1'b1;
                    ptr_ram_addr  <= head_ptr_in[ADDR_WIDTH-1:0];
                    current_state <= ST_CHECK;
                    rd_depth_cell <= rd_depth_cell + 1;
                end

                ST_CHECK: begin
                    if (is_cell_1) current_state <= ST_EXIT;
                    else           current_state <= ST_READ;
                end

                ST_READ: begin
                    current_state <= ST_PUSH;
                end

                ST_PUSH: begin
                    pcp_queue_din <= ptr_ram_dout;
                    pcp_queue_wr  <= 1'b1;
                    ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                    current_state <= ST_PUSH_LOOP;
                    rd_depth_cell <= rd_depth_cell + 1;
                end

                ST_PUSH_LOOP: begin
                    current_state <= ST_PUSH_DONE;
                end

                ST_PUSH_DONE: begin
                    current_state <= ST_REFRESH;
                    if (is_last_cell) begin
                        ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                        current_state <= ST_EXIT;
                    end
                end

                ST_REFRESH: begin
                    current_state <= ST_REFRESH_DONE;
                    pcp_queue_din <= ptr_ram_dout;
                    ptr_ram_addr  <= ptr_ram_dout[ADDR_WIDTH-1:0];
                    pcp_queue_wr  <= 1'b1;
                    rd_depth_cell <= rd_depth_cell + 1;
                end

                ST_REFRESH_DONE: begin
                    if (is_last_cell) current_state <= ST_EXIT;
                    else              current_state <= 4'd15;
                end

                4'd15: begin
                    current_state <= ST_PUSH;
                end

                ST_EXIT: begin
                    dequeue_done  <= 1'b1;
                    current_state <= ST_CAM_REFRESH;
                end

                ST_CAM_REFRESH: begin
                    current_state <= ST_CAM_WAIT;
                    new_head     <= ptr_ram_dout;
                end

                ST_CAM_WAIT: begin
                    current_state <= ST_FINAL;
                end

                ST_FINAL: begin
                    current_state <= ST_EXIT2;
                end

                ST_EXIT2: begin
                    current_state <= ST_IDLE;
                end

                default: begin
                    pcp_queue_wr  <= 1'b0;
                    dequeue_done  <= 1'b0;
                    current_state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule