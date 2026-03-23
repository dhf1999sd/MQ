module comparator #(
    parameter DATA_WIDTH = 59
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire [DATA_WIDTH-1:0]  in_data_0,
    input  wire [DATA_WIDTH-1:0]  in_data_1,
    input  wire [DATA_WIDTH-1:0]  in_data_2,
    input  wire [DATA_WIDTH-1:0]  local_clock,
    output reg  [1:0]             min_index_out,
    output reg                    min_index_out_flag
);

    reg [DATA_WIDTH-1:0] min_val_reg;
    reg [1:0]            min_idx_reg;
    reg [DATA_WIDTH-1:0] local_clock_pipe;

    wire valid = (min_val_reg != {DATA_WIDTH{1'b1}}) && (min_val_reg <= local_clock_pipe);

    always @(posedge clk) begin
        if (reset) begin
            min_val_reg      <= {DATA_WIDTH{1'b1}};
            min_idx_reg      <= 2'd0;
            local_clock_pipe <= {DATA_WIDTH{1'b1}};
        end else begin
            if (in_data_0 <= in_data_1 && in_data_0 <= in_data_2) begin
                min_val_reg <= in_data_0;
                min_idx_reg <= 2'd0;
            end else if (in_data_1 <= in_data_0 && in_data_1 <= in_data_2) begin
                min_val_reg <= in_data_1;
                min_idx_reg <= 2'd1;
            end else begin
                min_val_reg <= in_data_2;
                min_idx_reg <= 2'd2;
            end
            local_clock_pipe <= local_clock;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            min_index_out      <= 2'b0;
            min_index_out_flag <= 1'b0;
        end else begin
            min_index_out      <= min_idx_reg;
            min_index_out_flag <= valid;
        end
    end

endmodule
