/*****************************************
    TB_MAC_TOP.v (Self-Checking)
    
    1. 8개의 MNT 케이스를 자동으로 순회
    2. START/DONE 핸드셰이크로 DUT 제어
    3. OUT_MEM의 결과를 Golden Vector와 자동 비교
*****************************************/

module TB_MAC_TOP;

    parameter   PERIOD = 10.0;
    parameter   HPERIOD = PERIOD/2.0;

    // DUT Inputs
    reg             CLK, RSTN;
    reg             START;
    reg     [11:0]  MNT;

    // DUT Outputs
    wire            DONE;
    wire            EN_W;
    wire    [2:0]   ADDR_W;
    wire    [63:0]  RDATA_W;
    wire            EN_I;
    wire    [2:0]   ADDR_I;
    wire    [63:0]  RDATA_I;
    wire            dut_EN_O;
    wire            dut_RW_O;
    wire    [3:0]   dut_ADDR_O;
    wire    [63:0]  dut_WDATA_O;
    wire    [63:0]  RDATA_O;
	
	// OUT_MEM 제어
    reg             tb_clear_EN_O;
    reg             tb_clear_RW_O;
    reg     [3:0]   tb_clear_ADDR_O;
    reg     [63:0]  tb_clear_WDATA_O;

    // MUX 제어
	reg         	tb_clear_mode; // 1이면 TB가, 0이면 DUT가 OUT_MEM 제어

	reg         	tb_EN_O;
    reg         	tb_RW_O;
    reg 	[3:0]   tb_ADDR_O;
    reg 	[63:0]  tb_WDATA_O;

    // --- Testbench Automation Registers ---
    reg     [11:0]  mnt_vectors   [0:7];
    reg     [63:0]  golden_mem    [0:15]; // 정답을 임시 저장할 메모리
    reg             test_failed;
    integer         i, j; 	// Loop iterators


    // DUT Instantiation
    MAC_TOP u_dut (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .MNT        (MNT),
        .START      (START),
        .DONE       (DONE),
        .EN_W       (EN_W),
        .ADDR_W     (ADDR_W),
        .RDATA_W    (RDATA_W),
        .EN_I       (EN_I),
        .ADDR_I     (ADDR_I),
        .RDATA_I    (RDATA_I),
        .EN_O       (dut_EN_O),
        .RW_O       (dut_RW_O),
        .ADDR_O     (dut_ADDR_O),
        .WDATA_O    (dut_WDATA_O),
        .RDATA_O    (RDATA_O)
    );

    // SRAM Instantiation (Testbench-side)
    SRAM    INPUT_MEM (
        .CLK        (CLK),
        .CSN        (~EN_I),
        .A          (ADDR_I),
        .WEN        (1'b1), // Read-Only
        .DI         (64'd0),
        .DOUT       (RDATA_I)
    );
    
    SRAM    WEIGHT_MEM (
        .CLK        (CLK),
        .CSN        (~EN_W),
        .A          (ADDR_W),
        .WEN        (1'b1), // Read-Only
        .DI         (64'd0),
        .DOUT       (RDATA_W)
    );

    SRAM    OUT_MEM (
        .CLK        (CLK),
        .CSN        (~tb_EN_O),
        .A          (tb_ADDR_O),
        .WEN        (~tb_RW_O), // Controlled by DUT
        .DI         (tb_WDATA_O),
        .DOUT       (RDATA_O)
    );

    // Load Input/Weight memories (딱 1번만 실행)
    defparam INPUT_MEM.MEM_FILE = "./matrix-hex/input.hex";
    defparam INPUT_MEM.WRITE = 1;
    defparam WEIGHT_MEM.MEM_FILE = "./matrix-hex/weight_transpose.hex";
    defparam WEIGHT_MEM.WRITE = 1;
    
    // OUT_MEM 파라미터 (DUT의 ADDR_O 4비트에 맞게 설정)
    defparam OUT_MEM.AW = 4;
    defparam OUT_MEM.ENTRY = 16;
    defparam OUT_MEM.WRITE = 0; // DUT가 쓸 것이므로 $readmemh 안 함

	// Mux 로직: tb_clear_mode에 따라 제어권 선택
    always @(*) begin
        tb_EN_O    = (tb_clear_mode) ? tb_clear_EN_O   : dut_EN_O;
        tb_RW_O    = (tb_clear_mode) ? tb_clear_RW_O   : dut_RW_O;
        tb_ADDR_O  = (tb_clear_mode) ? tb_clear_ADDR_O : dut_ADDR_O;
        tb_WDATA_O = (tb_clear_mode) ? tb_clear_WDATA_O : dut_WDATA_O;
    end 

	// OUT_MEM 초기화 작업 (시뮬레이션 시작 시 모든 위치를 'x'로 설정)
	task clear_out_mem;
        integer k;
        begin
            $display("[INFO] Clearing OUT_MEM to 'x'...");
            tb_clear_mode = 1'b1; // [하이재킹] TB가 제어권 획득

            for (k = 0; k < 16; k = k + 1) begin
                @(posedge CLK);
                tb_clear_EN_O   = 1'b1;     // CSN = ~tb_EN_O = 0 (Active)
                tb_clear_RW_O   = 1'b1;     // WEN = ~tb_RW_O = 0 (Write Enabled)
                tb_clear_ADDR_O = k;
                tb_clear_WDATA_O = {64{1'bx}};
            end
            @(posedge CLK);
            tb_clear_EN_O   = 1'b0;     // CSN = 1 (Deselect)
            tb_clear_RW_O   = 1'b0;
            @(posedge CLK);
            tb_clear_mode = 1'b0; // DUT에게 제어권 반환
        end
    endtask

    /// CLOCK Generator ///
    initial CLK <= 1'b0;
    always #(HPERIOD) CLK <= ~CLK;

    /// Main Test Sequence ///
    initial begin
        // 1. VCD 덤프 설정
        $dumpfile("TB_MAC_TOP.vcd");
        $dumpvars(0, TB_MAC_TOP);
        
        // 2. 테스트 케이스 벡터 초기화
        // MNT 값
        mnt_vectors[0] = 12'h444;  // stage 0
        mnt_vectors[1] = 12'h337;  // stage 1
        mnt_vectors[2] = 12'h374;  // stage 2
        mnt_vectors[3] = 12'h376;  // stage 3
        mnt_vectors[4] = 12'h634;  // stage 4
        mnt_vectors[5] = 12'h738;  // stage 5
        mnt_vectors[6] = 12'h583;  // stage 6
        mnt_vectors[7] = 12'h656;  // stage 7


        // 3. 리셋 적용
        tb_clear_mode <= 1'b0; // Mux 제어 신호 초기화
        START <= 1'b0;
        MNT   <= 1'b0;
        RSTN  <= 1'b0;
        #(10*PERIOD);
        RSTN  <= 1'b1;
        #(2*PERIOD);

        $display("------------------------------------");
        $display("[INFO] Test Sequence Started.");
        $display("------------------------------------");

        // 4. 테스트 케이스 루프 실행
        for (i = 0; i < 8; i = i + 1) begin
            $display("[RUNNING] Case %0d (MNT = %h)", i, mnt_vectors[i]);
            test_failed = 1'b0;

			clear_out_mem(); 
            #(PERIOD); // 메모리 클리어 후 1사이클 대기

            // (A) DUT에 MNT 값 설정
            MNT <= mnt_vectors[i];
            
            // (B) START 1클럭 펄스 전송
            START <= 1'b1;
            #(PERIOD);
            START <= 1'b0;

            // (C) DONE 신호 대기 (핸드셰이크)
            @(posedge u_dut.DONE);
            $display("[INFO] Case %0d: DONE received. Checking results...", i);
            
            // (D) 정답 파일 로드
			case (i)
				0: $readmemh("./matrix-hex/golden_case_0.hex", golden_mem);
				1: $readmemh("./matrix-hex/golden_case_1.hex", golden_mem);
				2: $readmemh("./matrix-hex/golden_case_2.hex", golden_mem);
				3: $readmemh("./matrix-hex/golden_case_3.hex", golden_mem);
				4: $readmemh("./matrix-hex/golden_case_4.hex", golden_mem);
				5: $readmemh("./matrix-hex/golden_case_5.hex", golden_mem);
				6: $readmemh("./matrix-hex/golden_case_6.hex", golden_mem);
				7: $readmemh("./matrix-hex/golden_case_7.hex", golden_mem);
			endcase

            // (E) 결과 비교 (OUT_MEM의 내부 RAM과 golden_mem 비교)
            for (j = 0; j < 16; j = j + 1) begin
                // `OUT_MEM.ram[j]` : 계층 경로로 SRAM 내부 메모리에 직접 접근
                if (OUT_MEM.ram[j] !== golden_mem[j]) begin
                    $error("[FAILED] Case %0d: Mismatch at ADDR_O = %0d", i, j);
                    $error("     -> DUT Result : %h", OUT_MEM.ram[j]);
                    $error("     -> Golden Data: %h", golden_mem[j]);
                    test_failed = 1'b1;
                end
            end

            if (test_failed == 1'b0) begin
                $display("[PASSED] Case %0d", i);
            end else begin
                $display("------------------------------------");
                $display("[INFO] Simulation stopped due to failure.");
                $display("------------------------------------");
                $finish(2); // 오류 발생 시 시뮬레이션 즉시 종료
            end
            
            #(2*PERIOD); // 다음 케이스 시작 전 잠시 대기
        end

        $display("------------------------------------");
        $display("[SUCCESS] All 8 test cases passed!");
        $display("------------------------------------");
        $finish;
    end

endmodule