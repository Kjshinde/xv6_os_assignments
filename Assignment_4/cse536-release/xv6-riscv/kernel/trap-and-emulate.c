#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "stdbool.h"    // Include stdbool.h for bool type
#include "stdlib.h"     // Include stdlib.h for malloc

// -------------------- Define Macros --------------------

// Macros for VM modes
#define VM_MODE_RESTRICTED 0            // (RISC - V) User Mode 
#define VM_MODE_UNRESTRICTED 1          // (RISC - V) Supervisor Mode
#define VM_MODE_FULLY_UNRESTRICTED 2    // (RISC - V) Machine Mode


// -------------------- Define Structs --------------------

// Structure representing a virtual machine register
typedef struct vm_reg {
    int     csr;   // CSR (Control and Status Register) 
    int     mode;   // Privilege level required to access this register (restricted/unrestricted/fully_unrestricted)
    uint64  val;    // Actual value stored in the register (64-bit unsigned integer)
} vm_register;

// Structure to keep the virtual state of the VM's privileged registers
typedef struct vm_virtual_state {
    // User trap setup registers
    vm_register user_status;                        // User mode status register, controls user-level privileges
    vm_register user_interrupt_enable;              // Controls which interrupts are enabled in user mode
    vm_register user_trap_vector;                   // Contains address of user-mode trap handler

    // User trap handling registers
    vm_register user_scratch;                       // Temporary storage for user trap handler
    vm_register user_exception_pc;                  // Holds PC value when trap occurs in user mode
    vm_register user_trap_cause;                    // Indicates cause of user-mode trap
    vm_register user_trap_value;                    // Additional information about user trap
    vm_register user_interrupt_pending;             // Shows which interrupts are pending in user mode

    // Supervisor trap setup registers
    vm_register supervisor_status;                  // Supervisor mode status register, controls privileges
    vm_register supervisor_exception_delegation;    // Controls which exceptions are delegated to supervisor
    vm_register supervisor_interrupt_delegation;    // Controls which interrupts are delegated to supervisor
    vm_register supervisor_interrupt_enable;        // Controls enabled supervisor-level interrupts
    vm_register supervisor_trap_vector;             // Contains address of supervisor trap handler
    vm_register supervisor_counter_enable;          // Controls which counters are accessible to lower modes

    // Supervisor trap handling registers
    vm_register supervisor_scratch;                 // Temporary storage for supervisor trap handler
    vm_register supervisor_exception_pc;            // Holds PC value when trap occurs in supervisor mode
    vm_register supervisor_trap_cause;              // Indicates cause of supervisor-mode trap
    vm_register supervisor_trap_value;              // Additional information about supervisor trap
    vm_register supervisor_interrupt_pending;       // Shows which interrupts are pending in supervisor mode

    // Supervisor page table register
    vm_register supervisor_address_translation;     // Controls page table configuration and virtual memory

    // Machine information registers
    vm_register machine_vendor_id;                  // Identifies the vendor of the RISC-V implementation
    vm_register machine_architecture_id;            // Identifies the microarchitecture
    vm_register machine_implementation_id;          // Provides implementation-specific version number
    vm_register machine_hardware_thread_id;         // Identifies the hardware thread running the csr

    // Machine trap setup registers
    vm_register machine_status;                   // Machine mode status register, highest privilege control
    vm_register machine_isa;                      // Identifies supported instructions and extensions
    vm_register machine_exception_delegation;     // Controls exception delegation to lower modes
    vm_register machine_interrupt_delegation;     // Controls interrupt delegation to lower modes
    vm_register machine_interrupt_enable;         // Controls enabled machine-level interrupts
    vm_register machine_trap_vector;              // Contains address of machine trap handler
    vm_register machine_counter_enable;           // Controls counter access for lower privilege modes

    // Machine trap handling registers
    vm_register machine_scratch;                  // Temporary storage for machine trap handler
    vm_register machine_exception_pc;             // Holds PC value when trap occurs in machine mode
    vm_register machine_trap_cause;               // Indicates cause of machine-mode trap
    vm_register machine_trap_value;               // Additional information about machine trap
    vm_register machine_interrupt_pending;        // Shows which interrupts are pending in machine mode

    // Define the mode of the VM
    int mode;

    // Add page table field
    pagetable_t vm_ptable;  // Virtual machine's page table

    // TO DO: Add machine physical memory protection registers and check if VM is setup for full memory protection

    // TO DO: Add the VM's page table registers
} vm_virtual_state;

