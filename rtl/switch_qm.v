`timescale 1ns / 1ps
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

module switch_qm #(
    parameter NUM_FLOW_QUEUES   = 24,
    parameter NUM_PRIORITY      = 8,
    parameter DEPTH_FLOW_QUEUES = 8,
    parameter TIMESTAMP_WIDTH   = 59,
    parameter PORT_NUM          = 4,
    parameter ADDR_WIDTH        = 10,
    parameter METADATA_WIDTH    = 20
)(
    input  wire                           clk,
    input  wire                           reset,
    input  wire                           in_metadata_wr,
    input  wire [TIMESTAMP_WIDTH-1:0]   frame_eligible_time,
    input  wire                           frame_elig_time_ok_w,
    input  wire [4:0]                   group_id,
    input  wire                           ptr_ack,
    input  wire [2:0]                    pcp,
    input  wire [METADATA_WIDTH-1:0]    in_metadata,
    input  wire [31:0]                   input_flow_ID,
    input  wire [TIMESTAMP_WIDTH-1:0]   local_clock,
    output wire                           input_data_full,
    output wire                           ptr_rdy,
    output wire [METADATA_WIDTH-1:0]    ptr_dout
);

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
    reg  [2:0]                                re_comparator_counter;
    reg                                       stop_dequeue_flag;
    reg                                       dequeue_valid;

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
        .clk    (clk),
        .rst    (reset),
        .din    ({input_flow_ID[31:0], frame_eligible_time[TIMESTAMP_WIDTH-1:0]}),
        .wr_en  (frame_elig_time_ok_w),
        .rd_en  (parameter_fifo_rd),
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
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_0),
        .min_index_out_flag (min_index_out_flag_0)
    );

    comparator u_comparator_1 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[3][0]),
        .in_data_1          (frame_elig_time_queue_r[4][0]),
        .in_data_2          (frame_elig_time_queue_r[5][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_1),
        .min_index_out_flag (min_index_out_flag_1)
    );

    comparator u_comparator_2 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[6][0]),
        .in_data_1          (frame_elig_time_queue_r[7][0]),
        .in_data_2          (frame_elig_time_queue_r[8][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_2),
        .min_index_out_flag (min_index_out_flag_2)
    );

    comparator u_comparator_3 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[9][0]),
        .in_data_1          (frame_elig_time_queue_r[10][0]),
        .in_data_2          (frame_elig_time_queue_r[11][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_3),
        .min_index_out_flag (min_index_out_flag_3)
    );

    comparator u_comparator_4 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[12][0]),
        .in_data_1          (frame_elig_time_queue_r[13][0]),
        .in_data_2          (frame_elig_time_queue_r[14][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_4),
        .min_index_out_flag (min_index_out_flag_4)
    );

    comparator u_comparator_5 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[15][0]),
        .in_data_1          (frame_elig_time_queue_r[16][0]),
        .in_data_2          (frame_elig_time_queue_r[17][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_5),
        .min_index_out_flag (min_index_out_flag_5)
    );

    comparator u_comparator_6 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[18][0]),
        .in_data_1          (frame_elig_time_queue_r[19][0]),
        .in_data_2          (frame_elig_time_queue_r[20][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_6),
        .min_index_out_flag (min_index_out_flag_6)
    );

    comparator u_comparator_7 (
        .clk                (clk),
        .reset              (reset),
        .in_data_0          (frame_elig_time_queue_r[21][0]),
        .in_data_1          (frame_elig_time_queue_r[22][0]),
        .in_data_2          (frame_elig_time_queue_r[23][0]),
        .local_clock        (local_clock[TIMESTAMP_WIDTH-1:0]),
        .min_index_out      (min_index_out_7),
        .min_index_out_flag (min_index_out_flag_7)
    );

    dequeue_process #(
        .DATA_WIDTH (METADATA_WIDTH),
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
        for (y = 0; y < NUM_PRIORITY; y = y + 1) begin : PRIORITY_QUEUES
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
        .clk        (clk),
        .rst        (reset),
        .din        (out_mb_md[METADATA_WIDTH-1:0]),
        .wr_en      (out_mb_md_wr),
        .rd_en      (ptr_ack),
        .dout       (ptr_dout),
        .full       (),
        .empty      (output_queue_empty),
        .data_count ()
    );

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

    integer i, q, d, e;

    always @(posedge clk) begin
        if (reset) begin
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
        end else begin
            case (qm_wr_state)
                0: begin
                    if (!input_data_empty) begin
                        input_data_rd <= 1;
                        qm_wr_state   <= 1;
                    end
                end
                1: begin
                    input_data_rd <= 0;
                    qm_wr_state   <= 2;
                    if (input_data_dout[14]) parameter_fifo_rd <= 1;
                end
                2: begin
                    ptr_din        <= input_data_dout;
                    ptr_wr         <= 1;
                    wr_finish_flag <= 1;
                    qm_wr_state    <= 3;
                    wr_pcp         <= input_data_dout[22:20];
                    if (input_data_dout[14]) begin
                        frame_elig_time_r <= parameter_fifo_out[TIMESTAMP_WIDTH-1:0];
                        flow_id_search_r  <= parameter_fifo_out[90:59];
                        wr_group_id[4:0] <= input_data_dout[27:23];
                    end
                end
                3: begin
                    parameter_fifo_rd <= 0;
                    if (ptr_wr_ack) begin
                        ptr_wr      <= 0;
                        qm_wr_state <= 0;
                        if (input_data_dout[15]) wr_finish_flag <= 0;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_FLOW_QUEUES; i = i + 1) begin
                depth_cell[i]  <= 0;
                tail[i]        <= 0;
                head[i]        <= 0;
                depth_frame[i] <= 0;
                depth_flag[i]  <= 0;
            end
            qm_mstate                <= 0;
            head_update_finish_flag  <= 0;
            ptr_wr_ack               <= 0;
            wr_flag                  <= 0;
            ptr_ram_addr             <= 0;
            ptr_ram_din              <= 0;
            ptr_ram_wr               <= 0;
        end else begin
            ptr_wr_ack <= 0;
            ptr_ram_wr <= 0;
            case (qm_mstate)
                0: begin
                    if (ptr_wr) begin
                        qm_mstate <= 1;
                        wr_flag   <= 1;
                    end else if (wr_finish_flag == 0 & ptr_rd) begin
                        qm_mstate <= 3;
                    end
                end
                1: begin
                    if (depth_cell[wr_group_id]) begin
                        ptr_ram_wr                       <= 1;
                        ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
                        ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
                        tail[wr_group_id]                <= ptr_din;
                    end else begin
                        ptr_ram_wr                       <= 1;
                        ptr_ram_addr[9:0]                <= ptr_din[9:0];
                        ptr_ram_din[METADATA_WIDTH-1:0] <= ptr_din[METADATA_WIDTH-1:0];
                        tail[wr_group_id]                <= ptr_din;
                        head[wr_group_id]                <= ptr_din;
                    end
                    depth_cell[wr_group_id] <= depth_cell[wr_group_id] + 1;
                    if (ptr_din[15]) begin
                        depth_flag[wr_group_id]  <= 1;
                        depth_frame[wr_group_id] <= depth_frame[wr_group_id] + 1;
                    end
                    ptr_wr_ack <= 1;
                    qm_mstate  <= 2;
                end
                2: begin
                    ptr_ram_addr[9:0]                <= tail[wr_group_id][9:0];
                    ptr_ram_din[METADATA_WIDTH-1:0] <= tail[wr_group_id][METADATA_WIDTH-1:0];
                    ptr_ram_wr                       <= 1;
                    qm_mstate                        <= 0;
                    wr_flag                          <= 0;
                end
                3: begin
                    ptr_ram_addr[9:0] <= ptr_ram_addr_rd;
                    if (dequeue_done) begin
                        qm_mstate                 <= 4;
                        head_update_finish_flag  <= 1;
                    end
                end
                4: begin
                    qm_mstate                <= 5;
                    head[rd_group_id]        <= new_head;
                    depth_frame[rd_group_id] <= depth_frame[rd_group_id] - 1;
                    depth_cell[rd_group_id]   <= depth_cell[rd_group_id] - rd_depth_cell_reg;
                    head_update_finish_flag   <= 0;
                end
                5: begin
                    qm_mstate <= 6;
                    if (depth_frame[rd_group_id] == 0) depth_flag[rd_group_id] <= 0;
                end
                6: qm_mstate <= 7;
                7: qm_mstate <= 8;
                8: qm_mstate <= 0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (q = 0; q < NUM_FLOW_QUEUES; q = q + 1) begin
                for (e = 0; e < DEPTH_FLOW_QUEUES; e = e + 1) begin
                    frame_elig_time_queue_r[q][e] <= 0;
                end
            end
            shift_en <= 0;
        end else begin
            if (dequeue_done) begin
                for (d = 0; d < DEPTH_FLOW_QUEUES-1; d = d + 1) begin
                    frame_elig_time_queue_r[rd_group_id][d] <= frame_elig_time_queue_r[rd_group_id][d+1];
                end
                frame_elig_time_queue_r[rd_group_id][DEPTH_FLOW_QUEUES-1] <= 0;
            end else if (qm_mstate == 1 && ptr_din[15]) begin
                frame_elig_time_queue_r[wr_group_id][depth_frame[wr_group_id]] <= frame_elig_time_r;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            re_comparator_counter <= 0;
            dequeue_valid <= 1;
        end else if (stop_dequeue_flag) begin
            if (re_comparator_counter < 5) begin
                re_comparator_counter <= re_comparator_counter + 1;
                dequeue_valid <= 0;
            end else begin
                re_comparator_counter <= 0;
                dequeue_valid <= 1;
            end
        end
    end

    always @(*) begin
        start_dequeue = 0;
        ptr_rd        = 0;
        if (dequeue_valid) begin
            stop_dequeue_flag = 0;
            if (priority_request[7]) begin
                rd_group_id   = 21 + min_index_out_7;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 7;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[6]) begin
                rd_group_id   = 18 + min_index_out_6;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 6;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[5]) begin
                rd_group_id   = 15 + min_index_out_5;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 5;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[4]) begin
                rd_group_id   = 12 + min_index_out_4;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 4;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[3]) begin
                rd_group_id   = 9 + min_index_out_3;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 3;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[2]) begin
                rd_group_id   = 6 + min_index_out_2;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 2;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[1]) begin
                rd_group_id   = 3 + min_index_out_1;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 1;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (priority_request[0]) begin
                rd_group_id   = 0 + min_index_out_0;
                start_dequeue = (wr_finish_flag == 0) ? 1 : 0;
                ptr_rd        = 1;
                rd_pri_id     = 0;
                if (dequeue_done) begin
                    stop_dequeue_flag = 1;
                    start_dequeue    = 0;
                end
            end else if (head_update_finish_flag) begin
                start_dequeue = 0;
            end
        end
    end

    always @(*) begin
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
            4'd0: begin
                pcp_queue_din[0] = pcp_queue_din_muxed;
                pcp_queue_wr[0]  = pcp_queue_wr_muxed;
            end
            4'd1: begin
                pcp_queue_din[1] = pcp_queue_din_muxed;
                pcp_queue_wr[1]  = pcp_queue_wr_muxed;
            end
            4'd2: begin
                pcp_queue_din[2] = pcp_queue_din_muxed;
                pcp_queue_wr[2]  = pcp_queue_wr_muxed;
            end
            4'd3: begin
                pcp_queue_din[3] = pcp_queue_din_muxed;
                pcp_queue_wr[3]  = pcp_queue_wr_muxed;
            end
            4'd4: begin
                pcp_queue_din[4] = pcp_queue_din_muxed;
                pcp_queue_wr[4]  = pcp_queue_wr_muxed;
            end
            4'd5: begin
                pcp_queue_din[5] = pcp_queue_din_muxed;
                pcp_queue_wr[5]  = pcp_queue_wr_muxed;
            end
            4'd6: begin
                pcp_queue_din[6] = pcp_queue_din_muxed;
                pcp_queue_wr[6]  = pcp_queue_wr_muxed;
            end
            4'd7: begin
                pcp_queue_din[7] = pcp_queue_din_muxed;
                pcp_queue_wr[7]  = pcp_queue_wr_muxed;
            end
            default: begin
                pcp_queue_din[0] = 0;
                pcp_queue_wr[0]  = 0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            out_mb_md    <= 20'd0;
            out_mb_md_wr <= 'b0;
        end else begin
            if (pcp_queue_ack[0] == 1'b1 & !pcp_queue_empty[0]) begin
                out_mb_md    <= pcp_queue_dout[0][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[1] == 1'b1 & !pcp_queue_empty[1]) begin
                out_mb_md    <= pcp_queue_dout[1][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[2] == 1'b1 & !pcp_queue_empty[2]) begin
                out_mb_md    <= pcp_queue_dout[2][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[3] == 1'b1 & !pcp_queue_empty[3]) begin
                out_mb_md    <= pcp_queue_dout[3][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[4] == 1'b1 & !pcp_queue_empty[4]) begin
                out_mb_md    <= pcp_queue_dout[4][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[5] == 1'b1 & !pcp_queue_empty[5]) begin
                out_mb_md    <= pcp_queue_dout[5][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[6] == 1'b1 & !pcp_queue_empty[6]) begin
                out_mb_md    <= pcp_queue_dout[6][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else if (pcp_queue_ack[7] == 1'b1 & !pcp_queue_empty[7]) begin
                out_mb_md    <= pcp_queue_dout[7][METADATA_WIDTH-1:0];
                out_mb_md_wr <= 1'b1;
            end else begin
                out_mb_md    <= 'b0;
                out_mb_md_wr <= 1'b0;
            end
        end
    end

endmodule
