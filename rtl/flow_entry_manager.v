`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2024/07/15
// Design Name:     Flow Entry Manager
// Module Name:     flow_entry_manager
// Project Name:    ATS_with_mult_queue_v13
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     This module manages flow entries using RAM-based storage.
//                  It provides flow parameter lookup and update functionality
//                  with support for multiple groups and flows per group.
// Dependencies:    flow_para_ram.v
//
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module flow_entry_manager #(
    parameter MATCH_ADDR_WIDTH = 9,
    parameter NUM_FLOW        = 16,
    parameter GROUP_NUMBER    = 24,
    parameter TIME_WIDTH      = 59,
    parameter CAM_ENTRY_WIDTH = 123
  )(
    input  wire                     clk,
    input  wire                     reset,
    input  wire [4:0]             flow_id,
    input  wire                     update_flag,
    input  wire [7:0]              group_id,
    input  wire                     start_match_flag,
    input  wire [TIME_WIDTH-1:0]   update_bucket_empty_time,
    input  wire [TIME_WIDTH-1:0]   update_group_eligibility_time,
    output reg                      match_finish_flag,
    output reg  [31:0]             bucket_size,
    output reg  [31:0]             token_rate,
    output reg  [TIME_WIDTH-1:0]   bucket_empty_time,
    output reg  [TIME_WIDTH-1:0]   group_eligibility_time,
    output reg  [TIME_WIDTH-1:0]   max_residence_time
  );

  function [MATCH_ADDR_WIDTH-1:0] calc_addr;
    input [4:0] group;
    input [3:0] flow_index;
    begin
      calc_addr = {group, flow_index};
    end
  endfunction

  localparam IDLE        = 3'd0;
  localparam INIT        = 3'd1;
  localparam SEARCHING   = 3'd2;
  localparam MATCH_FOUND = 3'd3;
  localparam UPDATING    = 3'd4;

  reg [3:0]                      state;
  reg                             match_flag;
  reg [MATCH_ADDR_WIDTH-1:0]     init_addr_counter;
  reg                             init_done;
  reg                             wea;
  reg [MATCH_ADDR_WIDTH-1:0]     addra;
  reg [CAM_ENTRY_WIDTH-1:0]      dina;
  reg [TIME_WIDTH-1:0]           group_max_residence_time[GROUP_NUMBER-1:0];
  reg [TIME_WIDTH-1:0]           group_eligibility_time_reg[GROUP_NUMBER-1:0];

  wire [CAM_ENTRY_WIDTH-1:0]     douta;
  wire                           clka;

  flow_para_ram u_flow_para_ram (
                  .clka  (clk),
                  .wea   (wea),
                  .addra (addra),
                  .dina  (dina),
                  .douta (douta)
                );

  assign clka = clk;

  integer i;

  always @(posedge clk)
  begin
    if (reset)
    begin
      state <= INIT;
      match_flag <= 1'b0;
      match_finish_flag <= 1'b0;
      bucket_size <= 0;
      token_rate <= 0;
      bucket_empty_time <= 0;
      group_eligibility_time <= 0;
      max_residence_time <= 0;

      init_addr_counter <= 0;
      init_done <= 1'b0;

      wea <= 1'b0;
      addra <= 0;
      dina <= 0;

      for (i = 0; i < GROUP_NUMBER; i = i + 1)
      begin
        group_max_residence_time[i]    <= {TIME_WIDTH{1'b0}};
        group_eligibility_time_reg[i] <= {TIME_WIDTH{1'b0}};
      end
    end
    else
    begin
      case (state)
        INIT:
        begin
          if (!init_done)
          begin
            wea   <= 1'b1;
            addra <= init_addr_counter;

            case (init_addr_counter)
              calc_addr(5'd3,  4'h7): dina <= {59'h0, 32'd40000,  32'd512};
              calc_addr(5'd7,  4'h0): dina <= {59'h0, 32'd40000,  32'd512};
              calc_addr(5'd7,  4'h1): dina <= {59'h0, 32'd80000,  32'd512};
              calc_addr(5'd7,  4'h2): dina <= {59'h0, 32'd320000, 32'd1600};
              calc_addr(5'd8,  4'h4): dina <= {59'h0, 32'd160000, 32'd3200};
              calc_addr(5'd8,  4'h5): dina <= {59'h0, 32'd80000,  32'd512};
              calc_addr(5'd9,  4'h4): dina <= {59'h0, 32'd320000, 32'd3200};
              calc_addr(5'd11, 4'h3): dina <= {59'h0, 32'd320000, 32'd3200};
              calc_addr(5'd15, 4'hF): dina <= {59'h0, 32'd64000,  32'd1024};
              calc_addr(5'd20, 4'h2): dina <= {59'h0, 32'd256000, 32'd4096};
              calc_addr(5'd22, 4'h0): dina <= {59'h0, 32'd80000,  32'd512};
              calc_addr(5'd23, 4'hF): dina <= {59'h0, 32'd500000, 32'd8000};
              default:
                dina <= 0;
            endcase

            init_addr_counter <= init_addr_counter + 1;

            if (init_addr_counter == GROUP_NUMBER * NUM_FLOW - 1)
            begin
              init_done <= 1'b1;
              state     <= IDLE;
              wea       <= 1'b0;
            end
          end
          else
          begin
            state <= IDLE;
            wea   <= 1'b0;
          end
        end

        IDLE:
        begin
          match_finish_flag <= 1'b0;
          wea <= 1'b0;

          if (update_flag)
          begin
            state  <= UPDATING;
            addra  <= calc_addr(group_id, flow_id[3:0]);
          end
          else if (start_match_flag)
          begin
            state  <= 5;
            addra  <= calc_addr(group_id, flow_id[3:0]);
          end
        end

        5:
        begin
          state <= 6;
        end

        6:
        begin
          state <= 7;
        end

        7:
        begin
          state <= SEARCHING;
        end

        UPDATING:
        begin
          wea   <= 1'b1;
          addra <= calc_addr(group_id, flow_id[3:0]);
          dina  <= {update_bucket_empty_time, douta[63:0]};
          group_eligibility_time_reg[group_id] <= update_group_eligibility_time;
          state <= IDLE;
        end

        SEARCHING:
        begin
          wea                        <= 1'b0;
          match_flag                 <= 1'b1;
          bucket_size                <= douta[31:0];
          token_rate                 <= douta[63:32];
          bucket_empty_time          <= douta[122:64];
          group_eligibility_time     <= group_eligibility_time_reg[group_id];
          max_residence_time         <= group_max_residence_time[group_id];
          match_finish_flag          <= 1'b1;
          state                      <= MATCH_FOUND;
        end

        MATCH_FOUND:
        begin
          state              <= 8;
          match_flag         <= 1'b0;
          match_finish_flag  <= 1'b1;
        end

        8:
        begin
          match_finish_flag <= 1'b0;
          state <= IDLE;
        end

        default:
        begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