// Structure to hold decoded instruction information
typedef struct decoded_inst {
    uint64 addr;     // instruction address
    uint32 inst;     // raw instruction
    uint32 op;       // opcode
    uint32 rd;       // destination register
    uint32 rs1;      // source register 1
    uint32 rs2;      // source register 2
    uint32 funct3;   // funct3 field
    uint32 uimm;     // upper immediate
} decoded_inst;

// -------------------- Define Global Variables --------------------
vm_virtual_state vm_state; // Create a global VM state

// -------------------- Function Prototypes --------------------
void init_all_vm_registers(void);
void handle_ecall(struct proc *p);
void handle_sret(struct proc *p);
void handle_mret(struct proc *p);
void handle_csrw(decoded_inst *decoded, struct proc *p);
void handle_csrr(decoded_inst *decoded, struct proc *p);
void write_csr(uint32 csr_address, uint32 value);
uint32 read_csr(uint32 csr_address);
void sret_handler(struct proc *p);

// -------------------- Function Definitions --------------------

// Function to initialize all the VM's registers to 0
void init_all_vm_registers(void) {

    // user trap setup registers
    vm_state.user_status.csr = 0x0000;
    vm_state.user_status.mode = VM_MODE_RESTRICTED;
    vm_state.user_status.val = 0x00000000;

    vm_state.user_interrupt_enable.csr = 0x0004;
    vm_state.user_interrupt_enable.mode = VM_MODE_RESTRICTED;
    vm_state.user_interrupt_enable.val = 0x00000000;

    vm_state.user_trap_vector.csr = 0x0005;
    vm_state.user_trap_vector.mode = VM_MODE_RESTRICTED;
    vm_state.user_trap_vector.val = 0x00000000;

    // user trap handling registers
    vm_state.user_scratch.csr = 0x0040;
    vm_state.user_scratch.mode = VM_MODE_RESTRICTED;
    vm_state.user_scratch.val = 0x00000000;

    vm_state.user_exception_pc.csr = 0x0041;
    vm_state.user_exception_pc.mode = VM_MODE_RESTRICTED;
    vm_state.user_exception_pc.val = 0x00000000;

    vm_state.user_trap_cause.csr = 0x0042;
    vm_state.user_trap_cause.mode = VM_MODE_RESTRICTED;
    vm_state.user_trap_cause.val = 0x00000000;

    vm_state.user_trap_value.csr = 0x0043;
    vm_state.user_trap_value.mode = VM_MODE_RESTRICTED;
    vm_state.user_trap_value.val = 0x00000000;

    vm_state.user_interrupt_pending.csr = 0x0044;
    vm_state.user_interrupt_pending.mode = VM_MODE_RESTRICTED;
    vm_state.user_interrupt_pending.val = 0x00000000;

    // supervisor trap setup registers
    vm_state.supervisor_status.csr = 0x0100;
    vm_state.supervisor_status.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_status.val = 0x00000000;

    vm_state.supervisor_exception_delegation.csr = 0x0102;
    vm_state.supervisor_exception_delegation.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_exception_delegation.val = 0x00000000    ;

    vm_state.supervisor_interrupt_delegation.csr = 0x0103;
    vm_state.supervisor_interrupt_delegation.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_interrupt_delegation.val = 0x00000000   ;

    vm_state.supervisor_interrupt_enable.csr = 0x0104;
    vm_state.supervisor_interrupt_enable.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_interrupt_enable.val = 0x00000000   ;

    vm_state.supervisor_trap_vector.csr = 0x0105;
    vm_state.supervisor_trap_vector.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_trap_vector.val = 0x00000000;

    vm_state.supervisor_counter_enable.csr = 0x0106;
    vm_state.supervisor_counter_enable.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_counter_enable.val = 0x00000000;

    // supervisor trap handling registers
    vm_state.supervisor_scratch.csr = 0x0140;
    vm_state.supervisor_scratch.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_scratch.val = 0x00000000;

    vm_state.supervisor_exception_pc.csr = 0x0141;
    vm_state.supervisor_exception_pc.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_exception_pc.val = 0x00000000;

    vm_state.supervisor_trap_cause.csr = 0x0142;
    vm_state.supervisor_trap_cause.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_trap_cause.val = 0x00000000;

    vm_state.supervisor_trap_value.csr = 0x0143;
    vm_state.supervisor_trap_value.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_trap_value.val = 0x00000000;

    vm_state.supervisor_interrupt_pending.csr = 0x0144;
    vm_state.supervisor_interrupt_pending.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_interrupt_pending.val = 0x00000000;

    // supervisor page table register
    vm_state.supervisor_address_translation.csr = 0x0180;
    vm_state.supervisor_address_translation.mode = VM_MODE_UNRESTRICTED;
    vm_state.supervisor_address_translation.val = 0x00000000;

    // machine information registers
    vm_state.machine_vendor_id.csr = 0x0f11;
    vm_state.machine_vendor_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_vendor_id.val = 0x637365353336;          // equals to CSE536 in hexadecimal

    vm_state.machine_architecture_id.csr = 0x0f12;
    vm_state.machine_architecture_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_architecture_id.val = 0x00000000;

    vm_state.machine_implementation_id.csr = 0x0f13;
    vm_state.machine_implementation_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_implementation_id.val = 0x00000000;

    vm_state.machine_hardware_thread_id.csr = 0x0f14;
    vm_state.machine_hardware_thread_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_hardware_thread_id.val = 0x00000000;

    // machine trap setup registers
    vm_state.machine_status.csr = 0x0300;
    vm_state.machine_status.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_status.val = 0x00000000;

    vm_state.machine_isa.csr = 0x0301;
    vm_state.machine_isa.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_isa.val = 0x00000000;

    vm_state.machine_exception_delegation.csr = 0x0302;
    vm_state.machine_exception_delegation.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_exception_delegation.val = 0x00000000;

    vm_state.machine_interrupt_delegation.csr = 0x0303;
    vm_state.machine_interrupt_delegation.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_interrupt_delegation.val = 0x00000000;

    vm_state.machine_interrupt_enable.csr = 0x0304;
    vm_state.machine_interrupt_enable.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_interrupt_enable.val = 0x00000000;

    vm_state.machine_trap_vector.csr = 0x0305;
    vm_state.machine_trap_vector.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_trap_vector.val = 0x00000000;

    vm_state.machine_counter_enable.csr = 0x0306;
    vm_state.machine_counter_enable.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_counter_enable.val = 0x00000000;

    // machine trap handling registers
    vm_state.machine_scratch.csr = 0x0340;
    vm_state.machine_scratch.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_scratch.val = 0x00000000;

    vm_state.machine_exception_pc.csr = 0x0341;
    vm_state.machine_exception_pc.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_exception_pc.val = 0x00000000;

    vm_state.machine_trap_cause.csr = 0x0342;
    vm_state.machine_trap_cause.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_trap_cause.val = 0x00000000;

    vm_state.machine_trap_value.csr = 0x0343;
    vm_state.machine_trap_value.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_trap_value.val = 0x00000000;

    vm_state.machine_interrupt_pending.csr = 0x0344;
    vm_state.machine_interrupt_pending.mode = VM_MODE_FULLY_UNRESTRICTED;
    vm_state.machine_interrupt_pending.val = 0x00000000;

   //TO DO: Add the VM's physical memory protection registers

}

