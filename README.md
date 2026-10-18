# 8086 Assembly Language Programs

A collection of low-level assembly language programs developed for the 8086/8088 architecture, focusing on memory addressing, bitwise operations, string manipulation, and screen routines.

---

##  Author Details
* **Name:** M. Sameer Akram
* **Roll Number:** 25L-0540

---

##  Project Overview & Description
This repository contains various x86 assembly programs written and tested using NASM and executed in a DOSBox environment. Key topics and implementations covered include:
* **Arithmetic & Bitwise Operations:** Shift-and-add multiplication routines using `rcl` and `shl`.
* **String Manipulation:** Efficient memory scanning and copying using instructions like `movsw`.
* **Video Memory & Screen Handling:** Direct screen scrolling and buffer manipulation routines.

---

##  Tools Used
* **NASM (Netwide Assembler):** Used to compile the assembly source code into flat binary/executable (`.com`) formats.
* **DOSBox:** Used as the 16-bit x86 emulation environment to run and debug programs.
* **AFD (Advanced Full-Screen Debugger):** Used for register and memory tracing during execution.

---

##  How to Assemble and Run

Follow these steps to assemble your code using NASM and execute it inside DOSBox:

### Step 1: Install Tools
Make sure you have both **NASM** and **DOSBox** installed on your system.

---

### Step 2: Assemble the Source Code (Compilation)
1. Place your assembly file (e.g., `program.asm`) and `nasm.exe` in the same working directory (or ensure NASM is in your System Path).
2. Open **Command Prompt / Terminal** in your project folder.
3. Run the following command to assemble `.asm` into a `.com` executable:

  First, launch the DOSBox application on your machine.

Next, you need to map your local project directory as a virtual drive inside DOSBox. Use the mount command followed by c and your local folder path:
mount c C:\path\to\your\project_folder

Once mounted, switch your current workspace drive to drive C by entering:
c:

Finally, type the name of your compiled executable file to launch and run the assembly program:
program.com
