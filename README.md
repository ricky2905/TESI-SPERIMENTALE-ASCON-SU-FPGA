🇮🇹 ASCON su FPGA — Tesi sperimentale
Questo progetto realizza e verifica in Vivado un’implementazione di ASCON-128 su FPGA Cmod35.  
L’architettura include il core crittografico, la permutazione interna, un controller SPI, un blocco di clock management e una logica di selezione della chiave tra chiave esterna e PUF emulata/simulata.
La parte PUF è presente nel progetto ma solo simulata/emulata, non implementata come PUF fisica su scheda.
I risultati sperimentali riportati in questa tesi sono ottenuti in Vivado, tramite simulazione funzionale e report di implementazione, non su scheda fisica effettiva.
---
📁 Struttura del progetto
```text
TESI_BACKUP/
├── dichiarazione_conseguimento_diploma.pdf
├── piano di studio.pdf
├── PRESENTAZIONE/
│   ├── presentazione.pdf
│   └── presentazione.ppt
├── PROGETTO_VIVADO_TESI/
│   └── ASCONTESISPERIMENTALE/
│       ├── ASCONTESISPERIMENTALE.xpr
│       ├── ASCONTESISPERIMENTALE.srcs/
│       │   ├── sources_1/new/
│       │   │   ├── ascon_top.v
│       │   │   ├── ascon_controller.v
│       │   │   ├── ascon_core.v
│       │   │   ├── ascon_logic.v
│       │   │   ├── ascon_perm.v
│       │   │   ├── puf_controller.v
│       │   │   └── SPI.v
│       │   ├── constrs_1/new/
│       │   │   └── constraints.xdc
│       │   └── sim_1/new/
│       │       └── tb_nist.v
│       ├── .cache/
│       ├── .gen/
│       ├── .runs/
│       ├── .sim/
│       └── .hw/
└── TESI/
    └── backup latex/
        ├── Introduzione.tex
        ├── Materiali_e_metodi.tex
        ├── Implementazione_della_soluzione.tex
        ├── Ottimizzazione_della_componente_hardware.tex
        ├── Risultati_sperimentali.tex
        ├── Conclusione_e_realizzazioni.tex
        └── ...
```
---
🧰 Requisiti di sistema
```text
Vivado 2024.2
Verilog HDL
FPGA Cmod35
Git (opzionale)
```
---
⚙️ Cosa implementa il progetto
Il design è organizzato in moduli separati:
`ascon_top.v`: top-level, integra clock, SPI, controller, core e selezione chiave
`ascon_controller.v`: FSM di controllo, parsing comandi SPI, provisioning chiave, avvio operazioni
`ascon_core.v`: datapath AEAD con gestione di AD, MSG, OUT e tag
`ascon_perm.v`: permutazione ASCON con round constants e stadi combinatori/registrati
`ascon_logic.v`: selezione tra PUF emulata e chiave esterna, reset sincronizzato e LED di stato
`puf_controller.v`: PUF emulata/simulata
`SPI.v`: interfaccia seriale SPI
`constraints.xdc`: assegnazione pin e clock
`tb_nist.v`: testbench di validazione
---
🔬 Analisi e ottimizzazione
Durante l’analisi del progetto è emerso che la funzione di permutazione rappresentava il principale collo di bottiglia: il suo tempo di elaborazione rallentava l’intero flusso crittografico.
Per questo motivo è stata introdotta una soluzione pipelined, con l’obiettivo di:
ridurre la latenza percepita del blocco di permutazione
migliorare il bilanciamento del datapath
aumentare la frequenza massima ottenibile
rendere più stabile il comportamento del core durante la simulazione e il flusso di implementazione
Questa ottimizzazione è uno degli aspetti centrali della tesi.
---
🧪 Validazione funzionale
La validazione è stata svolta con il testbench:
```text
tb_nist.v
```
Il testbench verifica:
cifratura con PUF simulata
provisioning di chiave esterna
test su boundary conditions
confronto tra tag atteso e tag ottenuto
La simulazione conferma che il tag prodotto dal core coincide con quello atteso in tutti gli scenari testati.
---
📦 Setup del progetto in Vivado
1) Apri il progetto
Apri il file:
```text
ASCONTESISPERIMENTALE.xpr
```
2) Verifica il target FPGA
Controlla che il part sia impostato correttamente per la scheda Cmod35 usata nel progetto.
3) Esegui la simulazione
Avvia la simulazione funzionale sul testbench:
```text
tb_nist
```
4) Esegui sintesi e implementazione
Nel flusso Vivado l’ordine consigliato è:
```text
Synthesis → Implementation → Report
```
5) Controlla i report
Verifica:
```text
Utilization
Timing
Power
```
---
🔐 Gestione della chiave
Il progetto supporta due sorgenti di chiave:
chiave esterna caricata via SPI
chiave da PUF emulata/simulata
La selezione avviene tramite la logica di controllo nel modulo `ascon_logic.v`.
La chiave esterna usata nei test è:
```text
000102030405060708090a0b0c0d0e0f
```
---
🧠 PUF
La PUF presente in questo lavoro è emulata:
genera una risposta deterministica a partire dal challenge
serve per validare il flusso di controllo e la selezione chiave
non rappresenta una PUF fisica implementata su scheda
Questa scelta è coerente con la parte sperimentale della tesi e con l’obiettivo di validare l’architettura in Vivado.
---
📈 Risultati sperimentali su Vivado
I risultati seguenti sono ottenuti in Vivado, non su scheda fisica.
Output della simulazione
```text
run all
[5200000] ===== START MULTIPLE SCENARIOS =====

[5200000] --- Test Encryption with PUF ---
[5200000] ===== TEST STARTED (use_puf=1) =====
[19175000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[19175000] Controller: Received CMD 0x81 (start op)
[74775000] Controller: Message length =     8 bytes
[297175000] Controller: Nonce loaded, starting processing
[311170000] ASCON Core: Tag produced = f861b9ce7dafb26ba834884365737a32
[408375000] Controller: All message data sent
[408380000] Controller: Processing done
[422375000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[422375000] Controller: RD TAG cmd received, done_seen=1, done=1
[422375000] Controller: Preparing tag frame to send, tag_out=f861b9ce7dafb26ba834884365737a32
[422600000] Reading tag from DUT...
[436370000] Controller: Tag frame transmitted, asserting tag_ack
[436375000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[436600000] Tag byte 0 = 0xf8, expected 0xf8
[436600000] Tag byte 1 = 0x61, expected 0x61
[436600000] Tag byte 2 = 0xb9, expected 0xb9
[436600000] Tag byte 3 = 0xce, expected 0xce
[436600000] Tag byte 4 = 0x7d, expected 0x7d
[436600000] Tag byte 5 = 0xaf, expected 0xaf
[436600000] Tag byte 6 = 0xb2, expected 0xb2
[436600000] Tag byte 7 = 0x6b, expected 0x6b
[436600000] Tag byte 8 = 0xa8, expected 0xa8
[436600000] Tag byte 9 = 0x34, expected 0x34
[436600000] Tag byte 10 = 0x88, expected 0x88
[436600000] Tag byte 11 = 0x43, expected 0x43
[436600000] Tag byte 12 = 0x65, expected 0x65
[436600000] Tag byte 13 = 0x73, expected 0x73
[436600000] Tag byte 14 = 0x7a, expected 0x7a
[436600000] Tag byte 15 = 0x32, expected 0x32
[436600000] SUMMARY: Tag OK (all bytes match).
[436600000] ===== TEST COMPLETED =====
[437800000] --- Test Key Provisioning ---
Warning: [Unisim MMCME2_ADV-20] Input CLKIN1 period and attribute CLKIN1_PERIOD are not same. Instance tb_nist.uut.pll_inst.inst.mmcm_adv_inst 
[452575000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=0)
[479475000] Controller: SPI RXED byte = 0x01 (done_seen=0, done=0)
[493375000] Controller: SPI RXED byte = 0x02 (done_seen=0, done=0)
[507275000] Controller: SPI RXED byte = 0x03 (done_seen=0, done=0)
[521175000] Controller: SPI RXED byte = 0x04 (done_seen=0, done=0)
[535075000] Controller: SPI RXED byte = 0x05 (done_seen=0, done=0)
[548975000] Controller: SPI RXED byte = 0x06 (done_seen=0, done=0)
[562875000] Controller: SPI RXED byte = 0x07 (done_seen=0, done=0)
[576775000] Controller: SPI RXED byte = 0x08 (done_seen=0, done=0)
[590675000] Controller: SPI RXED byte = 0x09 (done_seen=0, done=0)
[604575000] Controller: SPI RXED byte = 0x0a (done_seen=0, done=0)
[618475000] Controller: SPI RXED byte = 0x0b (done_seen=0, done=0)
[632375000] Controller: SPI RXED byte = 0x0c (done_seen=0, done=0)
[646275000] Controller: SPI RXED byte = 0x0d (done_seen=0, done=0)
[660175000] Controller: SPI RXED byte = 0x0e (done_seen=0, done=0)
[674075000] Controller: SPI RXED byte = 0x0f (done_seen=0, done=0)
[675300000] Key provisioning completed - key: 000102030405060708090a0b0c0d0e0f
[675300000] --- Test Encryption with External Key ---
[675300000] ===== TEST STARTED (use_puf=0) =====
[688975000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[688975000] Controller: Received CMD 0x81 (start op)
[744575000] Controller: Message length =     8 bytes
[966975000] Controller: Nonce loaded, starting processing
[980970000] ASCON Core: Tag produced = e2073178739c8b1b1cee97bec15fd33d
[1078175000] Controller: All message data sent
[1078180000] Controller: Processing done
[1092175000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1092175000] Controller: RD TAG cmd received, done_seen=1, done=1
[1092175000] Controller: Preparing tag frame to send, tag_out=e2073178739c8b1b1cee97bec15fd33d
[1092400000] Reading tag from DUT...
[1106170000] Controller: Tag frame transmitted, asserting tag_ack
[1106175000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1106400000] Tag byte 0 = 0xe2, expected 0xe2
[1106400000] Tag byte 1 = 0x07, expected 0x07
[1106400000] Tag byte 2 = 0x31, expected 0x31
[1106400000] Tag byte 3 = 0x78, expected 0x78
[1106400000] Tag byte 4 = 0x73, expected 0x73
[1106400000] Tag byte 5 = 0x9c, expected 0x9c
[1106400000] Tag byte 6 = 0x8b, expected 0x8b
[1106400000] Tag byte 7 = 0x1b, expected 0x1b
[1106400000] Tag byte 8 = 0x1c, expected 0x1c
[1106400000] Tag byte 9 = 0xee, expected 0xee
[1106400000] Tag byte 10 = 0x97, expected 0x97
[1106400000] Tag byte 11 = 0xbe, expected 0xbe
[1106400000] Tag byte 12 = 0xc1, expected 0xc1
[1106400000] Tag byte 13 = 0x5f, expected 0x5f
[1106400000] Tag byte 14 = 0xd3, expected 0xd3
[1106400000] Tag byte 15 = 0x3d, expected 0x3d
[1106400000] SUMMARY: Tag OK (all bytes match).
[1106400000] ===== TEST COMPLETED =====
Warning: [Unisim MMCME2_ADV-20] Input CLKIN1 period and attribute CLKIN1_PERIOD are not same. Instance tb_nist.uut.pll_inst.inst.mmcm_adv_inst
[1112600000] --- Boundary Conditions Tests ---
[1112600000] Boundary Test 1: Empty message (all zeros)
[1112600000] ===== TEST STARTED (use_puf=0) =====
[1126275000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[1126275000] Controller: Received CMD 0x81 (start op)
[1181875000] Controller: Message length =     8 bytes
[1404275000] Controller: Nonce loaded, starting processing
[1418270000] ASCON Core: Tag produced = bc2c86545437ddd00ceeeb13b931d925
[1515475000] Controller: All message data sent
[1515480000] Controller: Processing done
[1529475000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1529475000] Controller: RD TAG cmd received, done_seen=1, done=1
[1529475000] Controller: Preparing tag frame to send, tag_out=bc2c86545437ddd00ceeeb13b931d925
[1529700000] Reading tag from DUT...
[1543470000] Controller: Tag frame transmitted, asserting tag_ack
[1543475000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1543700000] Tag byte 0 = 0xbc, expected 0xbc
[1543700000] Tag byte 1 = 0x2c, expected 0x2c
[1543700000] Tag byte 2 = 0x86, expected 0x86
[1543700000] Tag byte 3 = 0x54, expected 0x54
[1543700000] Tag byte 4 = 0x54, expected 0x54
[1543700000] Tag byte 5 = 0x37, expected 0x37
[1543700000] Tag byte 6 = 0xdd, expected 0xdd
[1543700000] Tag byte 7 = 0xd0, expected 0xd0
[1543700000] Tag byte 8 = 0x0c, expected 0x0c
[1543700000] Tag byte 9 = 0xee, expected 0xee
[1543700000] Tag byte 10 = 0xeb, expected 0xeb
[1543700000] Tag byte 11 = 0x13, expected 0x13
[1543700000] Tag byte 12 = 0xb9, expected 0xb9
[1543700000] Tag byte 13 = 0x31, expected 0x31
[1543700000] Tag byte 14 = 0xd9, expected 0xd9
[1543700000] Tag byte 15 = 0x25, expected 0x25
[1543700000] SUMMARY: Tag OK (all bytes match).
[1543700000] ===== TEST COMPLETED =====
[1544700000] Boundary Test 2: Max message (all 0xFF)
[1544700000] ===== TEST STARTED (use_puf=0) =====
[1558375000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[1558375000] Controller: Received CMD 0x81 (start op)
[1613975000] Controller: Message length =     8 bytes
[1836375000] Controller: Nonce loaded, starting processing
[1836865000] ASCON Core: Tag produced = d9f00f19d5d3e423683592c01bff92be
[1947575000] Controller: All message data sent
[1947580000] Controller: Processing done
[1961575000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1961575000] Controller: RD TAG cmd received, done_seen=1, done=1
[1961575000] Controller: Preparing tag frame to send, tag_out=d9f00f19d5d3e423683592c01bff92be
[1961800000] Reading tag from DUT...
[1975570000] Controller: Tag frame transmitted, asserting tag_ack
[1975575000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1975800000] Tag byte 0 = 0xd9, expected 0xd9
[1975800000] Tag byte 1 = 0xf0, expected 0xf0
[1975800000] Tag byte 2 = 0x0f, expected 0x0f
[1975800000] Tag byte 3 = 0x19, expected 0x19
[1975800000] Tag byte 4 = 0xd5, expected 0xd5
[1975800000] Tag byte 5 = 0xd3, expected 0xd3
[1975800000] Tag byte 6 = 0xe4, expected 0xe4
[1975800000] Tag byte 7 = 0x23, expected 0x23
[1975800000] Tag byte 8 = 0x68, expected 0x68
[1975800000] Tag byte 9 = 0x35, expected 0x35
[1975800000] Tag byte 10 = 0x92, expected 0x92
[1975800000] Tag byte 11 = 0xc0, expected 0xc0
[1975800000] Tag byte 12 = 0x1b, expected 0x1b
[1975800000] Tag byte 13 = 0xff, expected 0xff
[1975800000] Tag byte 14 = 0x92, expected 0x92
[1975800000] Tag byte 15 = 0xbe, expected 0xbe
[1975800000] SUMMARY: Tag OK (all bytes match).
[1975800000] ===== TEST COMPLETED =====
[1976800000] Boundary Test 3: Min nonce (all zeros)
[1976800000] ===== TEST STARTED (use_puf=0) =====
[1990475000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[1990475000] Controller: Received CMD 0x81 (start op)
[2046075000] Controller: Message length =     8 bytes
[2268475000] Controller: Nonce loaded, starting processing
[2269100000] ASCON Core: Tag produced = 3357fb984c17d2be930ba4682965eacb
[2379675000] Controller: All message data sent
[2379680000] Controller: Processing done
[2393675000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[2393675000] Controller: RD TAG cmd received, done_seen=1, done=1
[2393675000] Controller: Preparing tag frame to send, tag_out=3357fb984c17d2be930ba4682965eacb
[2393900000] Reading tag from DUT...
[2407670000] Controller: Tag frame transmitted, asserting tag_ack
[2407675000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[2407900000] Tag byte 0 = 0x33, expected 0x33
[2407900000] Tag byte 1 = 0x57, expected 0x57
[2407900000] Tag byte 2 = 0xfb, expected 0xfb
[2407900000] Tag byte 3 = 0x98, expected 0x98
[2407900000] Tag byte 4 = 0x4c, expected 0x4c
[2407900000] Tag byte 5 = 0x17, expected 0x17
[2407900000] Tag byte 6 = 0xd2, expected 0xd2
[2407900000] Tag byte 7 = 0xbe, expected 0xbe
[2407900000] Tag byte 8 = 0x93, expected 0x93
[2407900000] Tag byte 9 = 0x0b, expected 0x0b
[2407900000] Tag byte 10 = 0xa4, expected 0xa4
[2407900000] Tag byte 11 = 0x68, expected 0x68
[2407900000] Tag byte 12 = 0x29, expected 0x29
[2407900000] Tag byte 13 = 0x65, expected 0x65
[2407900000] Tag byte 14 = 0xea, expected 0xea
[2407900000] Tag byte 15 = 0xcb, expected 0xcb
[2407900000] SUMMARY: Tag OK (all bytes match).
[2407900000] ===== TEST COMPLETED =====
[2408900000] Boundary Test 4: Max nonce (all 0xFF)
[2408900000] ===== TEST STARTED (use_puf=0) =====
[2422575000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[2422575000] Controller: Received CMD 0x81 (start op)
[2478175000] Controller: Message length =     8 bytes
[2700575000] Controller: Nonce loaded, starting processing
[2701200000] ASCON Core: Tag produced = 741a7da883e46f89a3730230cefde83e
[2811775000] Controller: All message data sent
[2811780000] Controller: Processing done
[2825775000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[2825775000] Controller: RD TAG cmd received, done_seen=1, done=1
[2825775000] Controller: Preparing tag frame to send, tag_out=741a7da883e46f89a3730230cefde83e
[2826000000] Reading tag from DUT...
[2839770000] Controller: Tag frame transmitted, asserting tag_ack
[2839775000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[2840000000] Tag byte 0 = 0x74, expected 0x74
[2840000000] Tag byte 1 = 0x1a, expected 0x1a
[2840000000] Tag byte 2 = 0x7d, expected 0x7d
[2840000000] Tag byte 3 = 0xa8, expected 0xa8
[2840000000] Tag byte 4 = 0x83, expected 0x83
[2840000000] Tag byte 5 = 0xe4, expected 0xe4
[2840000000] Tag byte 6 = 0x6f, expected 0x6f
[2840000000] Tag byte 7 = 0x89, expected 0x89
[2840000000] Tag byte 8 = 0xa3, expected 0xa3
[2840000000] Tag byte 9 = 0x73, expected 0x73
[2840000000] Tag byte 10 = 0x02, expected 0x02
[2840000000] Tag byte 11 = 0x30, expected 0x30
[2840000000] Tag byte 12 = 0xce, expected 0xce
[2840000000] Tag byte 13 = 0xfd, expected 0xfd
[2840000000] Tag byte 14 = 0xe8, expected 0xe8
[2840000000] Tag byte 15 = 0x3e, expected 0x3e
[2840000000] SUMMARY: Tag OK (all bytes match).
[2840000000] ===== TEST COMPLETED =====

[2841000000] ===== ALL SCENARIOS COMPLETED =====

$finish called at time : 2842 us : File "E:/backup/TESI_BACKUP/PROGETTO_VIVADO_TESI/ASCONTESISPERIMENTALE.srcs/sim_1/new/tb_nist.v" Line 351
run: Time (s): cpu = 00:00:05 ; elapsed = 00:00:21 . Memory (MB): peak = 1812.586 ; gain = 0.000
```
Osservazioni sui risultati
```text
* Tutti gli scenari terminano con "SUMMARY: Tag OK (all bytes match)"
* La logica PUF funziona nella versione simulata
* La provisioning della chiave esterna è corretta
* I test boundary passano con successo
* Il progetto è validato in simulazione Vivado, non su scheda fisica
```
---
✅ Funzionalità
```text
* Core ASCON-128 modulare
* Interfaccia SPI per provisioning e lettura tag
* Logica di selezione chiave tra PUF emulata e chiave esterna
* Ottimizzazione della permutazione tramite pipeline
* Validazione funzionale con testbench dedicato
* Risultati verificati in Vivado
```
---
🧹 Pulizia ambiente
Per rimuovere i file generati da Vivado, puoi eliminare:
```text
.cache/
.gen/
.runs/
.sim/
.hw/
```
Se vuoi ripartire da zero, conserva solo:
```text
srcs/
constraints.xdc
tb_nist.v
ASCONTESISPERIMENTALE.xpr
```
---
🇬🇧 ASCON on FPGA — Experimental Thesis Project
This project implements and verifies ASCON-128 in Vivado on an FPGA Cmod35.  
The architecture includes the cryptographic core, the internal permutation, an SPI controller, clock management, and key-selection logic between an external key and a simulated/emulated PUF.
The PUF part is included in the project but only simulated/emulated, not implemented as a physical PUF on the board.
The experimental results reported in this thesis are obtained in Vivado, through functional simulation and implementation reports, not on a real hardware board.
---
📁 Project Structure
```text
TESI_BACKUP/
├── dichiarazione_conseguimento_diploma.pdf
├── piano di studio.pdf
├── PRESENTAZIONE/
│   ├── presentazione.pdf
│   └── presentazione.ppt
├── PROGETTO_VIVADO_TESI/
│   └── ASCONTESISPERIMENTALE/
│       ├── ASCONTESISPERIMENTALE.xpr
│       ├── ASCONTESISPERIMENTALE.srcs/
│       │   ├── sources_1/new/
│       │   │   ├── ascon_top.v
│       │   │   ├── ascon_controller.v
│       │   │   ├── ascon_core.v
│       │   │   ├── ascon_logic.v
│       │   │   ├── ascon_perm.v
│       │   │   ├── puf_controller.v
│       │   │   └── SPI.v
│       │   ├── constrs_1/new/
│       │   │   └── constraints.xdc
│       │   └── sim_1/new/
│       │       └── tb_nist.v
│       ├── .cache/
│       ├── .gen/
│       ├── .runs/
│       ├── .sim/
│       └── .hw/
└── TESI/
    └── backup latex/
        ├── Introduzione.tex
        ├── Materiali_e_metodi.tex
        ├── Implementazione_della_soluzione.tex
        ├── Ottimizzazione_della_componente_hardware.tex
        ├── Risultati_sperimentali.tex
        ├── Conclusione_e_realizzazioni.tex
        └── ...
```
---
🧰 System Requirements
```text
Vivado 2024.2
Verilog HDL
Cmod35 FPGA
Git (optional)
```
---
⚙️ What the project implements
The design is split into dedicated modules:
`ascon_top.v`: top-level integration of clock, SPI, controller, core, and key selection logic
`ascon_controller.v`: FSM controller, SPI command parsing, key provisioning, operation start
`ascon_core.v`: AEAD datapath with handling for AD, MSG, OUT, and tag
`ascon_perm.v`: ASCON permutation with round constants and combinational/registered stages
`ascon_logic.v`: key selection between simulated PUF and external key, synchronized reset, and status LEDs
`puf_controller.v`: simulated/emulated PUF
`SPI.v`: SPI serial interface
`constraints.xdc`: pin and clock assignments
`tb_nist.v`: validation testbench
---
🔬 Analysis and optimization
During the analysis of the project, it became clear that the permutation function was the main bottleneck: it slowed down the entire cryptographic flow.
For this reason, a pipelined solution was introduced to:
reduce permutation latency
improve datapath balancing
increase the achievable maximum frequency
make the core behavior more stable during simulation and implementation
This optimization is one of the central contributions of the thesis.
---
🧪 Functional Validation
Validation was performed with the testbench:
```text
tb_nist.v
```
The testbench checks:
encryption with the simulated PUF
external key provisioning
boundary conditions
comparison between expected and actual tags
Simulation confirms that the tag produced by the core matches the expected tag in all tested scenarios.
---
📦 Vivado Project Setup
1) Open the project
Open:
```text
ASCONTESISPERIMENTALE.xpr
```
2) Verify the FPGA target
Check that the part is configured for the Cmod35 board used in the project.
3) Run simulation
Launch functional simulation on:
```text
tb_nist
```
4) Run synthesis and implementation
Recommended flow:
```text
Synthesis → Implementation → Report
```
5) Inspect reports
Check:
```text
Utilization
Timing
Power
```
---
🔐 Key Management
The project supports two key sources:
external key loaded through SPI
PUF-based key from the simulated/emulated PUF
The selection is handled by the control logic in `ascon_logic.v`.
The external key used in the tests is:
```text
000102030405060708090a0b0c0d0e0f
```
---
🧠 PUF
The PUF used in this work is emulated:
it generates a deterministic response from the challenge
it is used to validate control flow and key selection
it is not a physical PUF implemented on the board
This choice fits the experimental scope of the thesis and the goal of validating the architecture in Vivado.
---
📈 Experimental Results on Vivado
The following results were obtained in Vivado, not on a physical board.
Simulation output
```text
run all
[5200000] ===== START MULTIPLE SCENARIOS =====

[5200000] --- Test Encryption with PUF ---
[5200000] ===== TEST STARTED (use_puf=1) =====
[19175000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[19175000] Controller: Received CMD 0x81 (start op)
[74775000] Controller: Message length =     8 bytes
[297175000] Controller: Nonce loaded, starting processing
[311170000] ASCON Core: Tag produced = f861b9ce7dafb26ba834884365737a32
[408375000] Controller: All message data sent
[408380000] Controller: Processing done
[422375000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[422375000] Controller: RD TAG cmd received, done_seen=1, done=1
[422375000] Controller: Preparing tag frame to send, tag_out=f861b9ce7dafb26ba834884365737a32
[422600000] Reading tag from DUT...
[436370000] Controller: Tag frame transmitted, asserting tag_ack
[436375000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[436600000] Tag byte 0 = 0xf8, expected 0xf8
[436600000] Tag byte 1 = 0x61, expected 0x61
[436600000] Tag byte 2 = 0xb9, expected 0xb9
[436600000] Tag byte 3 = 0xce, expected 0xce
[436600000] Tag byte 4 = 0x7d, expected 0x7d
[436600000] Tag byte 5 = 0xaf, expected 0xaf
[436600000] Tag byte 6 = 0xb2, expected 0xb2
[436600000] Tag byte 7 = 0x6b, expected 0x6b
[436600000] Tag byte 8 = 0xa8, expected 0xa8
[436600000] Tag byte 9 = 0x34, expected 0x34
[436600000] Tag byte 10 = 0x88, expected 0x88
[436600000] Tag byte 11 = 0x43, expected 0x43
[436600000] Tag byte 12 = 0x65, expected 0x65
[436600000] Tag byte 13 = 0x73, expected 0x73
[436600000] Tag byte 14 = 0x7a, expected 0x7a
[436600000] Tag byte 15 = 0x32, expected 0x32
[436600000] SUMMARY: Tag OK (all bytes match).
[436600000] ===== TEST COMPLETED =====
[437800000] --- Test Key Provisioning ---
Warning: [Unisim MMCME2_ADV-20] Input CLKIN1 period and attribute CLKIN1_PERIOD are not same. Instance tb_nist.uut.pll_inst.inst.mmcm_adv_inst 
[452575000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=0)
[479475000] Controller: SPI RXED byte = 0x01 (done_seen=0, done=0)
[493375000] Controller: SPI RXED byte = 0x02 (done_seen=0, done=0)
[507275000] Controller: SPI RXED byte = 0x03 (done_seen=0, done=0)
[521175000] Controller: SPI RXED byte = 0x04 (done_seen=0, done=0)
[535075000] Controller: SPI RXED byte = 0x05 (done_seen=0, done=0)
[548975000] Controller: SPI RXED byte = 0x06 (done_seen=0, done=0)
[562875000] Controller: SPI RXED byte = 0x07 (done_seen=0, done=0)
[576775000] Controller: SPI RXED byte = 0x08 (done_seen=0, done=0)
[590675000] Controller: SPI RXED byte = 0x09 (done_seen=0, done=0)
[604575000] Controller: SPI RXED byte = 0x0a (done_seen=0, done=0)
[618475000] Controller: SPI RXED byte = 0x0b (done_seen=0, done=0)
[632375000] Controller: SPI RXED byte = 0x0c (done_seen=0, done=0)
[646275000] Controller: SPI RXED byte = 0x0d (done_seen=0, done=0)
[660175000] Controller: SPI RXED byte = 0x0e (done_seen=0, done=0)
[674075000] Controller: SPI RXED byte = 0x0f (done_seen=0, done=0)
[675300000] Key provisioning completed - key: 000102030405060708090a0b0c0d0e0f
[675300000] --- Test Encryption with External Key ---
[675300000] ===== TEST STARTED (use_puf=0) =====
[688975000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[688975000] Controller: Received CMD 0x81 (start op)
[744575000] Controller: Message length =     8 bytes
[966975000] Controller: Nonce loaded, starting processing
[980970000] ASCON Core: Tag produced = e2073178739c8b1b1cee97bec15fd33d
[1078175000] Controller: All message data sent
[1078180000] Controller: Processing done
[1092175000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1092175000] Controller: RD TAG cmd received, done_seen=1, done=1
[1092175000] Controller: Preparing tag frame to send, tag_out=e2073178739c8b1b1cee97bec15fd33d
[1092400000] Reading tag from DUT...
[1106170000] Controller: Tag frame transmitted, asserting tag_ack
[1106175000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1106400000] Tag byte 0 = 0xe2, expected 0xe2
[1106400000] Tag byte 1 = 0x07, expected 0x07
[1106400000] Tag byte 2 = 0x31, expected 0x31
[1106400000] Tag byte 3 = 0x78, expected 0x78
[1106400000] Tag byte 4 = 0x73, expected 0x73
[1106400000] Tag byte 5 = 0x9c, expected 0x9c
[1106400000] Tag byte 6 = 0x8b, expected 0x8b
[1106400000] Tag byte 7 = 0x1b, expected 0x1b
[1106400000] Tag byte 8 = 0x1c, expected 0x1c
[1106400000] Tag byte 9 = 0xee, expected 0xee
[1106400000] Tag byte 10 = 0x97, expected 0x97
[1106400000] Tag byte 11 = 0xbe, expected 0xbe
[1106400000] Tag byte 12 = 0xc1, expected 0xc1
[1106400000] Tag byte 13 = 0x5f, expected 0x5f
[1106400000] Tag byte 14 = 0xd3, expected 0xd3
[1106400000] Tag byte 15 = 0x3d, expected 0x3d
[1106400000] SUMMARY: Tag OK (all bytes match).
[1106400000] ===== TEST COMPLETED =====
Warning: [Unisim MMCME2_ADV-20] Input CLKIN1 period and attribute CLKIN1_PERIOD are not same. Instance tb_nist.uut.pll_inst.inst.mmcm_adv_inst
[1112600000] --- Boundary Conditions Tests ---
[1112600000] Boundary Test 1: Empty message (all zeros)
[1112600000] ===== TEST STARTED (use_puf=0) =====
[1126275000] Controller: SPI RXED byte = 0x81 (done_seen=0, done=0)
[1126275000] Controller: Received CMD 0x81 (start op)
[1181875000] Controller: Message length =     8 bytes
[1404275000] Controller: Nonce loaded, starting processing
[1418270000] ASCON Core: Tag produced = bc2c86545437ddd00ceeeb13b931d925
[1515475000] Controller: All message data sent
[1515480000] Controller: Processing done
[1529475000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1529475000] Controller: RD TAG cmd received, done_seen=1, done=1
[1529475000] Controller: Preparing tag frame to send, tag_out=bc2c86545437ddd00ceeeb13b931d925
[1529700000] Reading tag from DUT...
[1543470000] Controller: Tag frame transmitted, asserting tag_ack
[1543475000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1543700000] Tag byte 0 = 0xbc, expected 0xbc
[1543700000] Tag byte 1 = 0x2c, expected 0x2c
[1543700000] Tag byte 2 = 0x86, expected 0x86
[1543700000] Tag byte 3 = 0x54, expected 0x54
[1543700000] Tag byte 4 = 0x54, expected 0x54
[1543700000] Tag byte 5 = 0x37, expected 0x37
[1543700000] Tag byte 6 = 0xdd, expected 0xdd
[1543700000] Tag byte 7 = 0xd0, expected 0xd0
[1543700000] Tag byte 8 = 0x0c, expected 0x0c
[1543700000] Tag byte 9 = 0xee, expected 0xee
[1543700000] Tag byte 10 = 0xeb, expected 0xeb
[1543700000] Tag byte 11 = 0x13, expected 0x13
[1543700000] Tag byte 12 = 0xb9, expected 0xb9
[1543700000] Tag byte 13 = 0x31, expected 0x31
[1543700000] Tag byte 14 = 0xd9, expected 0xd9
[1543700000] Tag byte 15 = 0x25, expected 0x25
[1543700000] SUMMARY: Tag OK (all bytes match).
[1543700000] ===== TEST COMPLETED =====
[1544700000] Boundary Test 2: Max message (all 0xFF)
[1544700000] ===== TEST STARTED (use_puf=0) =====
[1558375000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[1558375000] Controller: Received CMD 0x81 (start op)
[1613975000] Controller: Message length =     8 bytes
[1836375000] Controller: Nonce loaded, starting processing
[1836865000] ASCON Core: Tag produced = d9f00f19d5d3e423683592c01bff92be
[1947575000] Controller: All message data sent
[1947580000] Controller: Processing done
[1961575000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[1961575000] Controller: RD TAG cmd received, done_seen=1, done=1
[1961575000] Controller: Preparing tag frame to send, tag_out=d9f00f19d5d3e423683592c01bff92be
[1961800000] Reading tag from DUT...
[1975570000] Controller: Tag frame transmitted, asserting tag_ack
[1975575000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[1975800000] Tag byte 0 = 0xd9, expected 0xd9
[1975800000] Tag byte 1 = 0xf0, expected 0xf0
[1975800000] Tag byte 2 = 0x0f, expected 0x0f
[1975800000] Tag byte 3 = 0x19, expected 0x19
[1975800000] Tag byte 4 = 0xd5, expected 0xd5
[1975800000] Tag byte 5 = 0xd3, expected 0xd3
[1975800000] Tag byte 6 = 0xe4, expected 0xe4
[1975800000] Tag byte 7 = 0x23, expected 0x23
[1975800000] Tag byte 8 = 0x68, expected 0x68
[1975800000] Tag byte 9 = 0x35, expected 0x35
[1975800000] Tag byte 10 = 0x92, expected 0x92
[1975800000] Tag byte 11 = 0xc0, expected 0xc0
[1975800000] Tag byte 12 = 0x1b, expected 0x1b
[1975800000] Tag byte 13 = 0xff, expected 0xff
[1975800000] Tag byte 14 = 0x92, expected 0x92
[1975800000] Tag byte 15 = 0xbe, expected 0xbe
[1975800000] SUMMARY: Tag OK (all bytes match).
[1975800000] ===== TEST COMPLETED =====
[1976800000] Boundary Test 3: Min nonce (all zeros)
[1976800000] ===== TEST STARTED (use_puf=0) =====
[1990475000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[1990475000] Controller: Received CMD 0x81 (start op)
[2046075000] Controller: Message length =     8 bytes
[2268475000] Controller: Nonce loaded, starting processing
[2269100000] ASCON Core: Tag produced = 3357fb984c17d2be930ba4682965eacb
[2379675000] Controller: All message data sent
[2379680000] Controller: Processing done
[2393675000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[2393675000] Controller: RD TAG cmd received, done_seen=1, done=1
[2393675000] Controller: Preparing tag frame to send, tag_out=3357fb984c17d2be930ba4682965eacb
[2393900000] Reading tag from DUT...
[2407670000] Controller: Tag frame transmitted, asserting tag_ack
[2407675000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[2407900000] Tag byte 0 = 0x33, expected 0x33
[2407900000] Tag byte 1 = 0x57, expected 0x57
[2407900000] Tag byte 2 = 0xfb, expected 0xfb
[2407900000] Tag byte 3 = 0x98, expected 0x98
[2407900000] Tag byte 4 = 0x4c, expected 0x4c
[2407900000] Tag byte 5 = 0x17, expected 0x17
[2407900000] Tag byte 6 = 0xd2, expected 0xd2
[2407900000] Tag byte 7 = 0xbe, expected 0xbe
[2407900000] Tag byte 8 = 0x93, expected 0x93
[2407900000] Tag byte 9 = 0x0b, expected 0x0b
[2407900000] Tag byte 10 = 0xa4, expected 0xa4
[2407900000] Tag byte 11 = 0x68, expected 0x68
[2407900000] Tag byte 12 = 0x29, expected 0x29
[2407900000] Tag byte 13 = 0x65, expected 0x65
[2407900000] Tag byte 14 = 0xea, expected 0xea
[2407900000] Tag byte 15 = 0xcb, expected 0xcb
[2407900000] SUMMARY: Tag OK (all bytes match).
[2407900000] ===== TEST COMPLETED =====
[2408900000] Boundary Test 4: Max nonce (all 0xFF)
[2408900000] ===== TEST STARTED (use_puf=0) =====
[2422575000] Controller: SPI RXED byte = 0x81 (done_seen=1, done=0)
[2422575000] Controller: Received CMD 0x81 (start op)
[2478175000] Controller: Message length =     8 bytes
[2700575000] Controller: Nonce loaded, starting processing
[2701200000] ASCON Core: Tag produced = 741a7da883e46f89a3730230cefde83e
[2811775000] Controller: All message data sent
[2811780000] Controller: Processing done
[2825775000] Controller: SPI RXED byte = 0x40 (done_seen=1, done=1)
[2825775000] Controller: RD TAG cmd received, done_seen=1, done=1
[2825775000] Controller: Preparing tag frame to send, tag_out=741a7da883e46f89a3730230cefde83e
[2826000000] Reading tag from DUT...
[2839770000] Controller: Tag frame transmitted, asserting tag_ack
[2839775000] Controller: SPI RXED byte = 0x00 (done_seen=0, done=1)
[2840000000] Tag byte 0 = 0x74, expected 0x74
[2840000000] Tag byte 1 = 0x1a, expected 0x1a
[2840000000] Tag byte 2 = 0x7d, expected 0x7d
[2840000000] Tag byte 3 = 0xa8, expected 0xa8
[2840000000] Tag byte 4 = 0x83, expected 0x83
[2840000000] Tag byte 5 = 0xe4, expected 0xe4
[2840000000] Tag byte 6 = 0x6f, expected 0x6f
[2840000000] Tag byte 7 = 0x89, expected 0x89
[2840000000] Tag byte 8 = 0xa3, expected 0xa3
[2840000000] Tag byte 9 = 0x73, expected 0x73
[2840000000] Tag byte 10 = 0x02, expected 0x02
[2840000000] Tag byte 11 = 0x30, expected 0x30
[2840000000] Tag byte 12 = 0xce, expected 0xce
[2840000000] Tag byte 13 = 0xfd, expected 0xfd
[2840000000] Tag byte 14 = 0xe8, expected 0xe8
[2840000000] Tag byte 15 = 0x3e, expected 0x3e
[2840000000] SUMMARY: Tag OK (all bytes match).
[2840000000] ===== TEST COMPLETED =====

[2841000000] ===== ALL SCENARIOS COMPLETED =====

$finish called at time : 2842 us : File "E:/backup/TESI_BACKUP/PROGETTO_VIVADO_TESI/ASCONTESISPERIMENTALE.srcs/sim_1/new/tb_nist.v" Line 351
run: Time (s): cpu = 00:00:05 ; elapsed = 00:00:21 . Memory (MB): peak = 1812.586 ; gain = 0.000
```
Osservazioni sui risultati
```text
* Tutti gli scenari terminano con "SUMMARY: Tag OK (all bytes match)"
* La logica PUF funziona nella versione simulata
* La provisioning della chiave esterna è corretta
* I test boundary passano con successo
* Il progetto è validato in simulazione Vivado, non su scheda fisica
```
---
✅ Features
```text
* Modular ASCON-128 core
* SPI interface for provisioning and tag reading
* Key selection between simulated PUF and external key
* Permutation optimized with a pipeline
* Functional validation with a dedicated testbench
* Results verified in Vivado
```
---
🧹 Cleanup environment
To remove Vivado-generated files, delete:
```text
.cache/
.gen/
.runs/
.sim/
.hw/
```
If you want to start from scratch, keep only:
```text
srcs/
constraints.xdc
tb_nist.v
ASCONTESISPERIMENTALE.xpr
```