// Function to decode a RISC-V instruction into its components
decoded_inst decode_instruction(uint64 instruction_address, uint32 raw_instruction) {
    decoded_inst decoded;
    
    // Store the original instruction information
    decoded.addr = instruction_address;
    decoded.inst = raw_instruction;
    
    // Extract instruction fields based on RISC-V encoding format 
    decoded.op = raw_instruction & 0b1111111;          // Extract opcode from bits [6:0]
    decoded.rd = (raw_instruction >> 7) & 0b11111;     // Extract destination register from bits [11:7]
    decoded.funct3 = (raw_instruction >> 12) & 0b111;  // Extract function3 code from bits [14:12]
    decoded.rs1 = (raw_instruction >> 15) & 0b11111;   // Extract source register 1 from bits [19:15]
    decoded.rs2 = (raw_instruction >> 20) & 0b11111;   // Extract source register 2 from bits [24:20]
    decoded.uimm = (raw_instruction >> 20);            // Extract upper immediate value from bits [31:20]
    
    return decoded;
}

// Function to print decoded instruction information
void print_instruction(decoded_inst* inst) {
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", inst->addr, inst->op, inst->rd, inst->funct3, inst->rs1, inst->uimm);
}

// Function to initialize the VM's registers and mode
void trap_and_emulate_init(void) {
    init_all_vm_registers();    // Initialize all the VM's registers to 0 
    
    // Set initial machine status register value with proper permissions
    vm_state.machine_status.val = (3UL << 11);  // Set MPP to M-mode (3)
    vm_state.machine_status.val |= (1UL << 7);  // Set MPIE
    vm_state.machine_status.val |= (1UL << 3);  // Set MIE
    
    // Set initial supervisor status register
    vm_state.supervisor_status.val = (1UL << 8); // Set SPP
    vm_state.supervisor_status.val |= (1UL << 5); // Set SPIE
    vm_state.supervisor_status.val |= (1UL << 1); // Set SIE
    
    // Set the mode of the VM to machine mode
    vm_state.mode = VM_MODE_FULLY_UNRESTRICTED;
    
    // Set up trap vectors
    vm_state.machine_trap_vector.val = 0x0;
    vm_state.supervisor_trap_vector.val = 0x0;
    
    printf("VM initialized in mode: %d\n", vm_state.mode);
}

