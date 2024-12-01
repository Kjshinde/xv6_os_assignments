#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

// Declare external symbols
extern char trampoline[], uservec[], userret[];
extern void kernelvec();
extern int devintr();

void
trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

/*
 * Handle an interrupt, exception, or system call from user space.
 * Called from trampoline.S
 */
void
usertrap(void)
{
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // Send interrupts and exceptions to kerneltrap(), since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();
  
  // Save user program counter.
  p->trapframe->epc = r_sepc();
  
  if(strncmp(p->name, "vm-", 3) == 0 && (r_scause() == 2 || r_scause() == 1)){
    trap_and_emulate();
  }
  else if(r_scause() == 8){
    // System call
    if(killed(p))
      exit(-1);
  
    if(strncmp(p->name, "vm-", 3) == 0){
      trap_and_emulate();
    }
    else{
      // sepc points to the ecall instruction,
      // but we want to return to the next instruction.
      p->trapframe->epc += 4;

      // An interrupt will change sepc, scause, and sstatus,
      // so enable only now that we're done with those registers.
      intr_on();

      syscall();
    }
  } else if((which_dev = devintr()) != 0){
    // Handle device interrupts
    // Device interrupt handling code...
  } else {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if(killed(p))
    exit(-1);

  // Yield the CPU if this was a timer interrupt.
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // The yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  // Removed unused variable 'fn'.
  usertrapret();
}

void
clockintr()
{
  acquire(&tickslock);
  ticks++;
  wakeup(&ticks);
  release(&tickslock);
}

// Check if it's an external interrupt or software interrupt,
// and handle it.
// Returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) && (scause & 0xff) == 9){
    // This is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // The PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    // Software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if(cpuid() == 0){
      clockintr();
    }
    
    // Acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
  }
}

// return to user space
void
usertrapret(void)
{
  struct proc *p = myproc();

  // ... [Other implementation code] ...

  // Ensure the sstatus.SPP bit is set to 0 for user mode
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // Set sepc to the saved user program counter
  w_sepc(p->trapframe->epc);

  // Switch to user page table
  uint64 satp = MAKE_SATP(p->pagetable);
  w_satp(satp);
  sfence_vma();

  // Tell the hardware the user page table to use in the next exception cycle.

  // Removed unused variable 'fn'

  // Use trampoline to return to user space
  ((void (*)(void))TRAMPOLINE)();
}

