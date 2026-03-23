//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
//
// Create Date:     2024/8/6
// Design Name:     Queue Management Module
// Module Name:     switch_qm
// Project Name:    ATS_with_mult_queue_v11
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:     Queue Management Module
//
// Dependencies:    comparator.v, dequeue_process.v, priority_arbiter.v
//
// Revision:     v1.0
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module switch_qm#(
    parameter       NUM_FLOW_QUEUES   = 256,
    parameter       NUM_PRIORITY      = 8,
    parameter       DEPTH_FLOW_QUEUES = 8,
    parameter       TIMESTAMP_WIDTH   = 59,
    parameter       PORT_NUM          = 4,
    parameter       ADDR_WIDTH        = 10,    // Pointer RAM address width
    parameter       METADATA_WIDTH    = 20
  )(
    input  wire                               clk,
    input  wire                               reset,
    input  wire                               in_metadata_wr,
    input  wire [TIMESTAMP_WIDTH-1:0]         frame_eligible_time,
    input  wire                               frame_elig_time_ok_w,
    input  wire [4:0]                         group_id,
    input  wire                               ptr_ack,
    input  wire [2:0]                         pcp,
    input  wire [METADATA_WIDTH-1:0]         in_metadata,
    input  wire [31:0]                        input_flow_ID,
    input  wire [TIMESTAMP_WIDTH-1:0]         local_clock,
    output wire                               input_data_full,
    output wire                               ptr_rdy,
    output wire [METADATA_WIDTH-1:0]         ptr_dout
  );

  /***************function**************/

  /***************parameter*************/

  /***************port******************/

  /***************mechine***************/

  /***************reg*******************/
  reg                                       ptr_wr;
  reg                                       input_data_rd;
  reg                                       parameter_fifo_rd;
  reg                                       ptr_wr_ack;
  reg  [1:0]                                qm_wr_state;
  reg  [2:0]                                wr_pcp;
  reg  [22:0]                               ptr_din;
  reg  [31:0]                               flow_id_search_r;
  reg  [4:0]                                wr_group_id;
  reg  [58:0]                               frame_elig_time_r;
  reg                                       wr_finish_flag;
  reg  [METADATA_WIDTH-1:0]                 tail[NUM_FLOW_QUEUES-1:0];
  reg  [METADATA_WIDTH-1:0]                 head[NUM_FLOW_QUEUES-1:0];
  reg  [METADATA_WIDTH-1:0]                 ptr_ram_din;
  reg  [15:0]                               depth_cell[NUM_FLOW_QUEUES-1:0];
  reg  [15:0]                               depth_frame[NUM_FLOW_QUEUES-1:0];
  reg  [15:0]                               frame_length[NUM_FLOW_QUEUES-1:0];
  reg  [9:0]                                ptr_ram_addr;
  reg  [3:0]                                rd_pri_id;
  reg  [3:0]                                qm_mstate;
  reg                                       ptr_ram_wr;
  reg                                       depth_flag[NUM_FLOW_QUEUES-1:0];
  reg                                       wr_flag;
  reg  [TIMESTAMP_WIDTH-1:0]                frame_elig_time_queue_r[NUM_FLOW_QUEUES-1:0][DEPTH_FLOW_QUEUES-1:0];
  reg                                       ptr_rd;
  reg  [METADATA_WIDTH-1:0]                 pcp_queue_din[NUM_PRIORITY-1:0];
  reg  [NUM_PRIORITY-1:0]                   pcp_queue_wr;
  reg  [4:0]                                rd_group_id;
  reg                                       start_dequeue;
  reg  [NUM_FLOW_QUEUES-1:0]                shift_en;
  reg                                       head_update_finish_flag;
  reg  [METADATA_WIDTH-1:0]                 out_mb_md;
  reg                                       out_mb_md_wr;
  reg [2:0]                                 re_comparator_counter;
  reg                                       stop_dequeue_flag;
  reg                                       dequeue_valid;

  /***************wire******************/
  wire                                      input_data_empty;
  wire [27:0]                               input_data_dout;
  wire [90:0]                               parameter_fifo_out;
  wire [4:0]                                min_index_out_0;
  wire [4:0]                                min_index_out_1;
  wire [4:0]                                min_index_out_2;
  wire [4:0]                                min_index_out_3;
  wire [4:0]                                min_index_out_4;
  wire [4:0]                                min_index_out_5;
  wire [4:0]                                min_index_out_6;
  wire [4:0]                                min_index_out_7;
  wire [9:0]                                ptr_ram_addr_rd;
  wire [METADATA_WIDTH-1:0]                 ptr_ram_dout;
  wire [METADATA_WIDTH-1:0]                 new_head;
  wire [NUM_PRIORITY-1:0]                   pcp_queue_full;
  wire [NUM_PRIORITY-1:0]                   pcp_queue_empty;
  wire [4:0]                                pcp_queue_cnt[NUM_PRIORITY-1:0];
  wire [NUM_PRIORITY-1:0]                   pcp_queue_ack;
  wire                                      q0_flag;
  wire                                      q1_flag;
  wire                                      q2_flag;
  wire                                      q3_flag;
  wire                                      q4_flag;
  wire                                      q5_flag;
  wire                                      q6_flag;
  wire                                      q7_flag;
  wire [METADATA_WIDTH-1:0]                 pcp_queue_dout[NUM_PRIORITY-1:0];
  wire                                      output_queue_empty;
  wire [NUM_PRIORITY-1:0]                   priority_request;
  wire                                      dequeue_done;
  wire [15:0]                               rd_depth_cell_reg;
  wire [METADATA_WIDTH-1:0]                 pcp_queue_din_muxed;
  wire                                      pcp_queue_wr_muxed;
  wire                                      min_index_out_flag_0;
  wire                                      min_index_out_flag_1;
  wire                                      min_index_out_flag_2;
  wire                                      min_index_out_flag_3;
  wire                                      min_index_out_flag_4;
  wire                                      min_index_out_flag_5;
  wire                                      min_index_out_flag_6;
  wire                                      min_index_out_flag_7;

  /***************component*************/
  fifo_d64_in_queue_port u_ptr_group_wr_fifo (
                           .clk        (clk),
                           .rst        (reset),
                           .din        ({group_id[4:0], pcp[2:0], in_metadata[METADATA_WIDTH-1:0]}),
                           .wr_en      (in_metadata_wr),
                           .rd_en      (input_data_rd),
                           .dout       (input_data_dout),
                           .full       (input_data_full),
                           .empty      (input_data_empty),
                           .data_count ()
                         );

  parameter_fifo u_flow_fifo_ft (
                   .clk    (clk),    // input wire clk
                   .rst    (reset),  // input wire rst
                   .din    ({input_flow_ID[31:0], frame_eligible_time[TIMESTAMP_WIDTH-1:0]}),
                   .wr_en  (frame_elig_time_ok_w),  // input wire wr_en
                   .rd_en  (parameter_fifo_rd),     // input wire rd_en
                   .dout   (parameter_fifo_out)
                 );

  sram_w16_d512 u_group_flow_ram (
                  .clka  (clk),
                  .wea   (ptr_ram_wr),
                  .addra (ptr_ram_addr[8:0]),
                  .dina  (ptr_ram_din),
                  .douta (ptr_ram_dout)
                );

  comparator u_comparator_0 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[0][0]),
               .in_data_1          (frame_elig_time_queue_r[1][0]),
               .in_data_2          (frame_elig_time_queue_r[2][0]),
               .in_data_3          (frame_elig_time_queue_r[3][0]),
               .in_data_4          (frame_elig_time_queue_r[4][0]),
               .in_data_5          (frame_elig_time_queue_r[5][0]),
               .in_data_6          (frame_elig_time_queue_r[6][0]),
               .in_data_7          (frame_elig_time_queue_r[7][0]),
               .in_data_8          (frame_elig_time_queue_r[8][0]),
               .in_data_9          (frame_elig_time_queue_r[9][0]),
               .in_data_10         (frame_elig_time_queue_r[10][0]),
               .in_data_11         (frame_elig_time_queue_r[11][0]),
               .in_data_12         (frame_elig_time_queue_r[12][0]),
               .in_data_13         (frame_elig_time_queue_r[13][0]),
               .in_data_14         (frame_elig_time_queue_r[14][0]),
               .in_data_15         (frame_elig_time_queue_r[15][0]),
               .in_data_16         (frame_elig_time_queue_r[16][0]),
               .in_data_17         (frame_elig_time_queue_r[17][0]),
               .in_data_18         (frame_elig_time_queue_r[18][0]),
               .in_data_19         (frame_elig_time_queue_r[19][0]),
               .in_data_20         (frame_elig_time_queue_r[20][0]),
               .in_data_21         (frame_elig_time_queue_r[21][0]),
               .in_data_22         (frame_elig_time_queue_r[22][0]),
               .in_data_23         (frame_elig_time_queue_r[23][0]),
               .in_data_24         (frame_elig_time_queue_r[24][0]),
               .in_data_25         (frame_elig_time_queue_r[25][0]),
               .in_data_26         (frame_elig_time_queue_r[26][0]),
               .in_data_27         (frame_elig_time_queue_r[27][0]),
               .in_data_28         (frame_elig_time_queue_r[28][0]),
               .in_data_29         (frame_elig_time_queue_r[29][0]),
               .in_data_30         (frame_elig_time_queue_r[30][0]),
               .in_data_31         (frame_elig_time_queue_r[31][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_0),
               .min_index_out_flag (min_index_out_flag_0)
             );

  comparator u_comparator_1 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[32][0]),
               .in_data_1          (frame_elig_time_queue_r[33][0]),
               .in_data_2          (frame_elig_time_queue_r[34][0]),
               .in_data_3          (frame_elig_time_queue_r[35][0]),
               .in_data_4          (frame_elig_time_queue_r[36][0]),
               .in_data_5          (frame_elig_time_queue_r[37][0]),
               .in_data_6          (frame_elig_time_queue_r[38][0]),
               .in_data_7          (frame_elig_time_queue_r[39][0]),
               .in_data_8          (frame_elig_time_queue_r[40][0]),
               .in_data_9          (frame_elig_time_queue_r[41][0]),
               .in_data_10         (frame_elig_time_queue_r[42][0]),
               .in_data_11         (frame_elig_time_queue_r[43][0]),
               .in_data_12         (frame_elig_time_queue_r[44][0]),
               .in_data_13         (frame_elig_time_queue_r[45][0]),
               .in_data_14         (frame_elig_time_queue_r[46][0]),
               .in_data_15         (frame_elig_time_queue_r[47][0]),
               .in_data_16         (frame_elig_time_queue_r[48][0]),
               .in_data_17         (frame_elig_time_queue_r[49][0]),
               .in_data_18         (frame_elig_time_queue_r[50][0]),
               .in_data_19         (frame_elig_time_queue_r[51][0]),
               .in_data_20         (frame_elig_time_queue_r[52][0]),
               .in_data_21         (frame_elig_time_queue_r[53][0]),
               .in_data_22         (frame_elig_time_queue_r[54][0]),
               .in_data_23         (frame_elig_time_queue_r[55][0]),
               .in_data_24         (frame_elig_time_queue_r[56][0]),
               .in_data_25         (frame_elig_time_queue_r[57][0]),
               .in_data_26         (frame_elig_time_queue_r[58][0]),
               .in_data_27         (frame_elig_time_queue_r[59][0]),
               .in_data_28         (frame_elig_time_queue_r[60][0]),
               .in_data_29         (frame_elig_time_queue_r[61][0]),
               .in_data_30         (frame_elig_time_queue_r[62][0]),
               .in_data_31         (frame_elig_time_queue_r[63][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_1),
               .min_index_out_flag (min_index_out_flag_1)
             );

  comparator u_comparator_2 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[64][0]),
               .in_data_1          (frame_elig_time_queue_r[65][0]),
               .in_data_2          (frame_elig_time_queue_r[66][0]),
               .in_data_3          (frame_elig_time_queue_r[67][0]),
               .in_data_4          (frame_elig_time_queue_r[68][0]),
               .in_data_5          (frame_elig_time_queue_r[69][0]),
               .in_data_6          (frame_elig_time_queue_r[70][0]),
               .in_data_7          (frame_elig_time_queue_r[71][0]),
               .in_data_8          (frame_elig_time_queue_r[72][0]),
               .in_data_9          (frame_elig_time_queue_r[73][0]),
               .in_data_10         (frame_elig_time_queue_r[74][0]),
               .in_data_11         (frame_elig_time_queue_r[75][0]),
               .in_data_12         (frame_elig_time_queue_r[76][0]),
               .in_data_13         (frame_elig_time_queue_r[77][0]),
               .in_data_14         (frame_elig_time_queue_r[78][0]),
               .in_data_15         (frame_elig_time_queue_r[79][0]),
               .in_data_16         (frame_elig_time_queue_r[80][0]),
               .in_data_17         (frame_elig_time_queue_r[81][0]),
               .in_data_18         (frame_elig_time_queue_r[82][0]),
               .in_data_19         (frame_elig_time_queue_r[83][0]),
               .in_data_20         (frame_elig_time_queue_r[84][0]),
               .in_data_21         (frame_elig_time_queue_r[85][0]),
               .in_data_22         (frame_elig_time_queue_r[86][0]),
               .in_data_23         (frame_elig_time_queue_r[87][0]),
               .in_data_24         (frame_elig_time_queue_r[88][0]),
               .in_data_25         (frame_elig_time_queue_r[89][0]),
               .in_data_26         (frame_elig_time_queue_r[90][0]),
               .in_data_27         (frame_elig_time_queue_r[91][0]),
               .in_data_28         (frame_elig_time_queue_r[92][0]),
               .in_data_29         (frame_elig_time_queue_r[93][0]),
               .in_data_30         (frame_elig_time_queue_r[94][0]),
               .in_data_31         (frame_elig_time_queue_r[95][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_2),
               .min_index_out_flag (min_index_out_flag_2)
             );

  comparator u_comparator_3 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[96][0]),
               .in_data_1          (frame_elig_time_queue_r[97][0]),
               .in_data_2          (frame_elig_time_queue_r[98][0]),
               .in_data_3          (frame_elig_time_queue_r[99][0]),
               .in_data_4          (frame_elig_time_queue_r[100][0]),
               .in_data_5          (frame_elig_time_queue_r[101][0]),
               .in_data_6          (frame_elig_time_queue_r[102][0]),
               .in_data_7          (frame_elig_time_queue_r[103][0]),
               .in_data_8          (frame_elig_time_queue_r[104][0]),
               .in_data_9          (frame_elig_time_queue_r[105][0]),
               .in_data_10         (frame_elig_time_queue_r[106][0]),
               .in_data_11         (frame_elig_time_queue_r[107][0]),
               .in_data_12         (frame_elig_time_queue_r[108][0]),
               .in_data_13         (frame_elig_time_queue_r[109][0]),
               .in_data_14         (frame_elig_time_queue_r[110][0]),
               .in_data_15         (frame_elig_time_queue_r[111][0]),
               .in_data_16         (frame_elig_time_queue_r[112][0]),
               .in_data_17         (frame_elig_time_queue_r[113][0]),
               .in_data_18         (frame_elig_time_queue_r[114][0]),
               .in_data_19         (frame_elig_time_queue_r[115][0]),
               .in_data_20         (frame_elig_time_queue_r[116][0]),
               .in_data_21         (frame_elig_time_queue_r[117][0]),
               .in_data_22         (frame_elig_time_queue_r[118][0]),
               .in_data_23         (frame_elig_time_queue_r[119][0]),
               .in_data_24         (frame_elig_time_queue_r[120][0]),
               .in_data_25         (frame_elig_time_queue_r[121][0]),
               .in_data_26         (frame_elig_time_queue_r[122][0]),
               .in_data_27         (frame_elig_time_queue_r[123][0]),
               .in_data_28         (frame_elig_time_queue_r[124][0]),
               .in_data_29         (frame_elig_time_queue_r[125][0]),
               .in_data_30         (frame_elig_time_queue_r[126][0]),
               .in_data_31         (frame_elig_time_queue_r[127][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_3),
               .min_index_out_flag (min_index_out_flag_3)
             );

  comparator u_comparator_4 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[128][0]),
               .in_data_1          (frame_elig_time_queue_r[129][0]),
               .in_data_2          (frame_elig_time_queue_r[130][0]),
               .in_data_3          (frame_elig_time_queue_r[131][0]),
               .in_data_4          (frame_elig_time_queue_r[132][0]),
               .in_data_5          (frame_elig_time_queue_r[133][0]),
               .in_data_6          (frame_elig_time_queue_r[134][0]),
               .in_data_7          (frame_elig_time_queue_r[135][0]),
               .in_data_8          (frame_elig_time_queue_r[136][0]),
               .in_data_9          (frame_elig_time_queue_r[137][0]),
               .in_data_10         (frame_elig_time_queue_r[138][0]),
               .in_data_11         (frame_elig_time_queue_r[139][0]),
               .in_data_12         (frame_elig_time_queue_r[140][0]),
               .in_data_13         (frame_elig_time_queue_r[141][0]),
               .in_data_14         (frame_elig_time_queue_r[142][0]),
               .in_data_15         (frame_elig_time_queue_r[143][0]),
               .in_data_16         (frame_elig_time_queue_r[144][0]),
               .in_data_17         (frame_elig_time_queue_r[145][0]),
               .in_data_18         (frame_elig_time_queue_r[146][0]),
               .in_data_19         (frame_elig_time_queue_r[147][0]),
               .in_data_20         (frame_elig_time_queue_r[148][0]),
               .in_data_21         (frame_elig_time_queue_r[149][0]),
               .in_data_22         (frame_elig_time_queue_r[150][0]),
               .in_data_23         (frame_elig_time_queue_r[151][0]),
               .in_data_24         (frame_elig_time_queue_r[152][0]),
               .in_data_25         (frame_elig_time_queue_r[153][0]),
               .in_data_26         (frame_elig_time_queue_r[154][0]),
               .in_data_27         (frame_elig_time_queue_r[155][0]),
               .in_data_28         (frame_elig_time_queue_r[156][0]),
               .in_data_29         (frame_elig_time_queue_r[157][0]),
               .in_data_30         (frame_elig_time_queue_r[158][0]),
               .in_data_31         (frame_elig_time_queue_r[159][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_4),
               .min_index_out_flag (min_index_out_flag_4)
             );

  comparator u_comparator_5 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[160][0]),
               .in_data_1          (frame_elig_time_queue_r[161][0]),
               .in_data_2          (frame_elig_time_queue_r[162][0]),
               .in_data_3          (frame_elig_time_queue_r[163][0]),
               .in_data_4          (frame_elig_time_queue_r[164][0]),
               .in_data_5          (frame_elig_time_queue_r[165][0]),
               .in_data_6          (frame_elig_time_queue_r[166][0]),
               .in_data_7          (frame_elig_time_queue_r[167][0]),
               .in_data_8          (frame_elig_time_queue_r[168][0]),
               .in_data_9          (frame_elig_time_queue_r[169][0]),
               .in_data_10         (frame_elig_time_queue_r[170][0]),
               .in_data_11         (frame_elig_time_queue_r[171][0]),
               .in_data_12         (frame_elig_time_queue_r[172][0]),
               .in_data_13         (frame_elig_time_queue_r[173][0]),
               .in_data_14         (frame_elig_time_queue_r[174][0]),
               .in_data_15         (frame_elig_time_queue_r[175][0]),
               .in_data_16         (frame_elig_time_queue_r[176][0]),
               .in_data_17         (frame_elig_time_queue_r[177][0]),
               .in_data_18         (frame_elig_time_queue_r[178][0]),
               .in_data_19         (frame_elig_time_queue_r[179][0]),
               .in_data_20         (frame_elig_time_queue_r[180][0]),
               .in_data_21         (frame_elig_time_queue_r[181][0]),
               .in_data_22         (frame_elig_time_queue_r[182][0]),
               .in_data_23         (frame_elig_time_queue_r[183][0]),
               .in_data_24         (frame_elig_time_queue_r[184][0]),
               .in_data_25         (frame_elig_time_queue_r[185][0]),
               .in_data_26         (frame_elig_time_queue_r[186][0]),
               .in_data_27         (frame_elig_time_queue_r[187][0]),
               .in_data_28         (frame_elig_time_queue_r[188][0]),
               .in_data_29         (frame_elig_time_queue_r[189][0]),
               .in_data_30         (frame_elig_time_queue_r[190][0]),
               .in_data_31         (frame_elig_time_queue_r[191][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_5),
               .min_index_out_flag (min_index_out_flag_5)
             );

  comparator u_comparator_6 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[192][0]),
               .in_data_1          (frame_elig_time_queue_r[193][0]),
               .in_data_2          (frame_elig_time_queue_r[194][0]),
               .in_data_3          (frame_elig_time_queue_r[195][0]),
               .in_data_4          (frame_elig_time_queue_r[196][0]),
               .in_data_5          (frame_elig_time_queue_r[197][0]),
               .in_data_6          (frame_elig_time_queue_r[198][0]),
               .in_data_7          (frame_elig_time_queue_r[199][0]),
               .in_data_8          (frame_elig_time_queue_r[200][0]),
               .in_data_9          (frame_elig_time_queue_r[201][0]),
               .in_data_10         (frame_elig_time_queue_r[202][0]),
               .in_data_11         (frame_elig_time_queue_r[203][0]),
               .in_data_12         (frame_elig_time_queue_r[204][0]),
               .in_data_13         (frame_elig_time_queue_r[205][0]),
               .in_data_14         (frame_elig_time_queue_r[206][0]),
               .in_data_15         (frame_elig_time_queue_r[207][0]),
               .in_data_16         (frame_elig_time_queue_r[208][0]),
               .in_data_17         (frame_elig_time_queue_r[209][0]),
               .in_data_18         (frame_elig_time_queue_r[210][0]),
               .in_data_19         (frame_elig_time_queue_r[211][0]),
               .in_data_20         (frame_elig_time_queue_r[212][0]),
               .in_data_21         (frame_elig_time_queue_r[213][0]),
               .in_data_22         (frame_elig_time_queue_r[214][0]),
               .in_data_23         (frame_elig_time_queue_r[215][0]),
               .in_data_24         (frame_elig_time_queue_r[216][0]),
               .in_data_25         (frame_elig_time_queue_r[217][0]),
               .in_data_26         (frame_elig_time_queue_r[218][0]),
               .in_data_27         (frame_elig_time_queue_r[219][0]),
               .in_data_28         (frame_elig_time_queue_r[220][0]),
               .in_data_29         (frame_elig_time_queue_r[221][0]),
               .in_data_30         (frame_elig_time_queue_r[222][0]),
               .in_data_31         (frame_elig_time_queue_r[223][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_6),
               .min_index_out_flag (min_index_out_flag_6)
             );

  comparator u_comparator_7 (
               .clk                (clk),
               .reset              (reset),
               .in_data_0          (frame_elig_time_queue_r[224][0]),
               .in_data_1          (frame_elig_time_queue_r[225][0]),
               .in_data_2          (frame_elig_time_queue_r[226][0]),
               .in_data_3          (frame_elig_time_queue_r[227][0]),
               .in_data_4          (frame_elig_time_queue_r[228][0]),
               .in_data_5          (frame_elig_time_queue_r[229][0]),
               .in_data_6          (frame_elig_time_queue_r[230][0]),
               .in_data_7          (frame_elig_time_queue_r[231][0]),
               .in_data_8          (frame_elig_time_queue_r[232][0]),
               .in_data_9          (frame_elig_time_queue_r[233][0]),
               .in_data_10         (frame_elig_time_queue_r[234][0]),
               .in_data_11         (frame_elig_time_queue_r[235][0]),
               .in_data_12         (frame_elig_time_queue_r[236][0]),
               .in_data_13         (frame_elig_time_queue_r[237][0]),
               .in_data_14         (frame_elig_time_queue_r[238][0]),
               .in_data_15         (frame_elig_time_queue_r[239][0]),
               .in_data_16         (frame_elig_time_queue_r[240][0]),
               .in_data_17         (frame_elig_time_queue_r[241][0]),
               .in_data_18         (frame_elig_time_queue_r[242][0]),
               .in_data_19         (frame_elig_time_queue_r[243][0]),
               .in_data_20         (frame_elig_time_queue_r[244][0]),
               .in_data_21         (frame_elig_time_queue_r[245][0]),
               .in_data_22         (frame_elig_time_queue_r[246][0]),
               .in_data_23         (frame_elig_time_queue_r[247][0]),
               .in_data_24         (frame_elig_time_queue_r[248][0]),
               .in_data_25         (frame_elig_time_queue_r[249][0]),
               .in_data_26         (frame_elig_time_queue_r[250][0]),
               .in_data_27         (frame_elig_time_queue_r[251][0]),
               .in_data_28         (frame_elig_time_queue_r[252][0]),
               .in_data_29         (frame_elig_time_queue_r[253][0]),
               .in_data_30         (frame_elig_time_queue_r[254][0]),
               .in_data_31         (frame_elig_time_queue_r[255][0]),
               .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
               .min_index_out      (min_index_out_7),
               .min_index_out_flag (min_index_out_flag_7)
             );

  dequeue_process #(
                    .DATA_WIDTH (20),
                    .ADDR_WIDTH (ADDR_WIDTH)
                  ) dequeue_process_inst (
                    .clk            (clk),
                    .reset          (reset),
                    .start_dequeue  (start_dequeue),
                    .head_ptr_in    (head[rd_group_id]),
                    .ptr_ram_dout   (ptr_ram_dout),
                    .pcp_queue_full (pcp_queue_full[rd_pri_id]),
                    .ptr_ram_addr   (ptr_ram_addr_rd),
                    .pcp_queue_din  (pcp_queue_din_muxed),
                    .pcp_queue_wr   (pcp_queue_wr_muxed),
                    .new_head       (new_head),
                    .dequeue_done   (dequeue_done),
                    .rd_depth_cell  (rd_depth_cell_reg)
                  );

  generate
    genvar y;
    for (y = 0; y < NUM_PRIORITY; y = y + 1)
    begin : PRIORITY_QUEUES
      fifo_ft_w16_d64 u_priority_queue (
                        .clk        (clk),
                        .rst        (reset),
                        .din        (pcp_queue_din[y]),
                        .wr_en      (pcp_queue_wr[y]),
                        .rd_en      (pcp_queue_ack[y]),
                        .dout       (pcp_queue_dout[y]),
                        .full       (pcp_queue_full[y]),
                        .empty      (pcp_queue_empty[y]),
                        .data_count (pcp_queue_cnt[y])
                      );
    end
  endgenerate

  priority_arbiter u_priority_arbiter (
                     .clk           (clk),
                     .reset         (reset),
                     .i_req_release (q0_flag | q1_flag | q2_flag | q3_flag | q4_flag | q5_flag | q6_flag | q7_flag),
                     .i_req_in      ({q0_flag, q1_flag, q2_flag, q3_flag, q4_flag, q5_flag, q6_flag, q7_flag}),
                     .o_grant_out   ({pcp_queue_ack[0], pcp_queue_ack[1], pcp_queue_ack[2], pcp_queue_ack[3], pcp_queue_ack[4], pcp_queue_ack[5], pcp_queue_ack[6], pcp_queue_ack[7]})
                   );

  fifo_output_w20 u_fifo_output_w20 (
                    .clk        (clk),              // input wire clk
                    .rst        (reset),            // input wire rst
                    .din        (out_mb_md[METADATA_WIDTH-1:0]),  // input wire [METADATA_WIDTH-1 : 0] din
                    .wr_en      (out_mb_md_wr),     // input wire wr_en
                    .rd_en      (ptr_ack),          // input wire rd_en
                    .dout       (ptr_dout),         // output wire [METADATA_WIDTH-1 : 0] dout
                    .full       (),                 // output wire full
                    .empty      (output_queue_empty), // output wire empty
                    .data_count ()                  // output wire [4 : 0] data_count
                  );

  /***************assign****************/
  assign priority_request = {min_index_out_flag_7, min_index_out_flag_6, min_index_out_flag_5, min_index_out_flag_4, min_index_out_flag_3, min_index_out_flag_2, min_index_out_flag_1, min_index_out_flag_0};
  assign ptr_rdy = !output_queue_empty;
  assign q0_flag = (pcp_queue_cnt[0] == 0) ? 0 : 1;
  assign q1_flag = (pcp_queue_cnt[1] == 0) ? 0 : 1;
  assign q2_flag = (pcp_queue_cnt[2] == 0) ? 0 : 1;
  assign q3_flag = (pcp_queue_cnt[3] == 0) ? 0 : 1;
  assign q4_flag = (pcp_queue_cnt[4] == 0) ? 0 : 1;
  assign q5_flag = (pcp_queue_cnt[5] == 0) ? 0 : 1;
  assign q6_flag = (pcp_queue_cnt[6] == 0) ? 0 : 1;
  assign q7_flag = (pcp_queue_cnt[7] == 0) ? 0 : 1;

  /***************always****************/
  integer i, q, d, e;

  // Input Write State Machine
  always @(posedge clk)
  begin
    if (reset)
    begin
      ptr_din           <= 0;
      ptr_wr            <= 0;
      input_data_rd     <= 0;
      qm_wr_state       <= 0;
      wr_pcp            <= 0;
      flow_id_search_r  <= 0;
      wr_group_id       <= 0;
      parameter_fifo_rd <= 0;
      wr_finish_flag    <= 0;
      frame_elig_time_r <= 0;
    end
    else
    begin
      case (qm_wr_state)
        0:
        begin
          if (!input_data_empty)
          begin
            input_data_rd <= 1;
            qm_wr_state   <= 1;
          end
        end
        1:
        begin
          input_data_rd <= 0;
          qm_wr_state   <= 2;
          if (input_data_dout[14])
            parameter_fifo_rd <= 1;
        end
        2:
        begin
          ptr_din        <= input_data_dout;
          ptr_wr         <= 1;
          wr_finish_flag <= 1;
          qm_wr_state    <= 3;
          wr_pcp         <= input_data_dout[22:20];
          if (input_data_dout[14])
          begin
            frame_elig_time_r <= parameter_fifo_out[TIMESTAMP_WIDTH-1:0];
            flow_id_search_r  <= parameter_fifo_out[90:59];
            wr_group_id[4:0]  <= input_data_dout[27:23];
          end
        end
        3:
        begin
          parameter_fifo_rd <= 0;
          if (ptr_wr_ack)
          begin
            ptr_wr      <= 0;
            qm_wr_state <= 0;
            if (input_data_dout[15])
            begin
              wr_finish_flag <= 0;
            end
          end
        end
      endcase
    end
  end

  // Queue Management Main State Machine
  always @(posedge clk)
  begin
    if (reset)
    begin
      for (i = 0; i < NUM_FLOW_QUEUES; i = i + 1)
      begin
        depth_cell[i]  <= 0;
        tail[i]        <= 0;
        head[i]        <= 0;
        depth_frame[i] <= 0;
        depth_flag[i]  <= 0;
      end
      qm_mstate          <= 0;
      head_update_finish_flag <= 0;
      ptr_wr_ack         <= 0;
      wr_flag            <= 0;
      ptr_ram_addr       <= 0;
      ptr_ram_din        <= 0;
      ptr_ram_wr         <= 0;
    end
    else
    begin
      ptr_wr_ack <= 0;
      ptr_ram_wr <= 0;
      case (qm_mstate)
        0:
        begin
          if (ptr_wr)
          begin
            qm_mstate <= 1;
            wr_flag   <= 1;
          end
          else if (wr_finish_flag == 0 & ptr_rd)
          begin // This seems to be disabled logic
            qm_mstate <= 3;
          end
        end
        1:
        begin
          if (depth_cell[wr_group_id])
          begin
            ptr_ram_wr                       <= 1;
            ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
            ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
            tail[wr_group_id]                <= ptr_din;
          end
          else
          begin
            ptr_ram_wr                       <= 1;
            ptr_ram_addr[9:0]                <= ptr_din[9:0];
            ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
            tail[wr_group_id]                <= ptr_din;
            head[wr_group_id]                <= ptr_din;
          end
          depth_cell[wr_group_id] <= depth_cell[wr_group_id] + 1;
          if (ptr_din[15])
          begin // last cell
            depth_flag[wr_group_id]  <= 1;
            depth_frame[wr_group_id] <= depth_frame[wr_group_id] + 1;
          end
          else if (ptr_din[14])
          begin // first cell
          end
          ptr_wr_ack <= 1;
          qm_mstate  <= 2;
        end
        2:
        begin
          ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
          ptr_ram_din[METADATA_WIDTH-1:0] <= tail[wr_group_id][METADATA_WIDTH-1:0];
          ptr_ram_wr                       <= 1;
          qm_mstate                        <= 0;
          wr_flag                          <= 0;
        end
        3:
        begin
          ptr_ram_addr[9:0] <= ptr_ram_addr_rd;
          if (dequeue_done)
          begin
            qm_mstate          <= 4;
            head_update_finish_flag <= 1;
          end
        end
        4:
        begin
          qm_mstate                 <= 5;
          head[rd_group_id]         <= new_head;
          depth_frame[rd_group_id]  <= depth_frame[rd_group_id] - 1;
          depth_cell[rd_group_id]   <= depth_cell[rd_group_id] - rd_depth_cell_reg;
          head_update_finish_flag        <= 0;
        end
        5:
        begin
          qm_mstate <= 6;
          if (depth_frame[rd_group_id] == 0)
            depth_flag[rd_group_id] <= 0;
        end
        6:
        begin
          qm_mstate <= 7;
        end
        7:
        begin
          qm_mstate <= 8;
        end
        8:
        begin
          qm_mstate <= 0;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    if (reset)
    begin
      for (q = 0; q < NUM_FLOW_QUEUES; q = q + 1)
      begin
        for (e = 0; e < DEPTH_FLOW_QUEUES; e = e + 1)
        begin
          frame_elig_time_queue_r[q][e] <= 0;
        end
      end
      shift_en <= 0;
    end
    else
    begin
      if (dequeue_done)
      begin
        for (d = 0; d < DEPTH_FLOW_QUEUES-1; d = d + 1)
        begin
          frame_elig_time_queue_r[rd_group_id][d] <= frame_elig_time_queue_r[rd_group_id][d+1];
        end
        frame_elig_time_queue_r[rd_group_id][DEPTH_FLOW_QUEUES-1] <= 0;
      end
      else if (qm_mstate == 1 && ptr_din[15])
      begin // last cell in write state
        frame_elig_time_queue_r[wr_group_id][depth_frame[wr_group_id]] <= frame_elig_time_r;
      end
    end
  end



  always @(posedge clk)
  begin
    if (reset)
    begin
      re_comparator_counter <= 0;
      dequeue_valid <= 1;
    end
    else if(stop_dequeue_flag)
    begin
      if (re_comparator_counter < 5)
      begin
        re_comparator_counter <= re_comparator_counter + 1;
        dequeue_valid <= 0;
      end
      else
      begin
        re_comparator_counter <= 0; // Reset after reaching the last priority
        dequeue_valid <= 1; // Reset dequeue_valid to allow new dequeue requests
      end
    end
  end


  always @(*)
  begin
    // Default values
    // rd_group_id   = 0;
    start_dequeue = 0;
    ptr_rd        = 0;
    // Strict Priority: 7 > 6 > 5 > 4 > 3 > 2 > 1 > 0
    if(dequeue_valid)
    begin
      stop_dequeue_flag = 0; // Set flag to indicate dequeue process has started
      if (priority_request[7])
      begin
        rd_group_id   = 224 + min_index_out_7; // queues 224-255
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 7; // Set read priority ID to 7
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset start_dequeue after processing
        end
      end
      else if (priority_request[6])
      begin
        rd_group_id   = 192 + min_index_out_6; // queues 192-223
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 6; // Set read priority ID to 6
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset start_dequeue after processing
        end
      end
      else if (priority_request[5])
      begin
        rd_group_id   = 160 + min_index_out_5; // queues 160-191
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 5; // Set read priority ID to 5
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset start_dequeue after processing
        end
      end
      else if (priority_request[4])
      begin
        rd_group_id   = 128 + min_index_out_4; // queues 128-159
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 4; // Set read priority ID to 4
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset start_dequeue after processing
        end
      end
      else if (priority_request[3])
      begin
        rd_group_id   = 96 + min_index_out_3; // queues 96-127
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 3; // Set read priority ID to 3
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset start_dequeue after processing
        end
      end
      else if (priority_request[2])
      begin
        rd_group_id   = 64 + min_index_out_2; // queues 64-95
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 2; // Set read priority ID to 2
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset dequeue flag after processing
        end
      end
      else if (priority_request[1])
      begin
        rd_group_id   = 32 + min_index_out_1; // queues 32-63
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 1; // Set read priority ID to 1
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset dequeue flag after processing
        end
      end
      else if (priority_request[0])
      begin
        rd_group_id   = 0 + min_index_out_0; // queues 0-31
        start_dequeue = (wr_finish_flag == 0) ? 1 : 0; // Only start dequeue if not in write state
        ptr_rd        = 1;
        rd_pri_id     = 0; // Set read priority ID to 0
        if(dequeue_done)
        begin
          stop_dequeue_flag=1; // Reset dequeue flag after processing
          start_dequeue=0; // Reset dequeue flag after processing
        end
      end
      else if (head_update_finish_flag)
      begin
        start_dequeue = 0;
      end
    end
  end

  always @(*)
  begin
    pcp_queue_din[0] = 0;
    pcp_queue_din[1] = 0;
    pcp_queue_din[2] = 0;
    pcp_queue_din[3] = 0;
    pcp_queue_din[4] = 0;
    pcp_queue_din[5] = 0;
    pcp_queue_din[6] = 0;
    pcp_queue_din[7] = 0;
    pcp_queue_wr[0]  = 0;
    pcp_queue_wr[1]  = 0;
    pcp_queue_wr[2]  = 0;
    pcp_queue_wr[3]  = 0;
    pcp_queue_wr[4]  = 0;
    pcp_queue_wr[5]  = 0;
    pcp_queue_wr[6]  = 0;
    pcp_queue_wr[7]  = 0;

    case (rd_pri_id)
      4'd0:
      begin
        pcp_queue_din[0] = pcp_queue_din_muxed;
        pcp_queue_wr[0]  = pcp_queue_wr_muxed;
      end
      4'd1:
      begin
        pcp_queue_din[1] = pcp_queue_din_muxed;
        pcp_queue_wr[1]  = pcp_queue_wr_muxed;
      end
      4'd2:
      begin
        pcp_queue_din[2] = pcp_queue_din_muxed;
        pcp_queue_wr[2]  = pcp_queue_wr_muxed;
      end
      4'd3:
      begin
        pcp_queue_din[3] = pcp_queue_din_muxed;
        pcp_queue_wr[3]  = pcp_queue_wr_muxed;
      end
      4'd4:
      begin
        pcp_queue_din[4] = pcp_queue_din_muxed;
        pcp_queue_wr[4]  = pcp_queue_wr_muxed;
      end
      4'd5:
      begin
        pcp_queue_din[5] = pcp_queue_din_muxed;
        pcp_queue_wr[5]  = pcp_queue_wr_muxed;
      end
      4'd6:
      begin
        pcp_queue_din[6] = pcp_queue_din_muxed;
        pcp_queue_wr[6]  = pcp_queue_wr_muxed;
      end
      4'd7:
      begin
        pcp_queue_din[7] = pcp_queue_din_muxed;
        pcp_queue_wr[7]  = pcp_queue_wr_muxed;
      end
      default:
      begin
        pcp_queue_din[0] = 0;
        pcp_queue_wr[0]  = 0;
      end
    endcase
  end

  always @(posedge clk)
  begin
    if (reset == 1'b1)
    begin
      out_mb_md    <= 20'd0;
      out_mb_md_wr <= 'b0;
    end
    else
    begin
      if (pcp_queue_ack[0] == 1'b1 & !pcp_queue_empty[0])
      begin
        out_mb_md    <= pcp_queue_dout[0][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[1] == 1'b1 & !pcp_queue_empty[1])
      begin
        out_mb_md    <= pcp_queue_dout[1][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[2] == 1'b1 & !pcp_queue_empty[2])
      begin
        out_mb_md    <= pcp_queue_dout[2][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[3] == 1'b1 & !pcp_queue_empty[3])
      begin
        out_mb_md    <= pcp_queue_dout[3][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[4] == 1'b1 & !pcp_queue_empty[4])
      begin
        out_mb_md    <= pcp_queue_dout[4][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[5] == 1'b1 & !pcp_queue_empty[5])
      begin
        out_mb_md    <= pcp_queue_dout[5][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[6] == 1'b1 & !pcp_queue_empty[6])
      begin
        out_mb_md    <= pcp_queue_dout[6][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else if (pcp_queue_ack[7] == 1'b1 & !pcp_queue_empty[7])
      begin
        out_mb_md    <= pcp_queue_dout[7][METADATA_WIDTH-1:0];
        out_mb_md_wr <= 1'b1;
      end
      else
      begin
        out_mb_md    <= 'b0;
        out_mb_md_wr <= 1'b0;
      end
    end
  end

endmodule