// Function to trap and emulate a RISC-V instruction made by the VM
void trap_and_emulate(void) {
    // Get the current process structure
    struct proc *current_process = myproc();
    
    // Get the instruction address from the trapped Program Counter (PC)
    uint64 instruction_address = current_process->trapframe->epc;
    
    uint32 raw_instruction;

    // Read the instruction from user space memory using copyin
    copyin(current_process->pagetable, (char*)&raw_instruction, instruction_address, sizeof(raw_instruction));
    
    // Decode the instruction into its components
    decoded_inst decoded_instruction = decode_instruction(instruction_address, raw_instruction);


    // Use a switch-case to handle different instructions based on funct3 and uimm
    switch (decoded_instruction.funct3) {
        case 0x0:
            switch (decoded_instruction.uimm) {
                case 0x0: // ECALL
                    printf("(EC at %p)\n", current_process->trapframe->epc);
                    handle_ecall(current_process);
                    break;
                case 0x102: // SRET
                    // print detailed about the process
                    // printf("(SRET at %p)\n", current_process->trapframe->epc);
                    handle_sret(current_process);
                    print_instruction(&decoded_instruction);  // Pass pointer to decoded_instruction
                    break;
                case 0x302: // MRET
                    handle_mret(current_process);
                    print_instruction(&decoded_instruction);  // Pass pointer to decoded_instruction
                    break;
                default:
                    // Handle other cases or errors
                    printf("(Unknown instruction at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                           decoded_instruction.addr, decoded_instruction.op, decoded_instruction.rd, 
                           decoded_instruction.funct3, decoded_instruction.rs1, decoded_instruction.uimm);
                    break;
            }
            break;
        case 0x1: // CSR Write (CSRW)
            handle_csrw(&decoded_instruction, current_process);
            print_instruction(&decoded_instruction);  // Pass pointer to decoded_instruction
            break;
        case 0x2: // CSR Read (CSRR)
            handle_csrr(&decoded_instruction, current_process);
            print_instruction(&decoded_instruction);  // Pass pointer to decoded_instruction
            break;
        default:
            // Print detailed information about the instruction
            printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                   decoded_instruction.addr, decoded_instruction.op, decoded_instruction.rd, 
                   decoded_instruction.funct3, decoded_instruction.rs1, decoded_instruction.uimm);
            break;
    }

    // // Advance the Program Counter to the next instruction
    // current_process->trapframe->epc += 4;
}

