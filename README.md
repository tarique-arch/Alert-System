# VGA-Based Alert system

## Project Overview
A VHDL-based fire safety system that displays fire/flood alerts on VGA monitor and controls LED patterns via UART commands. 


### Hardware Setup
- Connect **VGA cable** to monitor
- Connect **USB-UART cable** (CP2102) to computer
- Power on **DE10-Lite FPGA board**

### Software Setup
1. Open **Tera Term** → Serial → Baud Rate: **9600**
2. Load project in **Intel Quartus Prime**
3. Program the FPGA

## Available Commands
| Command | Action |
|---------|--------|
| `A` | Explosion LED Pattern |
| `B` | Alternating LED Pattern |
| `C` | Snake LED Pattern |
| `D` | Sparkle LED Pattern |
| `F` | VGA Fire Alert |
| `f` | VGA Flood Alert |

*Type command + ENTER to execute.*
Only the last typed character before Enter is considered. Previous command resets automatically.



## 📁 Project Files
- `TOP.vhd` - Main controller
- `vga_timing.vhd` - VGA display timing
- `uart_rx.vhd` - Serial communication
- `text_buffer.vhd` - Character memory
- `fire.vhd`, `flood.vhd` - Alert images
- `fire_alarm.vhd` - LED animations
- `clk.vhd` - Clock management

---

## Team
**Group 7** - EE232 Course Project
