module group_id_simple_map(
    input  wire [3:0] dst_port,
    input  wire [3:0] src_port,
    input  wire [2:0] pri,
    output reg  [4:0] group_id
);

    always @(*) begin
        group_id = {1'b0, pri};
        if (src_port[0]) begin
            if      (dst_port[1]) group_id = {1'b0, pri} + 5'd12;
            else if (dst_port[2]) group_id = {1'b0, pri} + 5'd8;
            else if (dst_port[3]) group_id = {1'b0, pri};
        end else if (src_port[1]) begin
            if      (dst_port[0]) group_id = {1'b0, pri} + 5'd16;
            else if (dst_port[2]) group_id = {1'b0, pri} + 5'd12;
            else if (dst_port[3]) group_id = {1'b0, pri} + 5'd4;
        end else if (src_port[2]) begin
            if      (dst_port[0]) group_id = {1'b0, pri} + 5'd16;
            else if (dst_port[1]) group_id = {1'b0, pri} + 5'd8;
            else if (dst_port[3]) group_id = {1'b0, pri} + 5'd4;
        end else if (src_port[3]) begin
            if      (dst_port[0]) group_id = {1'b0, pri} + 5'd16;
            else if (dst_port[1]) group_id = {1'b0, pri} + 5'd12;
            else if (dst_port[2]) group_id = {1'b0, pri};
        end
    end

endmodule