// Function to handle the ECALL instruction
void handle_ecall(struct proc *p) {
    uint64 old_pc = p->trapframe->epc;
    
    switch (vm_state.mode) {
        case VM_MODE_RESTRICTED: // U_MODE
            // Save current PC and update status
            vm_state.supervisor_exception_pc.val = old_pc;
            vm_state.supervisor_status.val |= (1UL << 8); // Set SPP to indicate from U-mode
            
            // Change mode and set new PC
            vm_state.mode = VM_MODE_UNRESTRICTED;
            p->trapframe->epc = vm_state.supervisor_trap_vector.val;
            break;

        case VM_MODE_UNRESTRICTED: // S_MODE
            // Save current PC and update status
            vm_state.machine_exception_pc.val = old_pc;
            vm_state.machine_status.val |= (1UL << 11); // Set MPP to indicate from S-mode
            
            // Change mode and set new PC
            vm_state.mode = VM_MODE_FULLY_UNRESTRICTED;
            p->trapframe->epc = vm_state.machine_trap_vector.val;
            break;

        default:
            printf("ECALL from M-mode not supported\n");
            setkilled(p);
            break;
    }
}

void handle_sret(struct proc *p) {

    if (vm_state.mode >= VM_MODE_UNRESTRICTED) {
        unsigned long sstatus = vm_state.supervisor_status.val;
        unsigned long spp_bit = (sstatus >> 8) & 0x1; // Get SPP bit
        sstatus &= ~(1UL << 8); // Clear the SPP bit

        unsigned long spie_bit = (sstatus >> 5) & 0x1; // Get the previous interrupt enable bit (SPIE)
        sstatus |= spie_bit << 1; // Set SIE bit to SPIE
        sstatus &= ~(1UL << 5); // Clear SPIE bit

        // Set the current privilege level (mode) to SPP
        if (spp_bit) {
            vm_state.mode = VM_MODE_UNRESTRICTED;
        } else {
            vm_state.mode = VM_MODE_RESTRICTED;
        }

        vm_state.supervisor_status.val = sstatus; // Write back to the sstatus register

        p->trapframe->epc = vm_state.supervisor_exception_pc.val; // Set the program counter to the value of SEPC
    } else {
        setkilled(p);
        trap_and_emulate_init();
    }
}

void handle_mret(struct proc *p) {
    if (vm_state.mode >= VM_MODE_FULLY_UNRESTRICTED) {
        unsigned long mstatus = vm_state.machine_status.val;

        unsigned long mpp = (mstatus >> 11) & 0x1; // Extract the previous privilege level (MPP)
        mstatus &= ~MSTATUS_MPP_MASK; // Clear MPP bits

        unsigned long mpie = (mstatus >> 7) & 0x1; // Extract the previous interrupt enable bit (MPIE)

        mstatus |= mpie << 3; // Set MIE bit to MPIE
        mstatus &= (1 << 0x7); // Set MPIE bit to 1
        mstatus &= ~(1 << 0x17); // Clear MPRV bit

        // Set the current privilege level (mode) to MPP
        if (mpp) {
            vm_state.mode = VM_MODE_UNRESTRICTED;
        } else {
            vm_state.mode = VM_MODE_RESTRICTED;
        }

        vm_state.machine_status.val = mstatus; // Write back to the mstatus register

        p->trapframe->epc = vm_state.machine_exception_pc.val; // Set the program counter to the value of MEPC

        // Copy the page table entries
        vm_state.vm_ptable = proc_pagetable(p);
        for (uint64 i = 0; i < p->sz; i += PGSIZE) {
            pte_t *pte = walk(p->pagetable, i, 0);
            if (pte == 0 || (*pte & PTE_V) == 0) {
                panic("uvmcopy: page not present");
            }
            uint64 pa = PTE2PA(*pte);
            uint flags = PTE_FLAGS(*pte);
            mappages(vm_state.vm_ptable, i, PGSIZE, (uint64)pa, flags);
        }

        // Unmap a specific memory region
        uvmunmap(vm_state.vm_ptable, 0x0000000080000000, 1, 0);
        p->pagetable = vm_state.vm_ptable;
    } else {
        setkilled(p);
        trap_and_emulate_init();
    }
}

uint64* get_vm_trapframe_register(uint32 reg, struct trapframe *tf) {
    // reg == 1 corresponds to ra (x1), reg == 2 to sp (x2), etc.
    if (reg == 0) return 0;  // x0 is hardwired to 0
    return (uint64*)((char*)&tf->ra + (reg - 1) * sizeof(uint64));
}

