`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         TSN@NNS
// Engineer:        Wenxue Wu
// Create Date:     2024/8/6
// Module Name:     slave_mac_transmit_rx_tx
// Target Devices:  ZYNQ
// Tool Versions:   VIVADO 2023.2
// Description:
//////////////////////////////////////////////////////////////////////////////////

module slave_mac_transmit_rx_tx (
    input        clk_125,
    input        clk_125_90,
    input        clk_15_625,
    input        mmcm_locked,
    input        reset,
    output       core_reset,
    input  [3:0] rgmii_rxd,
    input        rgmii_rx_ctl,
    input        rgmii_rxc,
    output [3:0] rgmii_txd,
    output       rgmii_tx_ctl,
    output       rgmii_txc,
    output       mac_rx_valid,
    output [63:0] mac_rx_data,
    output [7:0] mac_rx_keep,
    output       mac_rx_last,
    input        mac_rx_ready,
    input  [63:0] mac_tx_data,
    input        mac_tx_valid,
    input  [7:0] mac_tx_keep,
    input        mac_tx_last,
    output       mac_tx_ready
);

    wire        tx_reset;
    wire        rx_reset;
    wire        glbl_rst_intn;
    wire        gtx_resetn;
    wire        s_axi_resetn;
    wire        core_reset;
    wire        rx_mac_aclk;
    wire        tx_mac_aclk;
    wire [ 7:0] rx_axis_mac_tdata;
    wire        rx_axis_mac_tvalid;
    wire        rx_axis_mac_tlast;
    wire        rx_axis_mac_tuser;
    wire [ 7:0] tx_axis_mac_tdata;
    wire        tx_axis_mac_tvalid;
    wire        tx_axis_mac_tready;
    wire        tx_axis_mac_tlast;
    wire [11:0] s_axi_awaddr;
    wire        s_axi_awvalid;
    wire        s_axi_awready;
    wire [31:0] s_axi_wdata;
    wire        s_axi_wvalid;
    wire        s_axi_wready;
    wire [ 1:0] s_axi_bresp;
    wire        s_axi_bvalid;
    wire        s_axi_bready;
    wire [11:0] s_axi_araddr;
    wire        s_axi_arvalid;
    wire        s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [ 1:0] s_axi_rresp;
    wire        s_axi_rvalid;
    wire        s_axi_rready;
    wire        m_axis_tvalid1;
    wire [63:0] m_axis_tdata1;
    wire [ 7:0] m_axis_tkeep1;
    wire        m_axis_tready1;
    wire        m_axis_tlast1;
    wire        m_axis_tvalid3;
    wire [63:0] m_axis_tdata3;
    wire [ 7:0] m_axis_tkeep3;
    wire        m_axis_tready3;
    wire        m_axis_tlast3;
    wire        mac_tx_ready;

    tri_mode_ethernet_mac_0_example_design_resets system_resets (
        .s_axi_aclk    (clk_125),
        .gtx_clk       (clk_125),
        .core_clk      (clk_15_625),
        .glbl_rst      (reset),
        .reset_error   (1'b0),
        .rx_reset      (rx_reset),
        .tx_reset      (tx_reset),
        .dcm_locked    (mmcm_locked),
        .glbl_rst_intn (glbl_rst_intn),
        .gtx_resetn    (gtx_resetn),
        .s_axi_resetn  (s_axi_resetn),
        .phy_resetn    (),
        .chk_resetn    (),
        .core_reset    (core_reset)
    );

    tri_mode_ethernet_mac_slave u_tri_mode_ethernet_mac (
        .gtx_clk              (clk_125),
        .gtx_clk90            (clk_125_90),
        .glbl_rstn            (glbl_rst_intn),
        .rx_axi_rstn          (1'b1),
        .tx_axi_rstn          (1'b1),
        .rx_statistics_vector  (),
        .rx_statistics_valid   (),
        .rx_mac_aclk          (rx_mac_aclk),
        .rx_reset             (rx_reset),
        .rx_axis_mac_tdata    (rx_axis_mac_tdata),
        .rx_axis_mac_tvalid   (rx_axis_mac_tvalid),
        .rx_axis_mac_tlast    (rx_axis_mac_tlast),
        .rx_axis_mac_tuser    (rx_axis_mac_tuser),
        .tx_ifg_delay         (8'd0),
        .tx_statistics_vector (),
        .tx_statistics_valid  (),
        .tx_mac_aclk          (tx_mac_aclk),
        .tx_reset             (tx_reset),
        .tx_axis_mac_tdata    (tx_axis_mac_tdata),
        .tx_axis_mac_tvalid   (tx_axis_mac_tvalid),
        .tx_axis_mac_tlast    (tx_axis_mac_tlast),
        .tx_axis_mac_tuser    (1'b0),
        .tx_axis_mac_tready   (tx_axis_mac_tready),
        .pause_req            (1'b0),
        .pause_val            (16'd0),
        .speedis100           (),
        .speedis10100         (),
        .rgmii_txd            (rgmii_txd),
        .rgmii_tx_ctl         (rgmii_tx_ctl),
        .rgmii_txc            (rgmii_txc),
        .rgmii_rxd            (rgmii_rxd),
        .rgmii_rx_ctl         (rgmii_rx_ctl),
        .rgmii_rxc            (rgmii_rxc),
        .inband_link_status   (),
        .inband_clock_speed   (),
        .inband_duplex_status (),
        .s_axi_aclk           (clk_125),
        .s_axi_resetn         (s_axi_resetn),
        .s_axi_awaddr         (s_axi_awaddr),
        .s_axi_awvalid        (s_axi_awvalid),
        .s_axi_awready        (s_axi_awready),
        .s_axi_wdata          (s_axi_wdata),
        .s_axi_wvalid         (s_axi_wvalid),
        .s_axi_wready         (s_axi_wready),
        .s_axi_bresp          (s_axi_bresp),
        .s_axi_bvalid         (s_axi_bvalid),
        .s_axi_bready         (s_axi_bready),
        .s_axi_araddr         (s_axi_araddr),
        .s_axi_arvalid        (s_axi_arvalid),
        .s_axi_arready        (s_axi_arready),
        .s_axi_rdata          (s_axi_rdata),
        .s_axi_rresp          (s_axi_rresp),
        .s_axi_rvalid         (s_axi_rvalid),
        .s_axi_rready         (s_axi_rready),
        .mac_irq              ()
    );

    reg error_flag;
    always @(rx_axis_mac_tlast) begin
        if (rx_axis_mac_tlast)
            error_flag = rx_axis_mac_tlast & rx_axis_mac_tuser;
    end

    axis_dwidth_converter_RX rx_axis_dwidth_converter0 (
        .aclk           (rx_mac_aclk),
        .aresetn        (gtx_resetn),
        .s_axis_tvalid  (rx_axis_mac_tvalid),
        .s_axis_tready  (),
        .s_axis_tdata   (rx_axis_mac_tdata),
        .s_axis_tkeep   (1),
        .s_axis_tlast   (rx_axis_mac_tlast),
        .m_axis_tvalid  (m_axis_tvalid3),
        .m_axis_tready  (m_axis_tready3),
        .m_axis_tdata   (m_axis_tdata3),
        .m_axis_tkeep   (m_axis_tkeep3),
        .m_axis_tlast   (m_axis_tlast3)
    );

    axis_data_fifo_rx_async rx_fifo_0 (
        .s_axis_aresetn (gtx_resetn),
        .s_axis_aclk    (rx_mac_aclk),
        .s_axis_tvalid  (m_axis_tvalid3),
        .s_axis_tready  (m_axis_tready3),
        .s_axis_tdata   (m_axis_tdata3),
        .s_axis_tkeep   (m_axis_tkeep3),
        .s_axis_tlast   (m_axis_tlast3),
        .m_axis_aclk   (clk_125),
        .m_axis_tvalid  (mac_rx_valid),
        .m_axis_tready  (mac_rx_ready),
        .m_axis_tdata   (mac_rx_data),
        .m_axis_tkeep   (mac_rx_keep),
        .m_axis_tlast   (mac_rx_last)
    );

    axis_dwidth_converter_TX tx_converter0 (
        .aclk           (tx_mac_aclk),
        .aresetn        (~core_reset),
        .s_axis_tvalid  (mac_tx_valid),
        .s_axis_tready  (mac_tx_ready),
        .s_axis_tdata   (mac_tx_data),
        .s_axis_tkeep   (mac_tx_keep),
        .s_axis_tlast   (mac_tx_last),
        .m_axis_tvalid  (m_axis_tvalid1),
        .m_axis_tready  (m_axis_tready1),
        .m_axis_tdata   (m_axis_tdata1),
        .m_axis_tkeep   (m_axis_tkeep1),
        .m_axis_tlast   (m_axis_tlast1)
    );

    axis_data_fifo_tx_inter tx_async_fifo_0 (
        .s_axis_aresetn (gtx_resetn),
        .s_axis_aclk    (tx_mac_aclk),
        .s_axis_tvalid  (m_axis_tvalid1),
        .s_axis_tready  (m_axis_tready1),
        .s_axis_tdata   (m_axis_tdata1),
        .s_axis_tkeep   (m_axis_tkeep1),
        .s_axis_tlast   (m_axis_tlast1),
        .m_axis_aclk   (tx_mac_aclk),
        .m_axis_tvalid  (tx_axis_mac_tvalid),
        .m_axis_tready  (tx_axis_mac_tready),
        .m_axis_tdata   (tx_axis_mac_tdata),
        .m_axis_tkeep   (),
        .m_axis_tlast   (tx_axis_mac_tlast)
    );

    tri_mode_ethernet_mac_0_axi_lite_sm axi_lite_controller_0 (
        .s_axi_aclk       (clk_125),
        .s_axi_resetn     (s_axi_resetn),
        .mac_speed        (2'b10),
        .update_speed     (1'b0),
        .serial_command   (1'b0),
        .serial_response  (),
        .s_axi_awaddr     (s_axi_awaddr),
        .s_axi_awvalid    (s_axi_awvalid),
        .s_axi_awready    (s_axi_awready),
        .s_axi_wdata      (s_axi_wdata),
        .s_axi_wvalid     (s_axi_wvalid),
        .s_axi_wready     (s_axi_wready),
        .s_axi_bresp      (s_axi_bresp),
        .s_axi_bvalid     (s_axi_bvalid),
        .s_axi_bready     (s_axi_bready),
        .s_axi_araddr     (s_axi_araddr),
        .s_axi_arvalid    (s_axi_arvalid),
        .s_axi_arready    (s_axi_arready),
        .s_axi_rdata      (s_axi_rdata),
        .s_axi_rresp      (s_axi_rresp),
        .s_axi_rvalid     (s_axi_rvalid),
        .s_axi_rready     (s_axi_rready)
    );

endmodule
