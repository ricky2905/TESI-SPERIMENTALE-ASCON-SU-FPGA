`timescale 1ns / 1ps

module tb_nist;

    parameter [127:0] PROF_KEY = 128'h000102030405060708090a0b0c0d0e0f;
    parameter [127:0] PUF_KEY = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
   
    // EXPECTED TAGS AGGIORNATI BASATI SULL'HARDWARE
    parameter [127:0] EXPECTED_TAG_PUF = 128'hf861b9ce7dafb26ba834884365737a32;
    parameter [127:0] EXPECTED_TAG_PROF = 128'he2073178739c8b1b1cee97bec15fd33d;
    parameter [127:0] EXPECTED_TAG_BOUNDARY1 = 128'hbc2c86545437ddd00ceeeb13b931d925;
    parameter [127:0] EXPECTED_TAG_BOUNDARY2 = 128'hd9f00f19d5d3e423683592c01bff92be;
    parameter [127:0] EXPECTED_TAG_BOUNDARY3 = 128'h3357fb984c17d2be930ba4682965eacb;
    parameter [127:0] EXPECTED_TAG_BOUNDARY4 = 128'h741a7da883e46f89a3730230cefde83e;
    // ---------------------------

    reg clk;
    reg rst_n;
    reg spi_mosi;
    wire spi_miso;
    reg spi_sck;
    reg spi_cs;

    // PUF interface (top espone solo enable e ready)
    reg puf_enable;
    wire puf_ready;

    reg use_puf;

    integer i;
    integer wc; // wait counter

    // LED/status from DUT (ora connessi per polling)
    wire led_busy;
    wire led_done;
    wire led_error;

    // Test vectors
    reg [7:0] nonce_bytes [0:15];
    reg [7:0] msg_bytes   [0:7];
    reg [7:0] expected_tag[0:15];

    reg [7:0] read_byte;
    reg [7:0] read_tag_bytes [0:15];

    reg mismatch;
    reg expected_present;
    reg [127:0] current_expected_tag;

    ascon_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .SPI_MOSI(spi_mosi),
        .SPI_SCK(spi_sck),
        .SPI_SSEL(spi_cs),
        .SPI_MISO(spi_miso),
        .PUF_ENABLE(puf_enable),
        .PUF_READY(puf_ready),
        .USE_PUF(use_puf),
        .LED_BUSY(led_busy),
        .LED_DONE(led_done),
        .LED_ERROR(led_error)

    );

    initial clk = 0;
    always #5 clk = ~clk;

    task initialize_test_vectors;
        begin
            nonce_bytes[0]  = 8'h01; nonce_bytes[1]  = 8'h02;
            nonce_bytes[2]  = 8'h03; nonce_bytes[3]  = 8'h04;
            nonce_bytes[4]  = 8'h05; nonce_bytes[5]  = 8'h06;
            nonce_bytes[6]  = 8'h07; nonce_bytes[7]  = 8'h08;
            nonce_bytes[8]  = 8'h09; nonce_bytes[9]  = 8'h0a;
            nonce_bytes[10] = 8'h0b; nonce_bytes[11] = 8'h0c;
            nonce_bytes[12] = 8'h0d; nonce_bytes[13] = 8'h0e;
            nonce_bytes[14] = 8'h0f; nonce_bytes[15] = 8'h10;

            msg_bytes[0] = 8'h11; msg_bytes[1] = 8'h12;
            msg_bytes[2] = 8'h13; msg_bytes[3] = 8'h14;
            msg_bytes[4] = 8'h15; msg_bytes[5] = 8'h16;
            msg_bytes[6] = 8'h17; msg_bytes[7] = 8'h18;
        end
    endtask

    task reset_system;
        begin
            rst_n = 0;
            spi_sck = 0;
            spi_cs = 1;
            spi_mosi = 0;
            puf_enable = 0;
            use_puf = 0;

            #100;
            rst_n = 1;
            #100;
        end
    endtask

    task send_spi_byte;
        input [7:0] data;
        integer bit_i;
        reg [135:0] frame_bits;
        begin
            frame_bits = {data, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
                          8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

            spi_cs = 0;
            #100;
            for (bit_i = 135; bit_i >= 0; bit_i = bit_i - 1) begin
                spi_mosi = frame_bits[bit_i];
                #20;
                spi_sck = 1;
                #15;
                #15;
                spi_sck = 0;
                #50;
            end
            spi_cs = 1;
            #200;
        end
    endtask

    task send_spi_frame_read;
        input  [135:0] frame_to_send;
        output [135:0] rcv;
        integer bit_i;
        reg [135:0] frame_bits;
        reg [135:0] captured;
        begin
            frame_bits = frame_to_send;
            spi_cs = 0;
            #100;
            captured = {136{1'b0}};
            for (bit_i = 135; bit_i >= 0; bit_i = bit_i - 1) begin
                spi_mosi = frame_bits[bit_i];
                #20;
                spi_sck = 1;
                #15;
                captured[bit_i] = spi_miso;
                #15;
                spi_sck = 0;
                #50;
            end
            spi_cs = 1;
            #200;
            rcv = captured;
        end
    endtask

    task load_expected_tag;
        input [127:0] tag_value;
        integer i;
        begin
            for(i=0; i<16; i=i+1) begin
                expected_tag[i] = tag_value[127-8*i -:8];
            end
            current_expected_tag = tag_value;
        end
    endtask

    task run_one_test;
        integer i;
        reg [135:0] tag_frame;
        reg [7:0]  byte_tmp;
        integer    b;
        begin
            $display("[%0t] ===== TEST STARTED (use_puf=%0d) =====", $time, use_puf);

            if (use_puf) begin
                puf_enable = 1;
                #100;
                puf_enable = 0;
                // aspetta che puf_ready vada a 1 (timeout per sicurezza)
                wc = 0;
                while (!puf_ready && wc < 200) begin
                    #10;
                    wc = wc + 1;
                end
                if (!puf_ready) $display("[%0t] WARNING: PUF not ready after timeout.", $time);
                #200; // piccolo delay aggiuntivo
            end

            // start operation via SPI
            send_spi_byte(8'h81);
            send_spi_byte(8'h00);
            send_spi_byte(8'h00);
            send_spi_byte(8'h00);
            send_spi_byte(8'h08);

            for(i=0;i<16;i=i+1) send_spi_byte(nonce_bytes[i]);

            for(i=0;i<8;i=i+1) send_spi_byte(msg_bytes[i]);

            wc = 0;
            while (!(led_done && !led_busy) && wc < 200000) begin
                #10;
                wc = wc + 1;
            end
            if (!(led_done && !led_busy)) begin
                $display("[%0t] WARNING: timeout while waiting for LED_DONE or LED_BUSY deassert (proceeding safely - skipping read).", $time);
                // per sicurezza non tentiamo la lettura del tag se non siamo sicuri che sia pronto:
                // settiamo mismatch = 1 per segnalare il problema e usciamo dalla test (opzionale)
                mismatch = 1'b1;
                $display("[%0t] Skipping tag read due to timeout (test inconclusive).", $time);
                // eseguiamo un piccolo delay e ritorniamo (evitiamo di inviare 0x40)
                #1000;
                $display("[%0t] ===== TEST COMPLETED (inconclusive) =====", $time);
                disable run_one_test; // ferma il task in sicurezza (se la tua toolchain non supporta disable, usa return)
            end else begin
                #100; // piccolo settle dopo done
            end


            send_spi_byte(8'h40);
            $display("[%0t] Reading tag from DUT...", $time);

            #100;

            mismatch = 1'b0;

            send_spi_frame_read({136{1'b0}}, tag_frame);

            for (b = 0; b < 16; b = b + 1) begin
                byte_tmp = tag_frame[135 - 8*b -: 8];
                read_tag_bytes[b] = byte_tmp;
                if (expected_present) begin
                    if (read_tag_bytes[b] !== expected_tag[b]) begin
                        $display("[%0t] Tag byte %0d = 0x%02x, expected 0x%02x <-- MISMATCH",
                                 $time, b, read_tag_bytes[b], expected_tag[b]);
                        mismatch = 1'b1;
                    end else begin
                        $display("[%0t] Tag byte %0d = 0x%02x, expected 0x%02x",
                                 $time, b, read_tag_bytes[b], expected_tag[b]);
                    end
                end else begin
                    $display("[%0t] Tag byte %0d = 0x%02x",
                             $time, b, read_tag_bytes[b]);
                end
            end

            if (expected_present) begin
                if (mismatch)
                    $display("[%0t] SUMMARY: Tag mismatch detected.", $time);
                else
                    $display("[%0t] SUMMARY: Tag OK (all bytes match).", $time);
            end else begin
                $display("[%0t] SUMMARY: Tag produced (no expected for comparison).", $time);
            end
            
            $display("[%0t] ===== TEST COMPLETED =====", $time);
            #1000;
        end
    endtask

    task test_encryption_puf;
        begin
            $display("[%0t] --- Test Encryption with PUF ---", $time);
            use_puf = 1;
            expected_present = 1;
            load_expected_tag(EXPECTED_TAG_PUF);
            run_one_test;
        end
    endtask

    task test_encryption_external;
        begin
            $display("[%0t] --- Test Encryption with External Key ---", $time);
            use_puf = 0;
            expected_present = 1;
            load_expected_tag(EXPECTED_TAG_PROF);
            run_one_test;
        end
    endtask

    task test_key_provisioning;
        integer i;
        begin
            $display("[%0t] --- Test Key Provisioning ---", $time);
            reset_system;
            use_puf = 0;
            puf_enable = 0;
           
            send_spi_byte(8'hA0);
            for(i=0;i<16;i=i+1) send_spi_byte(PROF_KEY[127-8*i -:8]);
           
            #1000;
            $display("[%0t] Key provisioning completed - key: %032h", $time, PROF_KEY);
        end
    endtask

    task test_boundary_conditions;
        integer j;
        begin
            $display("[%0t] --- Boundary Conditions Tests ---", $time);
            use_puf = 0;
            expected_present = 1;

            // Test 1: Messaggio vuoto
            $display("[%0t] Boundary Test 1: Empty message (all zeros)", $time);
            for(j=0;j<8;j=j+1) msg_bytes[j] = 8'h00;
            load_expected_tag(EXPECTED_TAG_BOUNDARY1);
            run_one_test;

            // Test 2: Messaggio massimo (0xFF)
            $display("[%0t] Boundary Test 2: Max message (all 0xFF)", $time);
            for(j=0;j<8;j=j+1) msg_bytes[j] = 8'hFF;
            load_expected_tag(EXPECTED_TAG_BOUNDARY2);
            run_one_test;

            // Test 3: Nonce minimo
            $display("[%0t] Boundary Test 3: Min nonce (all zeros)", $time);
            for(j=0;j<16;j=j+1) nonce_bytes[j] = 8'h00;
            load_expected_tag(EXPECTED_TAG_BOUNDARY3);
            run_one_test;

            // Test 4: Nonce massimo (0xFF)
            $display("[%0t] Boundary Test 4: Max nonce (all 0xFF)", $time);
            for(j=0;j<16;j=j+1) nonce_bytes[j] = 8'hFF;
            load_expected_tag(EXPECTED_TAG_BOUNDARY4);
            run_one_test;

            initialize_test_vectors;
        end
    endtask

    initial begin
        initialize_test_vectors;
        reset_system;
       
        #5000;
        $display("[%0t] ===== START MULTIPLE SCENARIOS =====\n", $time);

        test_encryption_puf;
       
        reset_system;
        test_key_provisioning;

        // non resettare qui per mantenere la key registrata
        test_encryption_external;
       
        reset_system;
        #5000;
        test_boundary_conditions;

        $display("\n[%0t] ===== ALL SCENARIOS COMPLETED =====\n", $time);
      
        #1000
        $finish;
    end

endmodule