void handle_csrw(decoded_inst *decoded, struct proc *p) {
    // Get source register value from trapframe
    uint64 *src_reg = get_vm_trapframe_register(decoded->rs1, p->trapframe);
    
    // Get destination CSR register from vm_state
    vm_register *dest_csr = NULL;
    
    // Find the matching CSR register based on immediate value
    switch (decoded->uimm) {
        // User trap setup registers
        case 0x0000: dest_csr = &vm_state.user_status; break;
        case 0x0004: dest_csr = &vm_state.user_interrupt_enable; break;
        case 0x0005: dest_csr = &vm_state.user_trap_vector; break;
        
        // User trap handling registers
        case 0x0040: dest_csr = &vm_state.user_scratch; break;
        case 0x0041: dest_csr = &vm_state.user_exception_pc; break;
        case 0x0042: dest_csr = &vm_state.user_trap_cause; break;
        case 0x0043: dest_csr = &vm_state.user_trap_value; break;
        case 0x0044: dest_csr = &vm_state.user_interrupt_pending; break;
        
        // Supervisor trap setup registers
        case 0x0100: dest_csr = &vm_state.supervisor_status; break;
        case 0x0102: dest_csr = &vm_state.supervisor_exception_delegation; break;
        case 0x0103: dest_csr = &vm_state.supervisor_interrupt_delegation; break;
        case 0x0104: dest_csr = &vm_state.supervisor_interrupt_enable; break;
        case 0x0105: dest_csr = &vm_state.supervisor_trap_vector; break;
        case 0x0106: dest_csr = &vm_state.supervisor_counter_enable; break;
        
        // Supervisor trap handling registers
        case 0x0140: dest_csr = &vm_state.supervisor_scratch; break;
        case 0x0141: dest_csr = &vm_state.supervisor_exception_pc; break;
        case 0x0142: dest_csr = &vm_state.supervisor_trap_cause; break;
        case 0x0143: dest_csr = &vm_state.supervisor_trap_value; break;
        case 0x0144: dest_csr = &vm_state.supervisor_interrupt_pending; break;
        
         
        // Supervisor page table register
        case 0x0180: dest_csr = &vm_state.supervisor_address_translation; break;

        // Machine information registers
        case 0x0f11: dest_csr = &vm_state.machine_vendor_id; break;
        case 0x0f12: dest_csr = &vm_state.machine_architecture_id; break;
        case 0x0f13: dest_csr = &vm_state.machine_implementation_id; break;
        case 0x0f14: dest_csr = &vm_state.machine_hardware_thread_id; break;
        
        // Machine trap setup registers
        case 0x0300: dest_csr = &vm_state.machine_status; break;
        case 0x0301: dest_csr = &vm_state.machine_isa; break;
        case 0x0302: dest_csr = &vm_state.machine_exception_delegation; break;
        case 0x0303: dest_csr = &vm_state.machine_interrupt_delegation; break;
        case 0x0304: dest_csr = &vm_state.machine_interrupt_enable; break;
        case 0x0305: dest_csr = &vm_state.machine_trap_vector; break;
        case 0x0306: dest_csr = &vm_state.machine_counter_enable; break;
        
        // Machine trap handling registers
        case 0x0340: dest_csr = &vm_state.machine_scratch; break;
        case 0x0341: dest_csr = &vm_state.machine_exception_pc; break;
        case 0x0342: dest_csr = &vm_state.machine_trap_cause; break;
        case 0x0343: dest_csr = &vm_state.machine_trap_value; break;
        case 0x0344: dest_csr = &vm_state.machine_interrupt_pending; break;
        
        default:
            // Invalid CSR address
            printf("Invalid CSR address: %x\n", decoded->uimm);
            setkilled(p);
            return;
    }
    
    // Check if we found a valid CSR and have appropriate privileges
    if (dest_csr != NULL && vm_state.mode >= dest_csr->mode) {
        // Special handling for mvendorid (0xf11)
        if (decoded->uimm == 0xf11) {
            dest_csr->val = *src_reg;
            // Kill process if trying to set mvendorid to 0
            if (dest_csr->val == 0) {
                setkilled(p);
                return;
            }
        } else {
            // Normal CSR write
            dest_csr->val = *src_reg;
        }
        
        // Advance PC
        p->trapframe->epc += 4;
    } else {
        // Invalid privileges or CSR not found
        setkilled(p);
    }
}

