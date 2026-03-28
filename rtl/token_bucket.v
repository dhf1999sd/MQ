`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2025/07/13
// Module Name:     token_bucket
// Project Name:    MQ
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     This module implements the Token Bucket algorithm for Asynchronous Traffic
//                  Shaping (ATS). It calculates the frame eligibility time based on flow
//                  parameters and traffic conditions.
//////////////////////////////////////////////////////////////////////////////////

module token_bucket#(
    parameter       TIME_WIDTH = 59
  )(
    input  wire                           clk,
    input  wire                           reset,
    input  wire                           start_flag,
    input  wire                           read_end_flag,
    input  wire                           match_finish_flag,
    input  wire [15:0]                    frame_length,
    input  wire [31:0]                    committed_information_rate,
    input  wire [31:0]                    committed_burst_size,
    input  wire [TIME_WIDTH-1:0]          arrival_time,
    input  wire [TIME_WIDTH-1:0]          group_eligibility_time,
    input  wire [TIME_WIDTH-1:0]          bucket_empty_time,
    input  wire [TIME_WIDTH-1:0]          max_residence_time,
    output reg                            start_match_flag,
    output reg                            frame_discard_flag,
    output reg                            frame_eligible_time_OK,
    output reg  [TIME_WIDTH-1:0]          frame_eligible_time,
    output reg  [TIME_WIDTH-1:0]          update_bucket_empty_time,
    output reg  [TIME_WIDTH-1:0]          update_group_eligibility_time
  );

  localparam S_IDLE              = 4'd0;
  localparam S_CALC_DURATIONS    = 4'd1;
  localparam S_WAIT_1            = 4'd2;
  localparam S_CALC_TIMES        = 4'd3;
  localparam S_CALC_FET_TEMP     = 4'd4;
  localparam S_LATCH_FET         = 4'd5;
  localparam S_CHECK_RESIDENCE   = 4'd6;
  localparam S_SET_OK            = 4'd7;
  localparam S_WAIT_END          = 4'd8;
  localparam S_DISCARD_FRAME     = 4'd9;

  reg [3:0]                             token_state;
  reg [TIME_WIDTH-1:0]                  length_recovery_duration;
  reg [TIME_WIDTH-1:0]                  empty_to_full_duration;
  reg [TIME_WIDTH-1:0]                  scheduler_eligibility_time;
  reg [TIME_WIDTH-1:0]                  bucket_full_time;
  reg [TIME_WIDTH-1:0]                  frame_eligible_time_temp;
  reg [TIME_WIDTH-1:0]                  max_allowable_time;

  always @(posedge clk)
  begin
    if (reset)
    begin
      frame_discard_flag               <= 1'b0;
      frame_eligible_time_OK           <= 1'b0;
      frame_eligible_time              <= {TIME_WIDTH{1'b0}};
      update_bucket_empty_time         <= {TIME_WIDTH{1'b0}};
      update_group_eligibility_time    <= {TIME_WIDTH{1'b0}};
      token_state                      <= S_IDLE;
      length_recovery_duration         <= {TIME_WIDTH{1'b0}};
      empty_to_full_duration           <= {TIME_WIDTH{1'b0}};
      scheduler_eligibility_time       <= {TIME_WIDTH{1'b0}};
      bucket_full_time                 <= {TIME_WIDTH{1'b0}};
      frame_eligible_time_temp         <= {TIME_WIDTH{1'b0}};
      max_allowable_time               <= {TIME_WIDTH{1'b0}};
      start_match_flag                 <= 1'b0;
    end
    else
    begin
      case (token_state)
        S_IDLE:
        begin
          if (start_flag)
          begin
            frame_discard_flag           <= 1'b0;
            frame_eligible_time_OK       <= 1'b0;
            start_match_flag             <= 1'b1;
          end
          if(match_finish_flag)
          begin
            start_match_flag <= 1'b0;
            token_state      <= S_CALC_DURATIONS;
          end
        end

        S_CALC_DURATIONS:
        begin
          length_recovery_duration <= frame_length * committed_information_rate;
          empty_to_full_duration   <= committed_burst_size * committed_information_rate;
          token_state              <= S_WAIT_1;
        end

        S_WAIT_1:
        begin
          token_state <= S_CALC_TIMES;
        end

        S_CALC_TIMES:
        begin
          scheduler_eligibility_time <= bucket_empty_time + length_recovery_duration;
          bucket_full_time           <= bucket_empty_time + empty_to_full_duration;
          token_state                <= S_CALC_FET_TEMP;
        end

        S_CALC_FET_TEMP:
        begin
          frame_eligible_time_temp <= (arrival_time > group_eligibility_time && arrival_time > scheduler_eligibility_time) ? arrival_time :
            (group_eligibility_time > scheduler_eligibility_time) ? group_eligibility_time : scheduler_eligibility_time;
          max_allowable_time       <= arrival_time + max_residence_time;
          token_state              <= S_LATCH_FET;
        end

        S_LATCH_FET:
        begin
          frame_eligible_time <= frame_eligible_time_temp;
          token_state         <= S_CHECK_RESIDENCE;
        end

        S_CHECK_RESIDENCE:
        begin
          if (frame_eligible_time <= max_allowable_time)
          begin
            update_group_eligibility_time <= frame_eligible_time;
            update_bucket_empty_time      <= (frame_eligible_time < bucket_full_time) ?
            scheduler_eligibility_time :
              scheduler_eligibility_time + frame_eligible_time - bucket_full_time;
            frame_discard_flag            <= 1'b0;
            token_state                   <= S_SET_OK;
          end
          else
          begin
            token_state  <= S_DISCARD_FRAME;
          end
        end

        S_SET_OK:
        begin
          frame_eligible_time_OK <= 1'b1;
          token_state            <= S_WAIT_END;
        end

        S_DISCARD_FRAME:
        begin
          frame_eligible_time_OK <= 1'b1;
          frame_discard_flag     <= 1'b1;
          token_state            <= S_WAIT_END;
        end

        S_WAIT_END:
        begin
          if (read_end_flag)
          begin
            frame_eligible_time_OK <= 1'b0;
            token_state            <= S_IDLE;
            frame_discard_flag     <= 1'b0;
          end
        end

        default:
          token_state <= S_IDLE;
      endcase
    end
  end

endmodule