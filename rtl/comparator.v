module comparator #(
    parameter DATA_WIDTH = 59
  ) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire [DATA_WIDTH-1:0]  in_data_0,
    input  wire [DATA_WIDTH-1:0]  in_data_1,
    input  wire [DATA_WIDTH-1:0]  in_data_2,
    input  wire [DATA_WIDTH-1:0]  in_data_3,
    input  wire [DATA_WIDTH-1:0]  in_data_4,
    input  wire [DATA_WIDTH-1:0]  in_data_5,
    input  wire [DATA_WIDTH-1:0]  in_data_6,
    input  wire [DATA_WIDTH-1:0]  in_data_7,
    input  wire [DATA_WIDTH-1:0]  in_data_8,
    input  wire [DATA_WIDTH-1:0]  in_data_9,
    input  wire [DATA_WIDTH-1:0]  in_data_10,
    input  wire [DATA_WIDTH-1:0]  in_data_11,
    input  wire [DATA_WIDTH-1:0]  in_data_12,
    input  wire [DATA_WIDTH-1:0]  in_data_13,
    input  wire [DATA_WIDTH-1:0]  in_data_14,
    input  wire [DATA_WIDTH-1:0]  in_data_15,
    input  wire [DATA_WIDTH-1:0]  in_data_16,
    input  wire [DATA_WIDTH-1:0]  in_data_17,
    input  wire [DATA_WIDTH-1:0]  in_data_18,
    input  wire [DATA_WIDTH-1:0]  in_data_19,
    input  wire [DATA_WIDTH-1:0]  in_data_20,
    input  wire [DATA_WIDTH-1:0]  in_data_21,
    input  wire [DATA_WIDTH-1:0]  in_data_22,
    input  wire [DATA_WIDTH-1:0]  in_data_23,
    input  wire [DATA_WIDTH-1:0]  in_data_24,
    input  wire [DATA_WIDTH-1:0]  in_data_25,
    input  wire [DATA_WIDTH-1:0]  in_data_26,
    input  wire [DATA_WIDTH-1:0]  in_data_27,
    input  wire [DATA_WIDTH-1:0]  in_data_28,
    input  wire [DATA_WIDTH-1:0]  in_data_29,
    input  wire [DATA_WIDTH-1:0]  in_data_30,
    input  wire [DATA_WIDTH-1:0]  in_data_31,
    input  wire [DATA_WIDTH-1:0]  local_clock,
    output reg  [4:0]             min_index_out,  // 5 bits for 32 inputs (0-31)
    output reg                    min_index_out_flag
  );

  // --------- 1st stage: Zero mask & latch inputs ---------
  reg [DATA_WIDTH-1:0] stage1_data [0:31];

  // --------- 2nd stage: Compare pairs (16 pairs) ---------
  reg [DATA_WIDTH-1:0] stage2_min [0:15];
  reg [4:0]            stage2_idx [0:15];

  // --------- 3rd stage: Compare groups of 4 (8 groups) ---------
  reg [DATA_WIDTH-1:0] stage3_min [0:7];
  reg [4:0]            stage3_idx [0:7];

  // --------- 4th stage: Compare groups of 8 (4 groups) ---------
  reg [DATA_WIDTH-1:0] stage4_min [0:3];
  reg [4:0]            stage4_idx [0:3];

  // --------- 5th stage: Compare groups of 16 (2 groups) ---------
  reg [DATA_WIDTH-1:0] stage5_min [0:1];
  reg [4:0]            stage5_idx [0:1];

  // --------- 6th stage: Final comparison & valid output ---------
  reg [DATA_WIDTH-1:0] min_val_reg;
  reg [4:0]            min_idx_reg;
  reg [DATA_WIDTH-1:0] local_clock_pipe;

  // Loop variables
  integer j;

  always @(posedge clk)
  begin
    if (reset)
    begin
      stage1_data[0]  <= {DATA_WIDTH{1'b1}};
      stage1_data[1]  <= {DATA_WIDTH{1'b1}};
      stage1_data[2]  <= {DATA_WIDTH{1'b1}};
      stage1_data[3]  <= {DATA_WIDTH{1'b1}};
      stage1_data[4]  <= {DATA_WIDTH{1'b1}};
      stage1_data[5]  <= {DATA_WIDTH{1'b1}};
      stage1_data[6]  <= {DATA_WIDTH{1'b1}};
      stage1_data[7]  <= {DATA_WIDTH{1'b1}};
      stage1_data[8]  <= {DATA_WIDTH{1'b1}};
      stage1_data[9]  <= {DATA_WIDTH{1'b1}};
      stage1_data[10] <= {DATA_WIDTH{1'b1}};
      stage1_data[11] <= {DATA_WIDTH{1'b1}};
      stage1_data[12] <= {DATA_WIDTH{1'b1}};
      stage1_data[13] <= {DATA_WIDTH{1'b1}};
      stage1_data[14] <= {DATA_WIDTH{1'b1}};
      stage1_data[15] <= {DATA_WIDTH{1'b1}};
      stage1_data[16] <= {DATA_WIDTH{1'b1}};
      stage1_data[17] <= {DATA_WIDTH{1'b1}};
      stage1_data[18] <= {DATA_WIDTH{1'b1}};
      stage1_data[19] <= {DATA_WIDTH{1'b1}};
      stage1_data[20] <= {DATA_WIDTH{1'b1}};
      stage1_data[21] <= {DATA_WIDTH{1'b1}};
      stage1_data[22] <= {DATA_WIDTH{1'b1}};
      stage1_data[23] <= {DATA_WIDTH{1'b1}};
      stage1_data[24] <= {DATA_WIDTH{1'b1}};
      stage1_data[25] <= {DATA_WIDTH{1'b1}};
      stage1_data[26] <= {DATA_WIDTH{1'b1}};
      stage1_data[27] <= {DATA_WIDTH{1'b1}};
      stage1_data[28] <= {DATA_WIDTH{1'b1}};
      stage1_data[29] <= {DATA_WIDTH{1'b1}};
      stage1_data[30] <= {DATA_WIDTH{1'b1}};
      stage1_data[31] <= {DATA_WIDTH{1'b1}};
    end
    else
    begin
      stage1_data[0]  <= (in_data_0 != 0)  ? in_data_0  : {DATA_WIDTH{1'b1}};
      stage1_data[1]  <= (in_data_1 != 0)  ? in_data_1  : {DATA_WIDTH{1'b1}};
      stage1_data[2]  <= (in_data_2 != 0)  ? in_data_2  : {DATA_WIDTH{1'b1}};
      stage1_data[3]  <= (in_data_3 != 0)  ? in_data_3  : {DATA_WIDTH{1'b1}};
      stage1_data[4]  <= (in_data_4 != 0)  ? in_data_4  : {DATA_WIDTH{1'b1}};
      stage1_data[5]  <= (in_data_5 != 0)  ? in_data_5  : {DATA_WIDTH{1'b1}};
      stage1_data[6]  <= (in_data_6 != 0)  ? in_data_6  : {DATA_WIDTH{1'b1}};
      stage1_data[7]  <= (in_data_7 != 0)  ? in_data_7  : {DATA_WIDTH{1'b1}};
      stage1_data[8]  <= (in_data_8 != 0)  ? in_data_8  : {DATA_WIDTH{1'b1}};
      stage1_data[9]  <= (in_data_9 != 0)  ? in_data_9  : {DATA_WIDTH{1'b1}};
      stage1_data[10] <= (in_data_10 != 0) ? in_data_10 : {DATA_WIDTH{1'b1}};
      stage1_data[11] <= (in_data_11 != 0) ? in_data_11 : {DATA_WIDTH{1'b1}};
      stage1_data[12] <= (in_data_12 != 0) ? in_data_12 : {DATA_WIDTH{1'b1}};
      stage1_data[13] <= (in_data_13 != 0) ? in_data_13 : {DATA_WIDTH{1'b1}};
      stage1_data[14] <= (in_data_14 != 0) ? in_data_14 : {DATA_WIDTH{1'b1}};
      stage1_data[15] <= (in_data_15 != 0) ? in_data_15 : {DATA_WIDTH{1'b1}};
      stage1_data[16] <= (in_data_16 != 0) ? in_data_16 : {DATA_WIDTH{1'b1}};
      stage1_data[17] <= (in_data_17 != 0) ? in_data_17 : {DATA_WIDTH{1'b1}};
      stage1_data[18] <= (in_data_18 != 0) ? in_data_18 : {DATA_WIDTH{1'b1}};
      stage1_data[19] <= (in_data_19 != 0) ? in_data_19 : {DATA_WIDTH{1'b1}};
      stage1_data[20] <= (in_data_20 != 0) ? in_data_20 : {DATA_WIDTH{1'b1}};
      stage1_data[21] <= (in_data_21 != 0) ? in_data_21 : {DATA_WIDTH{1'b1}};
      stage1_data[22] <= (in_data_22 != 0) ? in_data_22 : {DATA_WIDTH{1'b1}};
      stage1_data[23] <= (in_data_23 != 0) ? in_data_23 : {DATA_WIDTH{1'b1}};
      stage1_data[24] <= (in_data_24 != 0) ? in_data_24 : {DATA_WIDTH{1'b1}};
      stage1_data[25] <= (in_data_25 != 0) ? in_data_25 : {DATA_WIDTH{1'b1}};
      stage1_data[26] <= (in_data_26 != 0) ? in_data_26 : {DATA_WIDTH{1'b1}};
      stage1_data[27] <= (in_data_27 != 0) ? in_data_27 : {DATA_WIDTH{1'b1}};
      stage1_data[28] <= (in_data_28 != 0) ? in_data_28 : {DATA_WIDTH{1'b1}};
      stage1_data[29] <= (in_data_29 != 0) ? in_data_29 : {DATA_WIDTH{1'b1}};
      stage1_data[30] <= (in_data_30 != 0) ? in_data_30 : {DATA_WIDTH{1'b1}};
      stage1_data[31] <= (in_data_31 != 0) ? in_data_31 : {DATA_WIDTH{1'b1}};
    end
  end

  // --------- 2nd stage: Compare pairs (16 pairs) ---------
  always @(posedge clk)
  begin
    if (reset)
    begin
      for (j = 0; j < 16; j = j + 1)
      begin
        stage2_min[j] <= {DATA_WIDTH{1'b1}};
        stage2_idx[j] <= 5'd0;
      end
    end
    else
    begin
      for (j = 0; j < 16; j = j + 1)
      begin
        if (stage1_data[j*2] <= stage1_data[j*2+1])
        begin
          stage2_min[j] <= stage1_data[j*2];
          stage2_idx[j] <= j*2;
        end
        else
        begin
          stage2_min[j] <= stage1_data[j*2+1];
          stage2_idx[j] <= j*2+1;
        end
      end
    end
  end

  // --------- 3rd stage: Compare groups of 4 (8 groups) ---------
  always @(posedge clk)
  begin
    if (reset)
    begin
      for (j = 0; j < 8; j = j + 1)
      begin
        stage3_min[j] <= {DATA_WIDTH{1'b1}};
        stage3_idx[j] <= 5'd0;
      end
    end
    else
    begin
      for (j = 0; j < 8; j = j + 1)
      begin
        if (stage2_min[j*2] <= stage2_min[j*2+1])
        begin
          stage3_min[j] <= stage2_min[j*2];
          stage3_idx[j] <= stage2_idx[j*2];
        end
        else
        begin
          stage3_min[j] <= stage2_min[j*2+1];
          stage3_idx[j] <= stage2_idx[j*2+1];
        end
      end
    end
  end

  // --------- 4th stage: Compare groups of 8 (4 groups) ---------
  always @(posedge clk)
  begin
    if (reset)
    begin
      for (j = 0; j < 4; j = j + 1)
      begin
        stage4_min[j] <= {DATA_WIDTH{1'b1}};
        stage4_idx[j] <= 5'd0;
      end
    end
    else
    begin
      for (j = 0; j < 4; j = j + 1)
      begin
        if (stage3_min[j*2] <= stage3_min[j*2+1])
        begin
          stage4_min[j] <= stage3_min[j*2];
          stage4_idx[j] <= stage3_idx[j*2];
        end
        else
        begin
          stage4_min[j] <= stage3_min[j*2+1];
          stage4_idx[j] <= stage3_idx[j*2+1];
        end
      end
    end
  end

  // --------- 5th stage: Compare groups of 16 (2 groups) ---------
  always @(posedge clk)
  begin
    if (reset)
    begin
      stage5_min[0] <= {DATA_WIDTH{1'b1}};
      stage5_min[1] <= {DATA_WIDTH{1'b1}};
      stage5_idx[0] <= 5'd0;
      stage5_idx[1] <= 5'd0;
    end
    else
    begin
      // Compare stage4_min[0] and stage4_min[1]
      if (stage4_min[0] <= stage4_min[1])
      begin
        stage5_min[0] <= stage4_min[0];
        stage5_idx[0] <= stage4_idx[0];
      end
      else
      begin
        stage5_min[0] <= stage4_min[1];
        stage5_idx[0] <= stage4_idx[1];
      end

      // Compare stage4_min[2] and stage4_min[3]
      if (stage4_min[2] <= stage4_min[3])
      begin
        stage5_min[1] <= stage4_min[2];
        stage5_idx[1] <= stage4_idx[2];
      end
      else
      begin
        stage5_min[1] <= stage4_min[3];
        stage5_idx[1] <= stage4_idx[3];
      end
    end
  end

  // --------- 6th stage: Final comparison & valid output ---------
  reg [DATA_WIDTH-1:0] min_val_reg;
  reg [4:0]            min_idx_reg;
  reg [DATA_WIDTH-1:0] local_clock_pipe;

  always @(posedge clk)
  begin
    if (reset)
    begin
      min_val_reg      <= {DATA_WIDTH{1'b1}};
      min_idx_reg      <= 5'd0;
      local_clock_pipe <= {DATA_WIDTH{1'b1}};
    end
    else
    begin
      // Final comparison
      if (stage5_min[0] <= stage5_min[1])
      begin
        min_val_reg <= stage5_min[0];
        min_idx_reg <= stage5_idx[0];
      end
      else
      begin
        min_val_reg <= stage5_min[1];
        min_idx_reg <= stage5_idx[1];
      end
      local_clock_pipe <= local_clock;
    end
  end

  wire valid = (min_val_reg != {DATA_WIDTH{1'b1}}) && (min_val_reg <= local_clock_pipe);

  always @(posedge clk)
  begin
    if (reset)
    begin
      min_index_out      <= 5'b0;
      min_index_out_flag <= 1'b0;
    end
    else
    begin
      min_index_out      <= min_idx_reg;
      min_index_out_flag <= valid;
    end
  end

endmodule