void handle_csrr(decoded_inst *decoded, struct proc *p) {
    // Print instruction details
   
    // Check if this is a valid CSRR instruction (op = 0x73, rs1 = 0)
    if (decoded->op == 0x73 && decoded->rs1 == 0x0) {
        // Get source CSR register from vm_state
        vm_register *dest_csr = NULL;
        
        // Find the matching CSR register based on immediate value
        switch (decoded->uimm) {
            // User trap setup registers
        case 0x0000: dest_csr = &vm_state.user_status; break;
        case 0x0004: dest_csr = &vm_state.user_interrupt_enable; break;
        case 0x0005: dest_csr = &vm_state.user_trap_vector; break;
        
        // User trap handling registers
        case 0x0040: dest_csr = &vm_state.user_scratch; break;
        case 0x0041: dest_csr = &vm_state.user_exception_pc; break;
        case 0x0042: dest_csr = &vm_state.user_trap_cause; break;
        case 0x0043: dest_csr = &vm_state.user_trap_value; break;
        case 0x0044: dest_csr = &vm_state.user_interrupt_pending; break;
        
        // Supervisor trap setup registers
        case 0x0100: dest_csr = &vm_state.supervisor_status; break;
        case 0x0102: dest_csr = &vm_state.supervisor_exception_delegation; break;
        case 0x0103: dest_csr = &vm_state.supervisor_interrupt_delegation; break;
        case 0x0104: dest_csr = &vm_state.supervisor_interrupt_enable; break;
        case 0x0105: dest_csr = &vm_state.supervisor_trap_vector; break;
        case 0x0106: dest_csr = &vm_state.supervisor_counter_enable; break;
        
        // Supervisor trap handling registers
        case 0x0140: dest_csr = &vm_state.supervisor_scratch; break;
        case 0x0141: dest_csr = &vm_state.supervisor_exception_pc; break;
        case 0x0142: dest_csr = &vm_state.supervisor_trap_cause; break;
        case 0x0143: dest_csr = &vm_state.supervisor_trap_value; break;
        case 0x0144: dest_csr = &vm_state.supervisor_interrupt_pending; break;
        
         
        // Supervisor page table register
        case 0x0180: dest_csr = &vm_state.supervisor_address_translation; break;

        // Machine information registers
        case 0x0f11: dest_csr = &vm_state.machine_vendor_id; break;
        case 0x0f12: dest_csr = &vm_state.machine_architecture_id; break;
        case 0x0f13: dest_csr = &vm_state.machine_implementation_id; break;
        case 0x0f14: dest_csr = &vm_state.machine_hardware_thread_id; break;
        
        // Machine trap setup registers
        case 0x0300: dest_csr = &vm_state.machine_status; break;
        case 0x0301: dest_csr = &vm_state.machine_isa; break;
        case 0x0302: dest_csr = &vm_state.machine_exception_delegation; break;
        case 0x0303: dest_csr = &vm_state.machine_interrupt_delegation; break;
        case 0x0304: dest_csr = &vm_state.machine_interrupt_enable; break;
        case 0x0305: dest_csr = &vm_state.machine_trap_vector; break;
        case 0x0306: dest_csr = &vm_state.machine_counter_enable; break;
        
        // Machine trap handling registers
        case 0x0340: dest_csr = &vm_state.machine_scratch; break;
        case 0x0341: dest_csr = &vm_state.machine_exception_pc; break;
        case 0x0342: dest_csr = &vm_state.machine_trap_cause; break;
        case 0x0343: dest_csr = &vm_state.machine_trap_value; break;
        case 0x0344: dest_csr = &vm_state.machine_interrupt_pending; break;
        
        default:
            setkilled(p);
            return;
        }

        // Get destination register from trapframe
        uint64 *dest = get_vm_trapframe_register(decoded->rd, p->trapframe);
        
        if (dest_csr != NULL && dest != NULL) {
            // Special case: mvendorid can be read from any privilege mode
            if (decoded->uimm == 0x0f11) {
                *dest = dest_csr->val;
                p->trapframe->epc += 4;
            }
            // Normal case: check privilege level
            else if (vm_state.mode >= dest_csr->mode) {
                *dest = dest_csr->val;
                p->trapframe->epc += 4;
            }
            // Insufficient privileges
            else {
                setkilled(p);
            }
        } else {
            // Invalid register
            setkilled(p);
        }
    } else {
        // Invalid instruction format
        setkilled(p);
    }
}