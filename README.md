\# RISC-V ISA Extension: Control-Flow Integrity (CFI) Monitor



A hardware-based, 3-state Finite State Machine (FSM) implemented in SystemVerilog designed to mitigate control-flow hijacking attacks (such as ROP/JOP) by validating branch targets against pre-recorded landing pads in real-time.



\## Overview

This hardware component monitors a 32-bit instruction/execution packet stream every clock cycle. It ensures that any speculative or runtime execution jump (`JUMP`) lands strictly on an authorized landing pad (`LPAD`) containing a matching security token (`label`). If a mismatch or out-of-order sequence occurs, the FSM instantly triggers an un-escapable error state to halt or alert the processor pipeline.



\### Architectural Specification

\- \*\*Packet Format:\*\* 32-bit width split into:

&#x20; - `pkt\[31:24]`: Command Opcode (8 bits)

&#x20; - `pkt\[23:0]`: Data Payload / Label Token (24 bits)

\- \*\*Supported Opcodes:\*\*

&#x20; - `SET`  (`0x01`): Stores the data payload into an internal target label register.

&#x20; - `JUMP` (`0x02`): Puts the FSM on alert, transitioning to target validation mode.

&#x20; - `LPAD` (`0x03`): Transmits the landing pad label to be checked against the stored token.



\---



\## Finite State Machine (FSM) State Diagram



The FSM restricts transitions based on the following deterministic rules:



```text

&#x20;      +================================================+



&#x20;      |                                                |

&#x20;      v                                                |

&#x20;  +-------+      on CMD\_SET (Store Data)               |



&#x20;  |       | -------------------------------+           |

&#x20;  | IDLE  |                                |           |

&#x20;  | (00)  | <------------------------------+           |

&#x20;  +-------+                                            |



&#x20;      |                                                |

&#x20;      | on CMD\_JUMP                                    |

&#x20;      v                                                |

&#x20;  +-------+      on CMD\_LPAD \&\& (Data == Label)        |



&#x20;  | CHECK | -------------------------------------------+

&#x20;  | (01)  |

&#x20;  +-------+

&#x20;      |

&#x20;      | Any Other Condition (Violation)

&#x20;      v

&#x20;  +-------+



&#x20;  | ERROR | <--- (Sticky State: Permanently Trapped)

&#x20;  | (10)  | ---+

&#x20;  +-------+    |

&#x20;      ^        |

&#x20;      +--------+

```



1\. \*\*`IDLE` (00):\*\* Waits for commands. `SET` caches the expected tracking label. `JUMP` transitions the FSM to `CHECK`.

2\. \*\*`CHECK` (01):\*\* Validates the immediately succeeding cycle. Must receive an `LPAD` opcode with a data field matching the cached label to safely bounce back to `IDLE`. Any other scenario triggers a security violation.

3\. \*\*`ERROR` (10):\*\* A sticky lockdown state. Once a security bypass is detected, the monitor asserts the error flag continuously and cannot be cleared by software.



\---



\## Code Architecture



The design is split cleanly using SystemVerilog structures:

\*   \*\*Strict Typing:\*\* Utilizes `typedef enum` for safe state encoding.

\*   \*\*Edge-Triggered Isolation:\*\* Strictly decouples combinational next-state decoding (`always\_comb`) from the sequential state registers (`always\_ff`).



\### Core Design Elements

\*   \*\*File:\*\* `rtl/module\_cfi.sv` — Main hardware monitoring block.

\*   \*\*File:\*\* `tb/tb\_module\_cfi.sv` — Comprehensive stimulus file validating both nominal execution and malicious instruction injections.



\---



\## Verification \& Simulation Results



The design was simulated using \*\*Xilinx Vivado Simulator\*\*. The testbench executes two critical functional vectors:



\### Test Case 1: Nominal Valid Path Success

1\. \*\*`SET` Label:\*\* Caches `0xABCDEF` into the internal tracking register.

2\. \*\*`JUMP` Dispatched:\*\* Moves the FSM from `IDLE` to `CHECK`.

3\. \*\*Valid `LPAD` Landing:\*\* On the very next cycle, an `LPAD` arrives carrying `0xABCDEF`. The FSM safely returns to `IDLE`. `error\_o` remains low (`0`).



\### Test Case 2: Security Violation Interception

1\. \*\*`JUMP` Dispatched:\*\* Moves FSM from `IDLE` to `CHECK`.

2\. \*\*Malicious / Incorrect Landing:\*\* The stream presents a mismatched label payload (`0x111111`). 

3\. \*\*Hardware Lockdown:\*\* The FSM immediately moves to `ERROR` and raises `error\_o` to `1`. Subsequent valid landing pads are rejected, confirming the sticky lockdown security feature works as designed.



\*(Optional: Place your Vivado Waveform Screenshot here)\*

<!-- !\[Vivado Simulation Waveform](sim/waveform\_screenshot.png) -->



\---



\## How to Run in Xilinx Vivado



1\. Clone this repository:

&#x20;  ```bash

&#x20;  git clone https://github.com

&#x20;  ```

2\. Open Xilinx Vivado and create an \*\*RTL Project\*\*.

3\. Add `rtl/module\_cfi.sv` as a \*\*Design Source\*\* (Ensure file type is set to \*\*SystemVerilog\*\*).

4\. Add `tb/tb\_module\_cfi.sv` as a \*\*Simulation Source\*\*.

5\. Click \*\*Run Simulation\*\* -> \*\*Run Behavioral Simulation\*\* in the Flow Navigator panel.



