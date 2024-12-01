
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b1010113          	addi	sp,sp,-1264 # 80008b10 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	00009717          	auipc	a4,0x9
    80000058:	97c70713          	addi	a4,a4,-1668 # 800089d0 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c8a78793          	addi	a5,a5,-886 # 80005cf0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc577>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00011517          	auipc	a0,0x11
    8000018c:	98850513          	addi	a0,a0,-1656 # 80010b10 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00011497          	auipc	s1,0x11
    8000019c:	97848493          	addi	s1,s1,-1672 # 80010b10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00011917          	auipc	s2,0x11
    800001a4:	a0890913          	addi	s2,s2,-1528 # 80010ba8 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00011717          	auipc	a4,0x11
    800001e6:	92e70713          	addi	a4,a4,-1746 # 80010b10 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	8e450513          	addi	a0,a0,-1820 # 80010b10 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	8ce50513          	addi	a0,a0,-1842 # 80010b10 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	92f72b23          	sw	a5,-1738(a4) # 80010ba8 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	84450513          	addi	a0,a0,-1980 # 80010b10 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	81650513          	addi	a0,a0,-2026 # 80010b10 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	7f270713          	addi	a4,a4,2034 # 80010b10 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7c878793          	addi	a5,a5,1992 # 80010b10 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8327a783          	lw	a5,-1998(a5) # 80010ba8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	78670713          	addi	a4,a4,1926 # 80010b10 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	77648493          	addi	s1,s1,1910 # 80010b10 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	73a70713          	addi	a4,a4,1850 # 80010b10 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7cf72223          	sw	a5,1988(a4) # 80010bb0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	6fe78793          	addi	a5,a5,1790 # 80010b10 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	76c7ab23          	sw	a2,1910(a5) # 80010bac <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	76a50513          	addi	a0,a0,1898 # 80010ba8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6b050513          	addi	a0,a0,1712 # 80010b10 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	a3078793          	addi	a5,a5,-1488 # 80020ea8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6807a223          	sw	zero,1668(a5) # 80010bd0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	40f72823          	sw	a5,1040(a4) # 80008990 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008a97          	auipc	s5,0x8
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00008517          	auipc	a0,0x8
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80008028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00008917          	auipc	s2,0x8
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80008020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00010497          	auipc	s1,0x10
    800007f6:	3c648493          	addi	s1,s1,966 # 80010bb8 <pr>
    800007fa:	00008597          	auipc	a1,0x8
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80008038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00008597          	auipc	a1,0x8
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80008058 <digits+0x18>
    80000852:	00010517          	auipc	a0,0x10
    80000856:	38650513          	addi	a0,a0,902 # 80010bd8 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00008797          	auipc	a5,0x8
    800008ae:	0ee7b783          	ld	a5,238(a5) # 80008998 <uart_tx_r>
    800008b2:	00008717          	auipc	a4,0x8
    800008b6:	0ee73703          	ld	a4,238(a4) # 800089a0 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00010a17          	auipc	s4,0x10
    800008d8:	304a0a13          	addi	s4,s4,772 # 80010bd8 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00008497          	auipc	s1,0x8
    800008e0:	0bc48493          	addi	s1,s1,188 # 80008998 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00008997          	auipc	s3,0x8
    800008e8:	0bc98993          	addi	s3,s3,188 # 800089a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00010517          	auipc	a0,0x10
    80000946:	29650513          	addi	a0,a0,662 # 80010bd8 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	03e7a783          	lw	a5,62(a5) # 80008990 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00008717          	auipc	a4,0x8
    80000960:	04473703          	ld	a4,68(a4) # 800089a0 <uart_tx_w>
    80000964:	00008797          	auipc	a5,0x8
    80000968:	0347b783          	ld	a5,52(a5) # 80008998 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00010997          	auipc	s3,0x10
    80000974:	26898993          	addi	s3,s3,616 # 80010bd8 <uart_tx_lock>
    80000978:	00008497          	auipc	s1,0x8
    8000097c:	02048493          	addi	s1,s1,32 # 80008998 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00008917          	auipc	s2,0x8
    80000984:	02090913          	addi	s2,s2,32 # 800089a0 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00010497          	auipc	s1,0x10
    800009aa:	23248493          	addi	s1,s1,562 # 80010bd8 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00008797          	auipc	a5,0x8
    800009be:	fee7b323          	sd	a4,-26(a5) # 800089a0 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00010497          	auipc	s1,0x10
    80000a30:	1ac48493          	addi	s1,s1,428 # 80010bd8 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00022797          	auipc	a5,0x22
    80000a72:	81a78793          	addi	a5,a5,-2022 # 80022288 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00010917          	auipc	s2,0x10
    80000a92:	18290913          	addi	s2,s2,386 # 80010c10 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80008060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	addi	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	0e450513          	addi	a0,a0,228 # 80010c10 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00021517          	auipc	a0,0x21
    80000b44:	74850513          	addi	a0,a0,1864 # 80022288 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00010497          	auipc	s1,0x10
    80000b66:	0ae48493          	addi	s1,s1,174 # 80010c10 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00010517          	auipc	a0,0x10
    80000b7e:	09650513          	addi	a0,a0,150 # 80010c10 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00010517          	auipc	a0,0x10
    80000baa:	06a50513          	addi	a0,a0,106 # 80010c10 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3e450513          	addi	a0,a0,996 # 80008070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39c50513          	addi	a0,a0,924 # 80008078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3a450513          	addi	a0,a0,932 # 80008090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00007517          	auipc	a0,0x7
    80000d38:	36450513          	addi	a0,a0,868 # 80008098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcd79>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00008717          	auipc	a4,0x8
    80000efc:	ab070713          	addi	a4,a4,-1360 # 800089a8 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1a250513          	addi	a0,a0,418 # 800080b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7ec080e7          	jalr	2028(ra) # 8000271a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dfa080e7          	jalr	-518(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00007517          	auipc	a0,0x7
    80000f5a:	17250513          	addi	a0,a0,370 # 800080c8 <digits+0x88>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13a50513          	addi	a0,a0,314 # 800080a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	74c080e7          	jalr	1868(ra) # 800026f2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	76c080e7          	jalr	1900(ra) # 8000271a <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d64080e7          	jalr	-668(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d72080e7          	jalr	-654(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	efe080e7          	jalr	-258(ra) # 80002ec4 <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	59c080e7          	jalr	1436(ra) # 8000356a <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	512080e7          	jalr	1298(ra) # 800044e8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e5a080e7          	jalr	-422(ra) # 80005e38 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	978080e7          	jalr	-1672(ra) # 80006966 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00008717          	auipc	a4,0x8
    80001000:	9af72623          	sw	a5,-1620(a4) # 800089a8 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	9a07b783          	ld	a5,-1632(a5) # 800089b0 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	addi	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcd6f>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	addi	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	addi	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	addi	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	addi	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00007797          	auipc	a5,0x7
    800012d0:	6ea7b223          	sd	a0,1764(a5) # 800089b0 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	addi	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	addi	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	addi	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	addi	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	addi	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80008188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800081a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	af450513          	addi	a0,a0,-1292 # 800081c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcd78>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	0000f497          	auipc	s1,0xf
    800018c8:	79c48493          	addi	s1,s1,1948 # 80011060 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00006a97          	auipc	s5,0x6
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80008000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00015a17          	auipc	s4,0x15
    800018e2:	382a0a13          	addi	s4,s4,898 # 80016c60 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8a450513          	addi	a0,a0,-1884 # 800081d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	88858593          	addi	a1,a1,-1912 # 800081e0 <digits+0x1a0>
    80001960:	0000f517          	auipc	a0,0xf
    80001964:	2d050513          	addi	a0,a0,720 # 80010c30 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	87858593          	addi	a1,a1,-1928 # 800081e8 <digits+0x1a8>
    80001978:	0000f517          	auipc	a0,0xf
    8000197c:	2d050513          	addi	a0,a0,720 # 80010c48 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	0000f497          	auipc	s1,0xf
    8000198c:	6d848493          	addi	s1,s1,1752 # 80011060 <proc>
      initlock(&p->lock, "proc");
    80001990:	00007b17          	auipc	s6,0x7
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00006a17          	auipc	s4,0x6
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00015997          	auipc	s3,0x15
    800019ae:	2b698993          	addi	s3,s3,694 # 80016c60 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	0000f517          	auipc	a0,0xf
    80001a18:	24c50513          	addi	a0,a0,588 # 80010c60 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	0000f717          	auipc	a4,0xf
    80001a40:	1f470713          	addi	a4,a4,500 # 80010c30 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00007797          	auipc	a5,0x7
    80001a78:	ecc7a783          	lw	a5,-308(a5) # 80008940 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	cb4080e7          	jalr	-844(ra) # 80002732 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	ea07a923          	sw	zero,-334(a5) # 80008940 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a52080e7          	jalr	-1454(ra) # 800034ea <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	0000f917          	auipc	s2,0xf
    80001ab2:	18290913          	addi	s2,s2,386 # 80010c30 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	e8478793          	addi	a5,a5,-380 # 80008944 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	61c58593          	addi	a1,a1,1564 # 80008200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	slli	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	0000f497          	auipc	s1,0xf
    80001c6c:	3f848493          	addi	s1,s1,1016 # 80011060 <proc>
    80001c70:	00015917          	auipc	s2,0x15
    80001c74:	ff090913          	addi	s2,s2,-16 # 80016c60 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	addi	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	addi	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	c6a7bd23          	sd	a0,-902(a5) # 800089b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00007597          	auipc	a1,0x7
    80001d4e:	c0658593          	addi	a1,a1,-1018 # 80008950 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00006597          	auipc	a1,0x6
    80001d70:	49c58593          	addi	a1,a1,1180 # 80008208 <digits+0x1c8>
    80001d74:	15848513          	addi	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	49850513          	addi	a0,a0,1176 # 80008218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	180080e7          	jalr	384(ra) # 80003f08 <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	addi	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	addi	s1,s5,208
    80001e8a:	0d0a0913          	addi	s2,s4,208
    80001e8e:	150a8993          	addi	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	addi	s1,s1,8
    80001eae:	0921                	addi	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	6c2080e7          	jalr	1730(ra) # 8000457a <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	85a080e7          	jalr	-1958(ra) # 80003724 <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	addi	a1,s5,344
    80001edc:	158a0513          	addi	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	d5248493          	addi	s1,s1,-686 # 80010c48 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	ccc70713          	addi	a4,a4,-820 # 80010c30 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	cf670713          	addi	a4,a4,-778 # 80010c68 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	caea0a13          	addi	s4,s4,-850 # 80010c30 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00015917          	auipc	s2,0x15
    80001f90:	cd490913          	addi	s2,s2,-812 # 80016c60 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	0000f497          	auipc	s1,0xf
    80001fa4:	0c048493          	addi	s1,s1,192 # 80011060 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	c2070713          	addi	a4,a4,-992 # 80010c30 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	bfa90913          	addi	s2,s2,-1030 # 80010c30 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	c1a58593          	addi	a1,a1,-998 # 80010c68 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	addi	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	addi	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	1a250513          	addi	a0,a0,418 # 80008240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	1a250513          	addi	a0,a0,418 # 80008250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	eee48493          	addi	s1,s1,-274 # 80011060 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015917          	auipc	s2,0x15
    80002182:	ae290913          	addi	s2,s2,-1310 # 80016c60 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	e7a48493          	addi	s1,s1,-390 # 80011060 <proc>
      pp->parent = initproc;
    800021ee:	00006a17          	auipc	s4,0x6
    800021f2:	7caa0a13          	addi	s4,s4,1994 # 800089b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00015997          	auipc	s3,0x15
    800021fa:	a6a98993          	addi	s3,s3,-1430 # 80016c60 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	addi	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	addi	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	addi	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00006797          	auipc	a5,0x6
    8000224e:	76e7b783          	ld	a5,1902(a5) # 800089b8 <initproc>
    80002252:	0d050493          	addi	s1,a0,208
    80002256:	15050913          	addi	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	addi	a0,a0,10 # 80008268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	35e080e7          	jalr	862(ra) # 800045cc <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	addi	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e82080e7          	jalr	-382(ra) # 80004108 <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	68a080e7          	jalr	1674(ra) # 8000391c <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	ee8080e7          	jalr	-280(ra) # 80004182 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	9a248493          	addi	s1,s1,-1630 # 80010c48 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f8450513          	addi	a0,a0,-124 # 80008278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	d4c48493          	addi	s1,s1,-692 # 80011060 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	94498993          	addi	s3,s3,-1724 # 80016c60 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	addi	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000f517          	auipc	a0,0xf
    800023fc:	85050513          	addi	a0,a0,-1968 # 80010c48 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	85298993          	addi	s3,s3,-1966 # 80016c60 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	0000fc17          	auipc	s8,0xf
    8000241a:	832c0c13          	addi	s8,s8,-1998 # 80010c48 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	0000e517          	auipc	a0,0xe
    80002458:	7f450513          	addi	a0,a0,2036 # 80010c48 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	0000e517          	auipc	a0,0xe
    8000248c:	7c050513          	addi	a0,a0,1984 # 80010c48 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	b7c48493          	addi	s1,s1,-1156 # 80011060 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	0000e517          	auipc	a0,0xe
    800024f2:	75a50513          	addi	a0,a0,1882 # 80010c48 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800080c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	be448493          	addi	s1,s1,-1052 # 800111b8 <proc+0x158>
    800025dc:	00014917          	auipc	s2,0x14
    800025e0:	7dc90913          	addi	s2,s2,2012 # 80016db8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	addi	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800082d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	addi	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <check_vm_or_not>:

extern int devintr();

//-------------- Function Definitions --------------

int check_vm_or_not(struct proc *p){
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  if(strncmp(p->name, "vm-", 3) == 0){
    800026d0:	460d                	li	a2,3
    800026d2:	00006597          	auipc	a1,0x6
    800026d6:	b2e58593          	addi	a1,a1,-1234 # 80008200 <digits+0x1c0>
    800026da:	15850513          	addi	a0,a0,344
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	736080e7          	jalr	1846(ra) # 80000e14 <strncmp>
    return 1;
  }
  return 0;
}
    800026e6:	00153513          	seqz	a0,a0
    800026ea:	60a2                	ld	ra,8(sp)
    800026ec:	6402                	ld	s0,0(sp)
    800026ee:	0141                	addi	sp,sp,16
    800026f0:	8082                	ret

00000000800026f2 <trapinit>:

// Initialize the ticks lock
void
trapinit(void)
{
    800026f2:	1141                	addi	sp,sp,-16
    800026f4:	e406                	sd	ra,8(sp)
    800026f6:	e022                	sd	s0,0(sp)
    800026f8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fa:	00006597          	auipc	a1,0x6
    800026fe:	c0658593          	addi	a1,a1,-1018 # 80008300 <states.0+0x30>
    80002702:	00014517          	auipc	a0,0x14
    80002706:	55e50513          	addi	a0,a0,1374 # 80016c60 <tickslock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4ae080e7          	jalr	1198(ra) # 80000bb8 <initlock>
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e422                	sd	s0,8(sp)
    8000271e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	00003797          	auipc	a5,0x3
    80002724:	54078793          	addi	a5,a5,1344 # 80005c60 <kernelvec>
    80002728:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272c:	6422                	ld	s0,8(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	2ea080e7          	jalr	746(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002742:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002746:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000274c:	00005697          	auipc	a3,0x5
    80002750:	8b468693          	addi	a3,a3,-1868 # 80007000 <_trampoline>
    80002754:	00005717          	auipc	a4,0x5
    80002758:	8ac70713          	addi	a4,a4,-1876 # 80007000 <_trampoline>
    8000275c:	8f15                	sub	a4,a4,a3
    8000275e:	040007b7          	lui	a5,0x4000
    80002762:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002764:	07b2                	slli	a5,a5,0xc
    80002766:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002768:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000276e:	18002673          	csrr	a2,satp
    80002772:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002774:	6d30                	ld	a2,88(a0)
    80002776:	6138                	ld	a4,64(a0)
    80002778:	6585                	lui	a1,0x1
    8000277a:	972e                	add	a4,a4,a1
    8000277c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000277e:	6d38                	ld	a4,88(a0)
    80002780:	00000617          	auipc	a2,0x0
    80002784:	13460613          	addi	a2,a2,308 # 800028b4 <usertrap>
    80002788:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278c:	8612                	mv	a2,tp
    8000278e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002794:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002798:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a2:	6f18                	ld	a4,24(a4)
    800027a4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027a8:	6928                	ld	a0,80(a0)
    800027aa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027ac:	00005717          	auipc	a4,0x5
    800027b0:	8f070713          	addi	a4,a4,-1808 # 8000709c <userret>
    800027b4:	8f15                	sub	a4,a4,a3
    800027b6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027b8:	577d                	li	a4,-1
    800027ba:	177e                	slli	a4,a4,0x3f
    800027bc:	8d59                	or	a0,a0,a4
    800027be:	9782                	jalr	a5
}
    800027c0:	60a2                	ld	ra,8(sp)
    800027c2:	6402                	ld	s0,0(sp)
    800027c4:	0141                	addi	sp,sp,16
    800027c6:	8082                	ret

00000000800027c8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027c8:	1101                	addi	sp,sp,-32
    800027ca:	ec06                	sd	ra,24(sp)
    800027cc:	e822                	sd	s0,16(sp)
    800027ce:	e426                	sd	s1,8(sp)
    800027d0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027d2:	00014497          	auipc	s1,0x14
    800027d6:	48e48493          	addi	s1,s1,1166 # 80016c60 <tickslock>
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	46c080e7          	jalr	1132(ra) # 80000c48 <acquire>
  ticks++;
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	1dc50513          	addi	a0,a0,476 # 800089c0 <ticks>
    800027ec:	411c                	lw	a5,0(a0)
    800027ee:	2785                	addiw	a5,a5,1
    800027f0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	96c080e7          	jalr	-1684(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	500080e7          	jalr	1280(ra) # 80000cfc <release>
}
    80002804:	60e2                	ld	ra,24(sp)
    80002806:	6442                	ld	s0,16(sp)
    80002808:	64a2                	ld	s1,8(sp)
    8000280a:	6105                	addi	sp,sp,32
    8000280c:	8082                	ret

000000008000280e <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280e:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002812:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002814:	0807df63          	bgez	a5,800028b2 <devintr+0xa4>
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002822:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002826:	46a5                	li	a3,9
    80002828:	00d70d63          	beq	a4,a3,80002842 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    8000282c:	577d                	li	a4,-1
    8000282e:	177e                	slli	a4,a4,0x3f
    80002830:	0705                	addi	a4,a4,1
    return 0;
    80002832:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002834:	04e78e63          	beq	a5,a4,80002890 <devintr+0x82>
  }
}
    80002838:	60e2                	ld	ra,24(sp)
    8000283a:	6442                	ld	s0,16(sp)
    8000283c:	64a2                	ld	s1,8(sp)
    8000283e:	6105                	addi	sp,sp,32
    80002840:	8082                	ret
    int irq = plic_claim();
    80002842:	00003097          	auipc	ra,0x3
    80002846:	526080e7          	jalr	1318(ra) # 80005d68 <plic_claim>
    8000284a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000284c:	47a9                	li	a5,10
    8000284e:	02f50763          	beq	a0,a5,8000287c <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002852:	4785                	li	a5,1
    80002854:	02f50963          	beq	a0,a5,80002886 <devintr+0x78>
    return 1;
    80002858:	4505                	li	a0,1
    } else if(irq){
    8000285a:	dcf9                	beqz	s1,80002838 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    8000285c:	85a6                	mv	a1,s1
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	aaa50513          	addi	a0,a0,-1366 # 80008308 <states.0+0x38>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	d24080e7          	jalr	-732(ra) # 8000058a <printf>
      plic_complete(irq);
    8000286e:	8526                	mv	a0,s1
    80002870:	00003097          	auipc	ra,0x3
    80002874:	51c080e7          	jalr	1308(ra) # 80005d8c <plic_complete>
    return 1;
    80002878:	4505                	li	a0,1
    8000287a:	bf7d                	j	80002838 <devintr+0x2a>
      uartintr();
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	18e080e7          	jalr	398(ra) # 80000a0a <uartintr>
    if(irq)
    80002884:	b7ed                	j	8000286e <devintr+0x60>
      virtio_disk_intr();
    80002886:	00004097          	auipc	ra,0x4
    8000288a:	b7e080e7          	jalr	-1154(ra) # 80006404 <virtio_disk_intr>
    if(irq)
    8000288e:	b7c5                	j	8000286e <devintr+0x60>
    if(cpuid() == 0){
    80002890:	fffff097          	auipc	ra,0xfffff
    80002894:	168080e7          	jalr	360(ra) # 800019f8 <cpuid>
    80002898:	c901                	beqz	a0,800028a8 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000289a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000289e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a0:	14479073          	csrw	sip,a5
    return 2;
    800028a4:	4509                	li	a0,2
    800028a6:	bf49                	j	80002838 <devintr+0x2a>
      clockintr();
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	f20080e7          	jalr	-224(ra) # 800027c8 <clockintr>
    800028b0:	b7ed                	j	8000289a <devintr+0x8c>
}
    800028b2:	8082                	ret

00000000800028b4 <usertrap>:
{
    800028b4:	1101                	addi	sp,sp,-32
    800028b6:	ec06                	sd	ra,24(sp)
    800028b8:	e822                	sd	s0,16(sp)
    800028ba:	e426                	sd	s1,8(sp)
    800028bc:	e04a                	sd	s2,0(sp)
    800028be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028c4:	1007f793          	andi	a5,a5,256
    800028c8:	e3b1                	bnez	a5,8000290c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ca:	00003797          	auipc	a5,0x3
    800028ce:	39678793          	addi	a5,a5,918 # 80005c60 <kernelvec>
    800028d2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	14e080e7          	jalr	334(ra) # 80001a24 <myproc>
    800028de:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e2:	14102773          	csrr	a4,sepc
    800028e6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e8:	14202773          	csrr	a4,scause
   if(r_scause() == CAUSE_SYSCALL_ECALL){
    800028ec:	47a1                	li	a5,8
    800028ee:	02f70763          	beq	a4,a5,8000291c <usertrap+0x68>
    else if((which_dev = devintr()) != 0){
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	f1c080e7          	jalr	-228(ra) # 8000280e <devintr>
    800028fa:	892a                	mv	s2,a0
    800028fc:	cd3d                	beqz	a0,8000297a <usertrap+0xc6>
    if(killed(p))
    800028fe:	8526                	mv	a0,s1
    80002900:	00000097          	auipc	ra,0x0
    80002904:	aa2080e7          	jalr	-1374(ra) # 800023a2 <killed>
    80002908:	cd65                	beqz	a0,80002a00 <usertrap+0x14c>
    8000290a:	a0f5                	j	800029f6 <usertrap+0x142>
    panic("usertrap: not from user mode");
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	a1c50513          	addi	a0,a0,-1508 # 80008328 <states.0+0x58>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c2c080e7          	jalr	-980(ra) # 80000540 <panic>
      if(strncmp(p->name, "vm-", 3) == 0) {
    8000291c:	460d                	li	a2,3
    8000291e:	00006597          	auipc	a1,0x6
    80002922:	8e258593          	addi	a1,a1,-1822 # 80008200 <digits+0x1c0>
    80002926:	15850513          	addi	a0,a0,344
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	4ea080e7          	jalr	1258(ra) # 80000e14 <strncmp>
    80002932:	e909                	bnez	a0,80002944 <usertrap+0x90>
        p->proc_te_vm = 1;  // Mark as VM process
    80002934:	4785                	li	a5,1
    80002936:	16f4a423          	sw	a5,360(s1)
        trap_and_emulate();
    8000293a:	00004097          	auipc	ra,0x4
    8000293e:	fcc080e7          	jalr	-52(ra) # 80006906 <trap_and_emulate>
    80002942:	a05d                	j	800029e8 <usertrap+0x134>
        if(killed(p))
    80002944:	8526                	mv	a0,s1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	a5c080e7          	jalr	-1444(ra) # 800023a2 <killed>
    8000294e:	e105                	bnez	a0,8000296e <usertrap+0xba>
        p->trapframe->epc += 4;
    80002950:	6cb8                	ld	a4,88(s1)
    80002952:	6f1c                	ld	a5,24(a4)
    80002954:	0791                	addi	a5,a5,4
    80002956:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000295c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002960:	10079073          	csrw	sstatus,a5
        syscall();
    80002964:	00000097          	auipc	ra,0x0
    80002968:	314080e7          	jalr	788(ra) # 80002c78 <syscall>
    8000296c:	a8b5                	j	800029e8 <usertrap+0x134>
          exit(-1);
    8000296e:	557d                	li	a0,-1
    80002970:	00000097          	auipc	ra,0x0
    80002974:	8be080e7          	jalr	-1858(ra) # 8000222e <exit>
    80002978:	bfe1                	j	80002950 <usertrap+0x9c>
    else if(strncmp(p->name, "vm-", 3) == 0 && 
    8000297a:	460d                	li	a2,3
    8000297c:	00006597          	auipc	a1,0x6
    80002980:	88458593          	addi	a1,a1,-1916 # 80008200 <digits+0x1c0>
    80002984:	15848513          	addi	a0,s1,344
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	48c080e7          	jalr	1164(ra) # 80000e14 <strncmp>
    80002990:	e105                	bnez	a0,800029b0 <usertrap+0xfc>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002992:	14202773          	csrr	a4,scause
    80002996:	47b1                	li	a5,12
    80002998:	00f70c63          	beq	a4,a5,800029b0 <usertrap+0xfc>
    8000299c:	14202773          	csrr	a4,scause
            r_scause() != CAUSE_INSTRUCTION_PAGE_FAULT && 
    800029a0:	47b5                	li	a5,13
    800029a2:	00f70763          	beq	a4,a5,800029b0 <usertrap+0xfc>
    800029a6:	14202773          	csrr	a4,scause
            r_scause() != CAUSE_LOAD_PAGE_FAULT && 
    800029aa:	47bd                	li	a5,15
    800029ac:	06f71763          	bne	a4,a5,80002a1a <usertrap+0x166>
    800029b0:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029b4:	5890                	lw	a2,48(s1)
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	99250513          	addi	a0,a0,-1646 # 80008348 <states.0+0x78>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	bcc080e7          	jalr	-1076(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ca:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9aa50513          	addi	a0,a0,-1622 # 80008378 <states.0+0xa8>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bb4080e7          	jalr	-1100(ra) # 8000058a <printf>
      setkilled(p);
    800029de:	8526                	mv	a0,s1
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	996080e7          	jalr	-1642(ra) # 80002376 <setkilled>
    if(killed(p))
    800029e8:	8526                	mv	a0,s1
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	9b8080e7          	jalr	-1608(ra) # 800023a2 <killed>
    800029f2:	c911                	beqz	a0,80002a06 <usertrap+0x152>
    800029f4:	4901                	li	s2,0
      exit(-1);
    800029f6:	557d                	li	a0,-1
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	836080e7          	jalr	-1994(ra) # 8000222e <exit>
    if(which_dev == 2)
    80002a00:	4789                	li	a5,2
    80002a02:	02f90163          	beq	s2,a5,80002a24 <usertrap+0x170>
    usertrapret();
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	d2c080e7          	jalr	-724(ra) # 80002732 <usertrapret>
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6902                	ld	s2,0(sp)
    80002a16:	6105                	addi	sp,sp,32
    80002a18:	8082                	ret
      trap_and_emulate();
    80002a1a:	00004097          	auipc	ra,0x4
    80002a1e:	eec080e7          	jalr	-276(ra) # 80006906 <trap_and_emulate>
    80002a22:	b7d9                	j	800029e8 <usertrap+0x134>
      yield();
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	69a080e7          	jalr	1690(ra) # 800020be <yield>
    80002a2c:	bfe9                	j	80002a06 <usertrap+0x152>

0000000080002a2e <kerneltrap>:
{
    80002a2e:	7179                	addi	sp,sp,-48
    80002a30:	f406                	sd	ra,40(sp)
    80002a32:	f022                	sd	s0,32(sp)
    80002a34:	ec26                	sd	s1,24(sp)
    80002a36:	e84a                	sd	s2,16(sp)
    80002a38:	e44e                	sd	s3,8(sp)
    80002a3a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a40:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a44:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a48:	1004f793          	andi	a5,s1,256
    80002a4c:	cb85                	beqz	a5,80002a7c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a52:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a54:	ef85                	bnez	a5,80002a8c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	db8080e7          	jalr	-584(ra) # 8000280e <devintr>
    80002a5e:	cd1d                	beqz	a0,80002a9c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a60:	4789                	li	a5,2
    80002a62:	06f50a63          	beq	a0,a5,80002ad6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a66:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6a:	10049073          	csrw	sstatus,s1
}
    80002a6e:	70a2                	ld	ra,40(sp)
    80002a70:	7402                	ld	s0,32(sp)
    80002a72:	64e2                	ld	s1,24(sp)
    80002a74:	6942                	ld	s2,16(sp)
    80002a76:	69a2                	ld	s3,8(sp)
    80002a78:	6145                	addi	sp,sp,48
    80002a7a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	91c50513          	addi	a0,a0,-1764 # 80008398 <states.0+0xc8>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	abc080e7          	jalr	-1348(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	93450513          	addi	a0,a0,-1740 # 800083c0 <states.0+0xf0>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	aac080e7          	jalr	-1364(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a9c:	85ce                	mv	a1,s3
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	94250513          	addi	a0,a0,-1726 # 800083e0 <states.0+0x110>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ae4080e7          	jalr	-1308(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	93a50513          	addi	a0,a0,-1734 # 800083f0 <states.0+0x120>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	acc080e7          	jalr	-1332(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	94250513          	addi	a0,a0,-1726 # 80008408 <states.0+0x138>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	a72080e7          	jalr	-1422(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	f4e080e7          	jalr	-178(ra) # 80001a24 <myproc>
    80002ade:	d541                	beqz	a0,80002a66 <kerneltrap+0x38>
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	f44080e7          	jalr	-188(ra) # 80001a24 <myproc>
    80002ae8:	4d18                	lw	a4,24(a0)
    80002aea:	4791                	li	a5,4
    80002aec:	f6f71de3          	bne	a4,a5,80002a66 <kerneltrap+0x38>
    yield();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	5ce080e7          	jalr	1486(ra) # 800020be <yield>
    80002af8:	b7bd                	j	80002a66 <kerneltrap+0x38>

0000000080002afa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002afa:	1101                	addi	sp,sp,-32
    80002afc:	ec06                	sd	ra,24(sp)
    80002afe:	e822                	sd	s0,16(sp)
    80002b00:	e426                	sd	s1,8(sp)
    80002b02:	1000                	addi	s0,sp,32
    80002b04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	f1e080e7          	jalr	-226(ra) # 80001a24 <myproc>
  switch (n) {
    80002b0e:	4795                	li	a5,5
    80002b10:	0497e163          	bltu	a5,s1,80002b52 <argraw+0x58>
    80002b14:	048a                	slli	s1,s1,0x2
    80002b16:	00006717          	auipc	a4,0x6
    80002b1a:	92a70713          	addi	a4,a4,-1750 # 80008440 <states.0+0x170>
    80002b1e:	94ba                	add	s1,s1,a4
    80002b20:	409c                	lw	a5,0(s1)
    80002b22:	97ba                	add	a5,a5,a4
    80002b24:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b26:	6d3c                	ld	a5,88(a0)
    80002b28:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b2a:	60e2                	ld	ra,24(sp)
    80002b2c:	6442                	ld	s0,16(sp)
    80002b2e:	64a2                	ld	s1,8(sp)
    80002b30:	6105                	addi	sp,sp,32
    80002b32:	8082                	ret
    return p->trapframe->a1;
    80002b34:	6d3c                	ld	a5,88(a0)
    80002b36:	7fa8                	ld	a0,120(a5)
    80002b38:	bfcd                	j	80002b2a <argraw+0x30>
    return p->trapframe->a2;
    80002b3a:	6d3c                	ld	a5,88(a0)
    80002b3c:	63c8                	ld	a0,128(a5)
    80002b3e:	b7f5                	j	80002b2a <argraw+0x30>
    return p->trapframe->a3;
    80002b40:	6d3c                	ld	a5,88(a0)
    80002b42:	67c8                	ld	a0,136(a5)
    80002b44:	b7dd                	j	80002b2a <argraw+0x30>
    return p->trapframe->a4;
    80002b46:	6d3c                	ld	a5,88(a0)
    80002b48:	6bc8                	ld	a0,144(a5)
    80002b4a:	b7c5                	j	80002b2a <argraw+0x30>
    return p->trapframe->a5;
    80002b4c:	6d3c                	ld	a5,88(a0)
    80002b4e:	6fc8                	ld	a0,152(a5)
    80002b50:	bfe9                	j	80002b2a <argraw+0x30>
  panic("argraw");
    80002b52:	00006517          	auipc	a0,0x6
    80002b56:	8c650513          	addi	a0,a0,-1850 # 80008418 <states.0+0x148>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	9e6080e7          	jalr	-1562(ra) # 80000540 <panic>

0000000080002b62 <fetchaddr>:
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	e04a                	sd	s2,0(sp)
    80002b6c:	1000                	addi	s0,sp,32
    80002b6e:	84aa                	mv	s1,a0
    80002b70:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	eb2080e7          	jalr	-334(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b7a:	653c                	ld	a5,72(a0)
    80002b7c:	02f4f863          	bgeu	s1,a5,80002bac <fetchaddr+0x4a>
    80002b80:	00848713          	addi	a4,s1,8
    80002b84:	02e7e663          	bltu	a5,a4,80002bb0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b88:	46a1                	li	a3,8
    80002b8a:	8626                	mv	a2,s1
    80002b8c:	85ca                	mv	a1,s2
    80002b8e:	6928                	ld	a0,80(a0)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	be0080e7          	jalr	-1056(ra) # 80001770 <copyin>
    80002b98:	00a03533          	snez	a0,a0
    80002b9c:	40a00533          	neg	a0,a0
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
    return -1;
    80002bac:	557d                	li	a0,-1
    80002bae:	bfcd                	j	80002ba0 <fetchaddr+0x3e>
    80002bb0:	557d                	li	a0,-1
    80002bb2:	b7fd                	j	80002ba0 <fetchaddr+0x3e>

0000000080002bb4 <fetchstr>:
{
    80002bb4:	7179                	addi	sp,sp,-48
    80002bb6:	f406                	sd	ra,40(sp)
    80002bb8:	f022                	sd	s0,32(sp)
    80002bba:	ec26                	sd	s1,24(sp)
    80002bbc:	e84a                	sd	s2,16(sp)
    80002bbe:	e44e                	sd	s3,8(sp)
    80002bc0:	1800                	addi	s0,sp,48
    80002bc2:	892a                	mv	s2,a0
    80002bc4:	84ae                	mv	s1,a1
    80002bc6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	e5c080e7          	jalr	-420(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bd0:	86ce                	mv	a3,s3
    80002bd2:	864a                	mv	a2,s2
    80002bd4:	85a6                	mv	a1,s1
    80002bd6:	6928                	ld	a0,80(a0)
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	c26080e7          	jalr	-986(ra) # 800017fe <copyinstr>
    80002be0:	00054e63          	bltz	a0,80002bfc <fetchstr+0x48>
  return strlen(buf);
    80002be4:	8526                	mv	a0,s1
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	2d8080e7          	jalr	728(ra) # 80000ebe <strlen>
}
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	69a2                	ld	s3,8(sp)
    80002bf8:	6145                	addi	sp,sp,48
    80002bfa:	8082                	ret
    return -1;
    80002bfc:	557d                	li	a0,-1
    80002bfe:	bfc5                	j	80002bee <fetchstr+0x3a>

0000000080002c00 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	eee080e7          	jalr	-274(ra) # 80002afa <argraw>
    80002c14:	c088                	sw	a0,0(s1)
}
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6105                	addi	sp,sp,32
    80002c1e:	8082                	ret

0000000080002c20 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c20:	1101                	addi	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	e426                	sd	s1,8(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	ece080e7          	jalr	-306(ra) # 80002afa <argraw>
    80002c34:	e088                	sd	a0,0(s1)
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	64a2                	ld	s1,8(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c40:	7179                	addi	sp,sp,-48
    80002c42:	f406                	sd	ra,40(sp)
    80002c44:	f022                	sd	s0,32(sp)
    80002c46:	ec26                	sd	s1,24(sp)
    80002c48:	e84a                	sd	s2,16(sp)
    80002c4a:	1800                	addi	s0,sp,48
    80002c4c:	84ae                	mv	s1,a1
    80002c4e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c50:	fd840593          	addi	a1,s0,-40
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	fcc080e7          	jalr	-52(ra) # 80002c20 <argaddr>
  return fetchstr(addr, buf, max);
    80002c5c:	864a                	mv	a2,s2
    80002c5e:	85a6                	mv	a1,s1
    80002c60:	fd843503          	ld	a0,-40(s0)
    80002c64:	00000097          	auipc	ra,0x0
    80002c68:	f50080e7          	jalr	-176(ra) # 80002bb4 <fetchstr>
}
    80002c6c:	70a2                	ld	ra,40(sp)
    80002c6e:	7402                	ld	s0,32(sp)
    80002c70:	64e2                	ld	s1,24(sp)
    80002c72:	6942                	ld	s2,16(sp)
    80002c74:	6145                	addi	sp,sp,48
    80002c76:	8082                	ret

0000000080002c78 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	e426                	sd	s1,8(sp)
    80002c80:	e04a                	sd	s2,0(sp)
    80002c82:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	da0080e7          	jalr	-608(ra) # 80001a24 <myproc>
    80002c8c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c8e:	05853903          	ld	s2,88(a0)
    80002c92:	0a893783          	ld	a5,168(s2)
    80002c96:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c9a:	37fd                	addiw	a5,a5,-1
    80002c9c:	4751                	li	a4,20
    80002c9e:	00f76f63          	bltu	a4,a5,80002cbc <syscall+0x44>
    80002ca2:	00369713          	slli	a4,a3,0x3
    80002ca6:	00005797          	auipc	a5,0x5
    80002caa:	7b278793          	addi	a5,a5,1970 # 80008458 <syscalls>
    80002cae:	97ba                	add	a5,a5,a4
    80002cb0:	639c                	ld	a5,0(a5)
    80002cb2:	c789                	beqz	a5,80002cbc <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cb4:	9782                	jalr	a5
    80002cb6:	06a93823          	sd	a0,112(s2)
    80002cba:	a839                	j	80002cd8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cbc:	15848613          	addi	a2,s1,344
    80002cc0:	588c                	lw	a1,48(s1)
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	75e50513          	addi	a0,a0,1886 # 80008420 <states.0+0x150>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	8c0080e7          	jalr	-1856(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cd2:	6cbc                	ld	a5,88(s1)
    80002cd4:	577d                	li	a4,-1
    80002cd6:	fbb8                	sd	a4,112(a5)
  }
}
    80002cd8:	60e2                	ld	ra,24(sp)
    80002cda:	6442                	ld	s0,16(sp)
    80002cdc:	64a2                	ld	s1,8(sp)
    80002cde:	6902                	ld	s2,0(sp)
    80002ce0:	6105                	addi	sp,sp,32
    80002ce2:	8082                	ret

0000000080002ce4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cec:	fec40593          	addi	a1,s0,-20
    80002cf0:	4501                	li	a0,0
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	f0e080e7          	jalr	-242(ra) # 80002c00 <argint>
  exit(n);
    80002cfa:	fec42503          	lw	a0,-20(s0)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	530080e7          	jalr	1328(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002d06:	4501                	li	a0,0
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d10:	1141                	addi	sp,sp,-16
    80002d12:	e406                	sd	ra,8(sp)
    80002d14:	e022                	sd	s0,0(sp)
    80002d16:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	d0c080e7          	jalr	-756(ra) # 80001a24 <myproc>
}
    80002d20:	5908                	lw	a0,48(a0)
    80002d22:	60a2                	ld	ra,8(sp)
    80002d24:	6402                	ld	s0,0(sp)
    80002d26:	0141                	addi	sp,sp,16
    80002d28:	8082                	ret

0000000080002d2a <sys_fork>:

uint64
sys_fork(void)
{
    80002d2a:	1141                	addi	sp,sp,-16
    80002d2c:	e406                	sd	ra,8(sp)
    80002d2e:	e022                	sd	s0,0(sp)
    80002d30:	0800                	addi	s0,sp,16
  return fork();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	0d6080e7          	jalr	214(ra) # 80001e08 <fork>
}
    80002d3a:	60a2                	ld	ra,8(sp)
    80002d3c:	6402                	ld	s0,0(sp)
    80002d3e:	0141                	addi	sp,sp,16
    80002d40:	8082                	ret

0000000080002d42 <sys_wait>:

uint64
sys_wait(void)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d4a:	fe840593          	addi	a1,s0,-24
    80002d4e:	4501                	li	a0,0
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	ed0080e7          	jalr	-304(ra) # 80002c20 <argaddr>
  return wait(p);
    80002d58:	fe843503          	ld	a0,-24(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	678080e7          	jalr	1656(ra) # 800023d4 <wait>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d6c:	7179                	addi	sp,sp,-48
    80002d6e:	f406                	sd	ra,40(sp)
    80002d70:	f022                	sd	s0,32(sp)
    80002d72:	ec26                	sd	s1,24(sp)
    80002d74:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d76:	fdc40593          	addi	a1,s0,-36
    80002d7a:	4501                	li	a0,0
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	e84080e7          	jalr	-380(ra) # 80002c00 <argint>
  addr = myproc()->sz;
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	ca0080e7          	jalr	-864(ra) # 80001a24 <myproc>
    80002d8c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d8e:	fdc42503          	lw	a0,-36(s0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	01a080e7          	jalr	26(ra) # 80001dac <growproc>
    80002d9a:	00054863          	bltz	a0,80002daa <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d9e:	8526                	mv	a0,s1
    80002da0:	70a2                	ld	ra,40(sp)
    80002da2:	7402                	ld	s0,32(sp)
    80002da4:	64e2                	ld	s1,24(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret
    return -1;
    80002daa:	54fd                	li	s1,-1
    80002dac:	bfcd                	j	80002d9e <sys_sbrk+0x32>

0000000080002dae <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dae:	7139                	addi	sp,sp,-64
    80002db0:	fc06                	sd	ra,56(sp)
    80002db2:	f822                	sd	s0,48(sp)
    80002db4:	f426                	sd	s1,40(sp)
    80002db6:	f04a                	sd	s2,32(sp)
    80002db8:	ec4e                	sd	s3,24(sp)
    80002dba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dbc:	fcc40593          	addi	a1,s0,-52
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	e3e080e7          	jalr	-450(ra) # 80002c00 <argint>
  acquire(&tickslock);
    80002dca:	00014517          	auipc	a0,0x14
    80002dce:	e9650513          	addi	a0,a0,-362 # 80016c60 <tickslock>
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	e76080e7          	jalr	-394(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002dda:	00006917          	auipc	s2,0x6
    80002dde:	be692903          	lw	s2,-1050(s2) # 800089c0 <ticks>
  while(ticks - ticks0 < n){
    80002de2:	fcc42783          	lw	a5,-52(s0)
    80002de6:	cf9d                	beqz	a5,80002e24 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002de8:	00014997          	auipc	s3,0x14
    80002dec:	e7898993          	addi	s3,s3,-392 # 80016c60 <tickslock>
    80002df0:	00006497          	auipc	s1,0x6
    80002df4:	bd048493          	addi	s1,s1,-1072 # 800089c0 <ticks>
    if(killed(myproc())){
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	c2c080e7          	jalr	-980(ra) # 80001a24 <myproc>
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	5a2080e7          	jalr	1442(ra) # 800023a2 <killed>
    80002e08:	ed15                	bnez	a0,80002e44 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e0a:	85ce                	mv	a1,s3
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	2ec080e7          	jalr	748(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002e16:	409c                	lw	a5,0(s1)
    80002e18:	412787bb          	subw	a5,a5,s2
    80002e1c:	fcc42703          	lw	a4,-52(s0)
    80002e20:	fce7ece3          	bltu	a5,a4,80002df8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e24:	00014517          	auipc	a0,0x14
    80002e28:	e3c50513          	addi	a0,a0,-452 # 80016c60 <tickslock>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	ed0080e7          	jalr	-304(ra) # 80000cfc <release>
  return 0;
    80002e34:	4501                	li	a0,0
}
    80002e36:	70e2                	ld	ra,56(sp)
    80002e38:	7442                	ld	s0,48(sp)
    80002e3a:	74a2                	ld	s1,40(sp)
    80002e3c:	7902                	ld	s2,32(sp)
    80002e3e:	69e2                	ld	s3,24(sp)
    80002e40:	6121                	addi	sp,sp,64
    80002e42:	8082                	ret
      release(&tickslock);
    80002e44:	00014517          	auipc	a0,0x14
    80002e48:	e1c50513          	addi	a0,a0,-484 # 80016c60 <tickslock>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	eb0080e7          	jalr	-336(ra) # 80000cfc <release>
      return -1;
    80002e54:	557d                	li	a0,-1
    80002e56:	b7c5                	j	80002e36 <sys_sleep+0x88>

0000000080002e58 <sys_kill>:

uint64
sys_kill(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e60:	fec40593          	addi	a1,s0,-20
    80002e64:	4501                	li	a0,0
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	d9a080e7          	jalr	-614(ra) # 80002c00 <argint>
  return kill(pid);
    80002e6e:	fec42503          	lw	a0,-20(s0)
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	492080e7          	jalr	1170(ra) # 80002304 <kill>
}
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e8c:	00014517          	auipc	a0,0x14
    80002e90:	dd450513          	addi	a0,a0,-556 # 80016c60 <tickslock>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	db4080e7          	jalr	-588(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e9c:	00006497          	auipc	s1,0x6
    80002ea0:	b244a483          	lw	s1,-1244(s1) # 800089c0 <ticks>
  release(&tickslock);
    80002ea4:	00014517          	auipc	a0,0x14
    80002ea8:	dbc50513          	addi	a0,a0,-580 # 80016c60 <tickslock>
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	e50080e7          	jalr	-432(ra) # 80000cfc <release>
  return xticks;
}
    80002eb4:	02049513          	slli	a0,s1,0x20
    80002eb8:	9101                	srli	a0,a0,0x20
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	64a2                	ld	s1,8(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ec4:	7179                	addi	sp,sp,-48
    80002ec6:	f406                	sd	ra,40(sp)
    80002ec8:	f022                	sd	s0,32(sp)
    80002eca:	ec26                	sd	s1,24(sp)
    80002ecc:	e84a                	sd	s2,16(sp)
    80002ece:	e44e                	sd	s3,8(sp)
    80002ed0:	e052                	sd	s4,0(sp)
    80002ed2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ed4:	00005597          	auipc	a1,0x5
    80002ed8:	63458593          	addi	a1,a1,1588 # 80008508 <syscalls+0xb0>
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	d9c50513          	addi	a0,a0,-612 # 80016c78 <bcache>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	cd4080e7          	jalr	-812(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eec:	0001c797          	auipc	a5,0x1c
    80002ef0:	d8c78793          	addi	a5,a5,-628 # 8001ec78 <bcache+0x8000>
    80002ef4:	0001c717          	auipc	a4,0x1c
    80002ef8:	fec70713          	addi	a4,a4,-20 # 8001eee0 <bcache+0x8268>
    80002efc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f00:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f04:	00014497          	auipc	s1,0x14
    80002f08:	d8c48493          	addi	s1,s1,-628 # 80016c90 <bcache+0x18>
    b->next = bcache.head.next;
    80002f0c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f0e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f10:	00005a17          	auipc	s4,0x5
    80002f14:	600a0a13          	addi	s4,s4,1536 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f18:	2b893783          	ld	a5,696(s2)
    80002f1c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f1e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f22:	85d2                	mv	a1,s4
    80002f24:	01048513          	addi	a0,s1,16
    80002f28:	00001097          	auipc	ra,0x1
    80002f2c:	496080e7          	jalr	1174(ra) # 800043be <initsleeplock>
    bcache.head.next->prev = b;
    80002f30:	2b893783          	ld	a5,696(s2)
    80002f34:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f36:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f3a:	45848493          	addi	s1,s1,1112
    80002f3e:	fd349de3          	bne	s1,s3,80002f18 <binit+0x54>
  }
}
    80002f42:	70a2                	ld	ra,40(sp)
    80002f44:	7402                	ld	s0,32(sp)
    80002f46:	64e2                	ld	s1,24(sp)
    80002f48:	6942                	ld	s2,16(sp)
    80002f4a:	69a2                	ld	s3,8(sp)
    80002f4c:	6a02                	ld	s4,0(sp)
    80002f4e:	6145                	addi	sp,sp,48
    80002f50:	8082                	ret

0000000080002f52 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	1800                	addi	s0,sp,48
    80002f60:	892a                	mv	s2,a0
    80002f62:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f64:	00014517          	auipc	a0,0x14
    80002f68:	d1450513          	addi	a0,a0,-748 # 80016c78 <bcache>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	cdc080e7          	jalr	-804(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f74:	0001c497          	auipc	s1,0x1c
    80002f78:	fbc4b483          	ld	s1,-68(s1) # 8001ef30 <bcache+0x82b8>
    80002f7c:	0001c797          	auipc	a5,0x1c
    80002f80:	f6478793          	addi	a5,a5,-156 # 8001eee0 <bcache+0x8268>
    80002f84:	02f48f63          	beq	s1,a5,80002fc2 <bread+0x70>
    80002f88:	873e                	mv	a4,a5
    80002f8a:	a021                	j	80002f92 <bread+0x40>
    80002f8c:	68a4                	ld	s1,80(s1)
    80002f8e:	02e48a63          	beq	s1,a4,80002fc2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f92:	449c                	lw	a5,8(s1)
    80002f94:	ff279ce3          	bne	a5,s2,80002f8c <bread+0x3a>
    80002f98:	44dc                	lw	a5,12(s1)
    80002f9a:	ff3799e3          	bne	a5,s3,80002f8c <bread+0x3a>
      b->refcnt++;
    80002f9e:	40bc                	lw	a5,64(s1)
    80002fa0:	2785                	addiw	a5,a5,1
    80002fa2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa4:	00014517          	auipc	a0,0x14
    80002fa8:	cd450513          	addi	a0,a0,-812 # 80016c78 <bcache>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fb4:	01048513          	addi	a0,s1,16
    80002fb8:	00001097          	auipc	ra,0x1
    80002fbc:	440080e7          	jalr	1088(ra) # 800043f8 <acquiresleep>
      return b;
    80002fc0:	a8b9                	j	8000301e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc2:	0001c497          	auipc	s1,0x1c
    80002fc6:	f664b483          	ld	s1,-154(s1) # 8001ef28 <bcache+0x82b0>
    80002fca:	0001c797          	auipc	a5,0x1c
    80002fce:	f1678793          	addi	a5,a5,-234 # 8001eee0 <bcache+0x8268>
    80002fd2:	00f48863          	beq	s1,a5,80002fe2 <bread+0x90>
    80002fd6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd8:	40bc                	lw	a5,64(s1)
    80002fda:	cf81                	beqz	a5,80002ff2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fdc:	64a4                	ld	s1,72(s1)
    80002fde:	fee49de3          	bne	s1,a4,80002fd8 <bread+0x86>
  panic("bget: no buffers");
    80002fe2:	00005517          	auipc	a0,0x5
    80002fe6:	53650513          	addi	a0,a0,1334 # 80008518 <syscalls+0xc0>
    80002fea:	ffffd097          	auipc	ra,0xffffd
    80002fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
      b->dev = dev;
    80002ff2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ff6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ffa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ffe:	4785                	li	a5,1
    80003000:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	c7650513          	addi	a0,a0,-906 # 80016c78 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	cf2080e7          	jalr	-782(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80003012:	01048513          	addi	a0,s1,16
    80003016:	00001097          	auipc	ra,0x1
    8000301a:	3e2080e7          	jalr	994(ra) # 800043f8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000301e:	409c                	lw	a5,0(s1)
    80003020:	cb89                	beqz	a5,80003032 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003022:	8526                	mv	a0,s1
    80003024:	70a2                	ld	ra,40(sp)
    80003026:	7402                	ld	s0,32(sp)
    80003028:	64e2                	ld	s1,24(sp)
    8000302a:	6942                	ld	s2,16(sp)
    8000302c:	69a2                	ld	s3,8(sp)
    8000302e:	6145                	addi	sp,sp,48
    80003030:	8082                	ret
    virtio_disk_rw(b, 0);
    80003032:	4581                	li	a1,0
    80003034:	8526                	mv	a0,s1
    80003036:	00003097          	auipc	ra,0x3
    8000303a:	19e080e7          	jalr	414(ra) # 800061d4 <virtio_disk_rw>
    b->valid = 1;
    8000303e:	4785                	li	a5,1
    80003040:	c09c                	sw	a5,0(s1)
  return b;
    80003042:	b7c5                	j	80003022 <bread+0xd0>

0000000080003044 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	1000                	addi	s0,sp,32
    8000304e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003050:	0541                	addi	a0,a0,16
    80003052:	00001097          	auipc	ra,0x1
    80003056:	440080e7          	jalr	1088(ra) # 80004492 <holdingsleep>
    8000305a:	cd01                	beqz	a0,80003072 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000305c:	4585                	li	a1,1
    8000305e:	8526                	mv	a0,s1
    80003060:	00003097          	auipc	ra,0x3
    80003064:	174080e7          	jalr	372(ra) # 800061d4 <virtio_disk_rw>
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret
    panic("bwrite");
    80003072:	00005517          	auipc	a0,0x5
    80003076:	4be50513          	addi	a0,a0,1214 # 80008530 <syscalls+0xd8>
    8000307a:	ffffd097          	auipc	ra,0xffffd
    8000307e:	4c6080e7          	jalr	1222(ra) # 80000540 <panic>

0000000080003082 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	e04a                	sd	s2,0(sp)
    8000308c:	1000                	addi	s0,sp,32
    8000308e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003090:	01050913          	addi	s2,a0,16
    80003094:	854a                	mv	a0,s2
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	3fc080e7          	jalr	1020(ra) # 80004492 <holdingsleep>
    8000309e:	c925                	beqz	a0,8000310e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800030a0:	854a                	mv	a0,s2
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	3ac080e7          	jalr	940(ra) # 8000444e <releasesleep>

  acquire(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	bce50513          	addi	a0,a0,-1074 # 80016c78 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	b96080e7          	jalr	-1130(ra) # 80000c48 <acquire>
  b->refcnt--;
    800030ba:	40bc                	lw	a5,64(s1)
    800030bc:	37fd                	addiw	a5,a5,-1
    800030be:	0007871b          	sext.w	a4,a5
    800030c2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030c4:	e71d                	bnez	a4,800030f2 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c6:	68b8                	ld	a4,80(s1)
    800030c8:	64bc                	ld	a5,72(s1)
    800030ca:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030cc:	68b8                	ld	a4,80(s1)
    800030ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030d0:	0001c797          	auipc	a5,0x1c
    800030d4:	ba878793          	addi	a5,a5,-1112 # 8001ec78 <bcache+0x8000>
    800030d8:	2b87b703          	ld	a4,696(a5)
    800030dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030de:	0001c717          	auipc	a4,0x1c
    800030e2:	e0270713          	addi	a4,a4,-510 # 8001eee0 <bcache+0x8268>
    800030e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e8:	2b87b703          	ld	a4,696(a5)
    800030ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	b8650513          	addi	a0,a0,-1146 # 80016c78 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	c02080e7          	jalr	-1022(ra) # 80000cfc <release>
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	64a2                	ld	s1,8(sp)
    80003108:	6902                	ld	s2,0(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret
    panic("brelse");
    8000310e:	00005517          	auipc	a0,0x5
    80003112:	42a50513          	addi	a0,a0,1066 # 80008538 <syscalls+0xe0>
    80003116:	ffffd097          	auipc	ra,0xffffd
    8000311a:	42a080e7          	jalr	1066(ra) # 80000540 <panic>

000000008000311e <bpin>:

void
bpin(struct buf *b) {
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312a:	00014517          	auipc	a0,0x14
    8000312e:	b4e50513          	addi	a0,a0,-1202 # 80016c78 <bcache>
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	b16080e7          	jalr	-1258(ra) # 80000c48 <acquire>
  b->refcnt++;
    8000313a:	40bc                	lw	a5,64(s1)
    8000313c:	2785                	addiw	a5,a5,1
    8000313e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003140:	00014517          	auipc	a0,0x14
    80003144:	b3850513          	addi	a0,a0,-1224 # 80016c78 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	bb4080e7          	jalr	-1100(ra) # 80000cfc <release>
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret

000000008000315a <bunpin>:

void
bunpin(struct buf *b) {
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	e426                	sd	s1,8(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003166:	00014517          	auipc	a0,0x14
    8000316a:	b1250513          	addi	a0,a0,-1262 # 80016c78 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	ada080e7          	jalr	-1318(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003176:	40bc                	lw	a5,64(s1)
    80003178:	37fd                	addiw	a5,a5,-1
    8000317a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	afc50513          	addi	a0,a0,-1284 # 80016c78 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b78080e7          	jalr	-1160(ra) # 80000cfc <release>
}
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a4:	00d5d59b          	srliw	a1,a1,0xd
    800031a8:	0001c797          	auipc	a5,0x1c
    800031ac:	1ac7a783          	lw	a5,428(a5) # 8001f354 <sb+0x1c>
    800031b0:	9dbd                	addw	a1,a1,a5
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	da0080e7          	jalr	-608(ra) # 80002f52 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031ba:	0074f713          	andi	a4,s1,7
    800031be:	4785                	li	a5,1
    800031c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c4:	14ce                	slli	s1,s1,0x33
    800031c6:	90d9                	srli	s1,s1,0x36
    800031c8:	00950733          	add	a4,a0,s1
    800031cc:	05874703          	lbu	a4,88(a4)
    800031d0:	00e7f6b3          	and	a3,a5,a4
    800031d4:	c69d                	beqz	a3,80003202 <bfree+0x6c>
    800031d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031d8:	94aa                	add	s1,s1,a0
    800031da:	fff7c793          	not	a5,a5
    800031de:	8f7d                	and	a4,a4,a5
    800031e0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	0f6080e7          	jalr	246(ra) # 800042da <log_write>
  brelse(bp);
    800031ec:	854a                	mv	a0,s2
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	e94080e7          	jalr	-364(ra) # 80003082 <brelse>
}
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	64a2                	ld	s1,8(sp)
    800031fc:	6902                	ld	s2,0(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret
    panic("freeing free block");
    80003202:	00005517          	auipc	a0,0x5
    80003206:	33e50513          	addi	a0,a0,830 # 80008540 <syscalls+0xe8>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	336080e7          	jalr	822(ra) # 80000540 <panic>

0000000080003212 <balloc>:
{
    80003212:	711d                	addi	sp,sp,-96
    80003214:	ec86                	sd	ra,88(sp)
    80003216:	e8a2                	sd	s0,80(sp)
    80003218:	e4a6                	sd	s1,72(sp)
    8000321a:	e0ca                	sd	s2,64(sp)
    8000321c:	fc4e                	sd	s3,56(sp)
    8000321e:	f852                	sd	s4,48(sp)
    80003220:	f456                	sd	s5,40(sp)
    80003222:	f05a                	sd	s6,32(sp)
    80003224:	ec5e                	sd	s7,24(sp)
    80003226:	e862                	sd	s8,16(sp)
    80003228:	e466                	sd	s9,8(sp)
    8000322a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000322c:	0001c797          	auipc	a5,0x1c
    80003230:	1107a783          	lw	a5,272(a5) # 8001f33c <sb+0x4>
    80003234:	cff5                	beqz	a5,80003330 <balloc+0x11e>
    80003236:	8baa                	mv	s7,a0
    80003238:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000323a:	0001cb17          	auipc	s6,0x1c
    8000323e:	0feb0b13          	addi	s6,s6,254 # 8001f338 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003242:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003244:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003246:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003248:	6c89                	lui	s9,0x2
    8000324a:	a061                	j	800032d2 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000324c:	97ca                	add	a5,a5,s2
    8000324e:	8e55                	or	a2,a2,a3
    80003250:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003254:	854a                	mv	a0,s2
    80003256:	00001097          	auipc	ra,0x1
    8000325a:	084080e7          	jalr	132(ra) # 800042da <log_write>
        brelse(bp);
    8000325e:	854a                	mv	a0,s2
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e22080e7          	jalr	-478(ra) # 80003082 <brelse>
  bp = bread(dev, bno);
    80003268:	85a6                	mv	a1,s1
    8000326a:	855e                	mv	a0,s7
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	ce6080e7          	jalr	-794(ra) # 80002f52 <bread>
    80003274:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003276:	40000613          	li	a2,1024
    8000327a:	4581                	li	a1,0
    8000327c:	05850513          	addi	a0,a0,88
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	ac4080e7          	jalr	-1340(ra) # 80000d44 <memset>
  log_write(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	050080e7          	jalr	80(ra) # 800042da <log_write>
  brelse(bp);
    80003292:	854a                	mv	a0,s2
    80003294:	00000097          	auipc	ra,0x0
    80003298:	dee080e7          	jalr	-530(ra) # 80003082 <brelse>
}
    8000329c:	8526                	mv	a0,s1
    8000329e:	60e6                	ld	ra,88(sp)
    800032a0:	6446                	ld	s0,80(sp)
    800032a2:	64a6                	ld	s1,72(sp)
    800032a4:	6906                	ld	s2,64(sp)
    800032a6:	79e2                	ld	s3,56(sp)
    800032a8:	7a42                	ld	s4,48(sp)
    800032aa:	7aa2                	ld	s5,40(sp)
    800032ac:	7b02                	ld	s6,32(sp)
    800032ae:	6be2                	ld	s7,24(sp)
    800032b0:	6c42                	ld	s8,16(sp)
    800032b2:	6ca2                	ld	s9,8(sp)
    800032b4:	6125                	addi	sp,sp,96
    800032b6:	8082                	ret
    brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	dc8080e7          	jalr	-568(ra) # 80003082 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	015c87bb          	addw	a5,s9,s5
    800032c6:	00078a9b          	sext.w	s5,a5
    800032ca:	004b2703          	lw	a4,4(s6)
    800032ce:	06eaf163          	bgeu	s5,a4,80003330 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032d2:	41fad79b          	sraiw	a5,s5,0x1f
    800032d6:	0137d79b          	srliw	a5,a5,0x13
    800032da:	015787bb          	addw	a5,a5,s5
    800032de:	40d7d79b          	sraiw	a5,a5,0xd
    800032e2:	01cb2583          	lw	a1,28(s6)
    800032e6:	9dbd                	addw	a1,a1,a5
    800032e8:	855e                	mv	a0,s7
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	c68080e7          	jalr	-920(ra) # 80002f52 <bread>
    800032f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f4:	004b2503          	lw	a0,4(s6)
    800032f8:	000a849b          	sext.w	s1,s5
    800032fc:	8762                	mv	a4,s8
    800032fe:	faa4fde3          	bgeu	s1,a0,800032b8 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003302:	00777693          	andi	a3,a4,7
    80003306:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000330a:	41f7579b          	sraiw	a5,a4,0x1f
    8000330e:	01d7d79b          	srliw	a5,a5,0x1d
    80003312:	9fb9                	addw	a5,a5,a4
    80003314:	4037d79b          	sraiw	a5,a5,0x3
    80003318:	00f90633          	add	a2,s2,a5
    8000331c:	05864603          	lbu	a2,88(a2)
    80003320:	00c6f5b3          	and	a1,a3,a2
    80003324:	d585                	beqz	a1,8000324c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003326:	2705                	addiw	a4,a4,1
    80003328:	2485                	addiw	s1,s1,1
    8000332a:	fd471ae3          	bne	a4,s4,800032fe <balloc+0xec>
    8000332e:	b769                	j	800032b8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003330:	00005517          	auipc	a0,0x5
    80003334:	22850513          	addi	a0,a0,552 # 80008558 <syscalls+0x100>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	252080e7          	jalr	594(ra) # 8000058a <printf>
  return 0;
    80003340:	4481                	li	s1,0
    80003342:	bfa9                	j	8000329c <balloc+0x8a>

0000000080003344 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003344:	7179                	addi	sp,sp,-48
    80003346:	f406                	sd	ra,40(sp)
    80003348:	f022                	sd	s0,32(sp)
    8000334a:	ec26                	sd	s1,24(sp)
    8000334c:	e84a                	sd	s2,16(sp)
    8000334e:	e44e                	sd	s3,8(sp)
    80003350:	e052                	sd	s4,0(sp)
    80003352:	1800                	addi	s0,sp,48
    80003354:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003356:	47ad                	li	a5,11
    80003358:	02b7e863          	bltu	a5,a1,80003388 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000335c:	02059793          	slli	a5,a1,0x20
    80003360:	01e7d593          	srli	a1,a5,0x1e
    80003364:	00b504b3          	add	s1,a0,a1
    80003368:	0504a903          	lw	s2,80(s1)
    8000336c:	06091e63          	bnez	s2,800033e8 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003370:	4108                	lw	a0,0(a0)
    80003372:	00000097          	auipc	ra,0x0
    80003376:	ea0080e7          	jalr	-352(ra) # 80003212 <balloc>
    8000337a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000337e:	06090563          	beqz	s2,800033e8 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003382:	0524a823          	sw	s2,80(s1)
    80003386:	a08d                	j	800033e8 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003388:	ff45849b          	addiw	s1,a1,-12
    8000338c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003390:	0ff00793          	li	a5,255
    80003394:	08e7e563          	bltu	a5,a4,8000341e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003398:	08052903          	lw	s2,128(a0)
    8000339c:	00091d63          	bnez	s2,800033b6 <bmap+0x72>
      addr = balloc(ip->dev);
    800033a0:	4108                	lw	a0,0(a0)
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	e70080e7          	jalr	-400(ra) # 80003212 <balloc>
    800033aa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ae:	02090d63          	beqz	s2,800033e8 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033b2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033b6:	85ca                	mv	a1,s2
    800033b8:	0009a503          	lw	a0,0(s3)
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	b96080e7          	jalr	-1130(ra) # 80002f52 <bread>
    800033c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ca:	02049713          	slli	a4,s1,0x20
    800033ce:	01e75593          	srli	a1,a4,0x1e
    800033d2:	00b784b3          	add	s1,a5,a1
    800033d6:	0004a903          	lw	s2,0(s1)
    800033da:	02090063          	beqz	s2,800033fa <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033de:	8552                	mv	a0,s4
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	ca2080e7          	jalr	-862(ra) # 80003082 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e8:	854a                	mv	a0,s2
    800033ea:	70a2                	ld	ra,40(sp)
    800033ec:	7402                	ld	s0,32(sp)
    800033ee:	64e2                	ld	s1,24(sp)
    800033f0:	6942                	ld	s2,16(sp)
    800033f2:	69a2                	ld	s3,8(sp)
    800033f4:	6a02                	ld	s4,0(sp)
    800033f6:	6145                	addi	sp,sp,48
    800033f8:	8082                	ret
      addr = balloc(ip->dev);
    800033fa:	0009a503          	lw	a0,0(s3)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e14080e7          	jalr	-492(ra) # 80003212 <balloc>
    80003406:	0005091b          	sext.w	s2,a0
      if(addr){
    8000340a:	fc090ae3          	beqz	s2,800033de <bmap+0x9a>
        a[bn] = addr;
    8000340e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003412:	8552                	mv	a0,s4
    80003414:	00001097          	auipc	ra,0x1
    80003418:	ec6080e7          	jalr	-314(ra) # 800042da <log_write>
    8000341c:	b7c9                	j	800033de <bmap+0x9a>
  panic("bmap: out of range");
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	15250513          	addi	a0,a0,338 # 80008570 <syscalls+0x118>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	11a080e7          	jalr	282(ra) # 80000540 <panic>

000000008000342e <iget>:
{
    8000342e:	7179                	addi	sp,sp,-48
    80003430:	f406                	sd	ra,40(sp)
    80003432:	f022                	sd	s0,32(sp)
    80003434:	ec26                	sd	s1,24(sp)
    80003436:	e84a                	sd	s2,16(sp)
    80003438:	e44e                	sd	s3,8(sp)
    8000343a:	e052                	sd	s4,0(sp)
    8000343c:	1800                	addi	s0,sp,48
    8000343e:	89aa                	mv	s3,a0
    80003440:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003442:	0001c517          	auipc	a0,0x1c
    80003446:	f1650513          	addi	a0,a0,-234 # 8001f358 <itable>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	7fe080e7          	jalr	2046(ra) # 80000c48 <acquire>
  empty = 0;
    80003452:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003454:	0001c497          	auipc	s1,0x1c
    80003458:	f1c48493          	addi	s1,s1,-228 # 8001f370 <itable+0x18>
    8000345c:	0001e697          	auipc	a3,0x1e
    80003460:	9a468693          	addi	a3,a3,-1628 # 80020e00 <log>
    80003464:	a039                	j	80003472 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003466:	02090b63          	beqz	s2,8000349c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346a:	08848493          	addi	s1,s1,136
    8000346e:	02d48a63          	beq	s1,a3,800034a2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003472:	449c                	lw	a5,8(s1)
    80003474:	fef059e3          	blez	a5,80003466 <iget+0x38>
    80003478:	4098                	lw	a4,0(s1)
    8000347a:	ff3716e3          	bne	a4,s3,80003466 <iget+0x38>
    8000347e:	40d8                	lw	a4,4(s1)
    80003480:	ff4713e3          	bne	a4,s4,80003466 <iget+0x38>
      ip->ref++;
    80003484:	2785                	addiw	a5,a5,1
    80003486:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003488:	0001c517          	auipc	a0,0x1c
    8000348c:	ed050513          	addi	a0,a0,-304 # 8001f358 <itable>
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
      return ip;
    80003498:	8926                	mv	s2,s1
    8000349a:	a03d                	j	800034c8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349c:	f7f9                	bnez	a5,8000346a <iget+0x3c>
    8000349e:	8926                	mv	s2,s1
    800034a0:	b7e9                	j	8000346a <iget+0x3c>
  if(empty == 0)
    800034a2:	02090c63          	beqz	s2,800034da <iget+0xac>
  ip->dev = dev;
    800034a6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034aa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ae:	4785                	li	a5,1
    800034b0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034b4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034b8:	0001c517          	auipc	a0,0x1c
    800034bc:	ea050513          	addi	a0,a0,-352 # 8001f358 <itable>
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	83c080e7          	jalr	-1988(ra) # 80000cfc <release>
}
    800034c8:	854a                	mv	a0,s2
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6a02                	ld	s4,0(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
    panic("iget: no inodes");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	0ae50513          	addi	a0,a0,174 # 80008588 <syscalls+0x130>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05e080e7          	jalr	94(ra) # 80000540 <panic>

00000000800034ea <fsinit>:
fsinit(int dev) {
    800034ea:	7179                	addi	sp,sp,-48
    800034ec:	f406                	sd	ra,40(sp)
    800034ee:	f022                	sd	s0,32(sp)
    800034f0:	ec26                	sd	s1,24(sp)
    800034f2:	e84a                	sd	s2,16(sp)
    800034f4:	e44e                	sd	s3,8(sp)
    800034f6:	1800                	addi	s0,sp,48
    800034f8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034fa:	4585                	li	a1,1
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	a56080e7          	jalr	-1450(ra) # 80002f52 <bread>
    80003504:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003506:	0001c997          	auipc	s3,0x1c
    8000350a:	e3298993          	addi	s3,s3,-462 # 8001f338 <sb>
    8000350e:	02000613          	li	a2,32
    80003512:	05850593          	addi	a1,a0,88
    80003516:	854e                	mv	a0,s3
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	888080e7          	jalr	-1912(ra) # 80000da0 <memmove>
  brelse(bp);
    80003520:	8526                	mv	a0,s1
    80003522:	00000097          	auipc	ra,0x0
    80003526:	b60080e7          	jalr	-1184(ra) # 80003082 <brelse>
  if(sb.magic != FSMAGIC)
    8000352a:	0009a703          	lw	a4,0(s3)
    8000352e:	102037b7          	lui	a5,0x10203
    80003532:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003536:	02f71263          	bne	a4,a5,8000355a <fsinit+0x70>
  initlog(dev, &sb);
    8000353a:	0001c597          	auipc	a1,0x1c
    8000353e:	dfe58593          	addi	a1,a1,-514 # 8001f338 <sb>
    80003542:	854a                	mv	a0,s2
    80003544:	00001097          	auipc	ra,0x1
    80003548:	b2c080e7          	jalr	-1236(ra) # 80004070 <initlog>
}
    8000354c:	70a2                	ld	ra,40(sp)
    8000354e:	7402                	ld	s0,32(sp)
    80003550:	64e2                	ld	s1,24(sp)
    80003552:	6942                	ld	s2,16(sp)
    80003554:	69a2                	ld	s3,8(sp)
    80003556:	6145                	addi	sp,sp,48
    80003558:	8082                	ret
    panic("invalid file system");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	03e50513          	addi	a0,a0,62 # 80008598 <syscalls+0x140>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fde080e7          	jalr	-34(ra) # 80000540 <panic>

000000008000356a <iinit>:
{
    8000356a:	7179                	addi	sp,sp,-48
    8000356c:	f406                	sd	ra,40(sp)
    8000356e:	f022                	sd	s0,32(sp)
    80003570:	ec26                	sd	s1,24(sp)
    80003572:	e84a                	sd	s2,16(sp)
    80003574:	e44e                	sd	s3,8(sp)
    80003576:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003578:	00005597          	auipc	a1,0x5
    8000357c:	03858593          	addi	a1,a1,56 # 800085b0 <syscalls+0x158>
    80003580:	0001c517          	auipc	a0,0x1c
    80003584:	dd850513          	addi	a0,a0,-552 # 8001f358 <itable>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	630080e7          	jalr	1584(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003590:	0001c497          	auipc	s1,0x1c
    80003594:	df048493          	addi	s1,s1,-528 # 8001f380 <itable+0x28>
    80003598:	0001e997          	auipc	s3,0x1e
    8000359c:	87898993          	addi	s3,s3,-1928 # 80020e10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035a0:	00005917          	auipc	s2,0x5
    800035a4:	01890913          	addi	s2,s2,24 # 800085b8 <syscalls+0x160>
    800035a8:	85ca                	mv	a1,s2
    800035aa:	8526                	mv	a0,s1
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	e12080e7          	jalr	-494(ra) # 800043be <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035b4:	08848493          	addi	s1,s1,136
    800035b8:	ff3498e3          	bne	s1,s3,800035a8 <iinit+0x3e>
}
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret

00000000800035ca <ialloc>:
{
    800035ca:	7139                	addi	sp,sp,-64
    800035cc:	fc06                	sd	ra,56(sp)
    800035ce:	f822                	sd	s0,48(sp)
    800035d0:	f426                	sd	s1,40(sp)
    800035d2:	f04a                	sd	s2,32(sp)
    800035d4:	ec4e                	sd	s3,24(sp)
    800035d6:	e852                	sd	s4,16(sp)
    800035d8:	e456                	sd	s5,8(sp)
    800035da:	e05a                	sd	s6,0(sp)
    800035dc:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035de:	0001c717          	auipc	a4,0x1c
    800035e2:	d6672703          	lw	a4,-666(a4) # 8001f344 <sb+0xc>
    800035e6:	4785                	li	a5,1
    800035e8:	04e7f863          	bgeu	a5,a4,80003638 <ialloc+0x6e>
    800035ec:	8aaa                	mv	s5,a0
    800035ee:	8b2e                	mv	s6,a1
    800035f0:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f2:	0001ca17          	auipc	s4,0x1c
    800035f6:	d46a0a13          	addi	s4,s4,-698 # 8001f338 <sb>
    800035fa:	00495593          	srli	a1,s2,0x4
    800035fe:	018a2783          	lw	a5,24(s4)
    80003602:	9dbd                	addw	a1,a1,a5
    80003604:	8556                	mv	a0,s5
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	94c080e7          	jalr	-1716(ra) # 80002f52 <bread>
    8000360e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003610:	05850993          	addi	s3,a0,88
    80003614:	00f97793          	andi	a5,s2,15
    80003618:	079a                	slli	a5,a5,0x6
    8000361a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000361c:	00099783          	lh	a5,0(s3)
    80003620:	cf9d                	beqz	a5,8000365e <ialloc+0x94>
    brelse(bp);
    80003622:	00000097          	auipc	ra,0x0
    80003626:	a60080e7          	jalr	-1440(ra) # 80003082 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000362a:	0905                	addi	s2,s2,1
    8000362c:	00ca2703          	lw	a4,12(s4)
    80003630:	0009079b          	sext.w	a5,s2
    80003634:	fce7e3e3          	bltu	a5,a4,800035fa <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	f8850513          	addi	a0,a0,-120 # 800085c0 <syscalls+0x168>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	f4a080e7          	jalr	-182(ra) # 8000058a <printf>
  return 0;
    80003648:	4501                	li	a0,0
}
    8000364a:	70e2                	ld	ra,56(sp)
    8000364c:	7442                	ld	s0,48(sp)
    8000364e:	74a2                	ld	s1,40(sp)
    80003650:	7902                	ld	s2,32(sp)
    80003652:	69e2                	ld	s3,24(sp)
    80003654:	6a42                	ld	s4,16(sp)
    80003656:	6aa2                	ld	s5,8(sp)
    80003658:	6b02                	ld	s6,0(sp)
    8000365a:	6121                	addi	sp,sp,64
    8000365c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000365e:	04000613          	li	a2,64
    80003662:	4581                	li	a1,0
    80003664:	854e                	mv	a0,s3
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	6de080e7          	jalr	1758(ra) # 80000d44 <memset>
      dip->type = type;
    8000366e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003672:	8526                	mv	a0,s1
    80003674:	00001097          	auipc	ra,0x1
    80003678:	c66080e7          	jalr	-922(ra) # 800042da <log_write>
      brelse(bp);
    8000367c:	8526                	mv	a0,s1
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	a04080e7          	jalr	-1532(ra) # 80003082 <brelse>
      return iget(dev, inum);
    80003686:	0009059b          	sext.w	a1,s2
    8000368a:	8556                	mv	a0,s5
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	da2080e7          	jalr	-606(ra) # 8000342e <iget>
    80003694:	bf5d                	j	8000364a <ialloc+0x80>

0000000080003696 <iupdate>:
{
    80003696:	1101                	addi	sp,sp,-32
    80003698:	ec06                	sd	ra,24(sp)
    8000369a:	e822                	sd	s0,16(sp)
    8000369c:	e426                	sd	s1,8(sp)
    8000369e:	e04a                	sd	s2,0(sp)
    800036a0:	1000                	addi	s0,sp,32
    800036a2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036a4:	415c                	lw	a5,4(a0)
    800036a6:	0047d79b          	srliw	a5,a5,0x4
    800036aa:	0001c597          	auipc	a1,0x1c
    800036ae:	ca65a583          	lw	a1,-858(a1) # 8001f350 <sb+0x18>
    800036b2:	9dbd                	addw	a1,a1,a5
    800036b4:	4108                	lw	a0,0(a0)
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	89c080e7          	jalr	-1892(ra) # 80002f52 <bread>
    800036be:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036c0:	05850793          	addi	a5,a0,88
    800036c4:	40d8                	lw	a4,4(s1)
    800036c6:	8b3d                	andi	a4,a4,15
    800036c8:	071a                	slli	a4,a4,0x6
    800036ca:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036cc:	04449703          	lh	a4,68(s1)
    800036d0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036d4:	04649703          	lh	a4,70(s1)
    800036d8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036dc:	04849703          	lh	a4,72(s1)
    800036e0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036e4:	04a49703          	lh	a4,74(s1)
    800036e8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036ec:	44f8                	lw	a4,76(s1)
    800036ee:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036f0:	03400613          	li	a2,52
    800036f4:	05048593          	addi	a1,s1,80
    800036f8:	00c78513          	addi	a0,a5,12
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	6a4080e7          	jalr	1700(ra) # 80000da0 <memmove>
  log_write(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	bd4080e7          	jalr	-1068(ra) # 800042da <log_write>
  brelse(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00000097          	auipc	ra,0x0
    80003714:	972080e7          	jalr	-1678(ra) # 80003082 <brelse>
}
    80003718:	60e2                	ld	ra,24(sp)
    8000371a:	6442                	ld	s0,16(sp)
    8000371c:	64a2                	ld	s1,8(sp)
    8000371e:	6902                	ld	s2,0(sp)
    80003720:	6105                	addi	sp,sp,32
    80003722:	8082                	ret

0000000080003724 <idup>:
{
    80003724:	1101                	addi	sp,sp,-32
    80003726:	ec06                	sd	ra,24(sp)
    80003728:	e822                	sd	s0,16(sp)
    8000372a:	e426                	sd	s1,8(sp)
    8000372c:	1000                	addi	s0,sp,32
    8000372e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003730:	0001c517          	auipc	a0,0x1c
    80003734:	c2850513          	addi	a0,a0,-984 # 8001f358 <itable>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	510080e7          	jalr	1296(ra) # 80000c48 <acquire>
  ip->ref++;
    80003740:	449c                	lw	a5,8(s1)
    80003742:	2785                	addiw	a5,a5,1
    80003744:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003746:	0001c517          	auipc	a0,0x1c
    8000374a:	c1250513          	addi	a0,a0,-1006 # 8001f358 <itable>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	5ae080e7          	jalr	1454(ra) # 80000cfc <release>
}
    80003756:	8526                	mv	a0,s1
    80003758:	60e2                	ld	ra,24(sp)
    8000375a:	6442                	ld	s0,16(sp)
    8000375c:	64a2                	ld	s1,8(sp)
    8000375e:	6105                	addi	sp,sp,32
    80003760:	8082                	ret

0000000080003762 <ilock>:
{
    80003762:	1101                	addi	sp,sp,-32
    80003764:	ec06                	sd	ra,24(sp)
    80003766:	e822                	sd	s0,16(sp)
    80003768:	e426                	sd	s1,8(sp)
    8000376a:	e04a                	sd	s2,0(sp)
    8000376c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000376e:	c115                	beqz	a0,80003792 <ilock+0x30>
    80003770:	84aa                	mv	s1,a0
    80003772:	451c                	lw	a5,8(a0)
    80003774:	00f05f63          	blez	a5,80003792 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003778:	0541                	addi	a0,a0,16
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	c7e080e7          	jalr	-898(ra) # 800043f8 <acquiresleep>
  if(ip->valid == 0){
    80003782:	40bc                	lw	a5,64(s1)
    80003784:	cf99                	beqz	a5,800037a2 <ilock+0x40>
}
    80003786:	60e2                	ld	ra,24(sp)
    80003788:	6442                	ld	s0,16(sp)
    8000378a:	64a2                	ld	s1,8(sp)
    8000378c:	6902                	ld	s2,0(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret
    panic("ilock");
    80003792:	00005517          	auipc	a0,0x5
    80003796:	e4650513          	addi	a0,a0,-442 # 800085d8 <syscalls+0x180>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	da6080e7          	jalr	-602(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a2:	40dc                	lw	a5,4(s1)
    800037a4:	0047d79b          	srliw	a5,a5,0x4
    800037a8:	0001c597          	auipc	a1,0x1c
    800037ac:	ba85a583          	lw	a1,-1112(a1) # 8001f350 <sb+0x18>
    800037b0:	9dbd                	addw	a1,a1,a5
    800037b2:	4088                	lw	a0,0(s1)
    800037b4:	fffff097          	auipc	ra,0xfffff
    800037b8:	79e080e7          	jalr	1950(ra) # 80002f52 <bread>
    800037bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037be:	05850593          	addi	a1,a0,88
    800037c2:	40dc                	lw	a5,4(s1)
    800037c4:	8bbd                	andi	a5,a5,15
    800037c6:	079a                	slli	a5,a5,0x6
    800037c8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ca:	00059783          	lh	a5,0(a1)
    800037ce:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037d2:	00259783          	lh	a5,2(a1)
    800037d6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037da:	00459783          	lh	a5,4(a1)
    800037de:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037e2:	00659783          	lh	a5,6(a1)
    800037e6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ea:	459c                	lw	a5,8(a1)
    800037ec:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ee:	03400613          	li	a2,52
    800037f2:	05b1                	addi	a1,a1,12
    800037f4:	05048513          	addi	a0,s1,80
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	5a8080e7          	jalr	1448(ra) # 80000da0 <memmove>
    brelse(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00000097          	auipc	ra,0x0
    80003806:	880080e7          	jalr	-1920(ra) # 80003082 <brelse>
    ip->valid = 1;
    8000380a:	4785                	li	a5,1
    8000380c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000380e:	04449783          	lh	a5,68(s1)
    80003812:	fbb5                	bnez	a5,80003786 <ilock+0x24>
      panic("ilock: no type");
    80003814:	00005517          	auipc	a0,0x5
    80003818:	dcc50513          	addi	a0,a0,-564 # 800085e0 <syscalls+0x188>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	d24080e7          	jalr	-732(ra) # 80000540 <panic>

0000000080003824 <iunlock>:
{
    80003824:	1101                	addi	sp,sp,-32
    80003826:	ec06                	sd	ra,24(sp)
    80003828:	e822                	sd	s0,16(sp)
    8000382a:	e426                	sd	s1,8(sp)
    8000382c:	e04a                	sd	s2,0(sp)
    8000382e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003830:	c905                	beqz	a0,80003860 <iunlock+0x3c>
    80003832:	84aa                	mv	s1,a0
    80003834:	01050913          	addi	s2,a0,16
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	c58080e7          	jalr	-936(ra) # 80004492 <holdingsleep>
    80003842:	cd19                	beqz	a0,80003860 <iunlock+0x3c>
    80003844:	449c                	lw	a5,8(s1)
    80003846:	00f05d63          	blez	a5,80003860 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00001097          	auipc	ra,0x1
    80003850:	c02080e7          	jalr	-1022(ra) # 8000444e <releasesleep>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6902                	ld	s2,0(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret
    panic("iunlock");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	d9050513          	addi	a0,a0,-624 # 800085f0 <syscalls+0x198>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cd8080e7          	jalr	-808(ra) # 80000540 <panic>

0000000080003870 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003870:	7179                	addi	sp,sp,-48
    80003872:	f406                	sd	ra,40(sp)
    80003874:	f022                	sd	s0,32(sp)
    80003876:	ec26                	sd	s1,24(sp)
    80003878:	e84a                	sd	s2,16(sp)
    8000387a:	e44e                	sd	s3,8(sp)
    8000387c:	e052                	sd	s4,0(sp)
    8000387e:	1800                	addi	s0,sp,48
    80003880:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003882:	05050493          	addi	s1,a0,80
    80003886:	08050913          	addi	s2,a0,128
    8000388a:	a021                	j	80003892 <itrunc+0x22>
    8000388c:	0491                	addi	s1,s1,4
    8000388e:	01248d63          	beq	s1,s2,800038a8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003892:	408c                	lw	a1,0(s1)
    80003894:	dde5                	beqz	a1,8000388c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003896:	0009a503          	lw	a0,0(s3)
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	8fc080e7          	jalr	-1796(ra) # 80003196 <bfree>
      ip->addrs[i] = 0;
    800038a2:	0004a023          	sw	zero,0(s1)
    800038a6:	b7dd                	j	8000388c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038a8:	0809a583          	lw	a1,128(s3)
    800038ac:	e185                	bnez	a1,800038cc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038ae:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038b2:	854e                	mv	a0,s3
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	de2080e7          	jalr	-542(ra) # 80003696 <iupdate>
}
    800038bc:	70a2                	ld	ra,40(sp)
    800038be:	7402                	ld	s0,32(sp)
    800038c0:	64e2                	ld	s1,24(sp)
    800038c2:	6942                	ld	s2,16(sp)
    800038c4:	69a2                	ld	s3,8(sp)
    800038c6:	6a02                	ld	s4,0(sp)
    800038c8:	6145                	addi	sp,sp,48
    800038ca:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	fffff097          	auipc	ra,0xfffff
    800038d4:	682080e7          	jalr	1666(ra) # 80002f52 <bread>
    800038d8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038da:	05850493          	addi	s1,a0,88
    800038de:	45850913          	addi	s2,a0,1112
    800038e2:	a021                	j	800038ea <itrunc+0x7a>
    800038e4:	0491                	addi	s1,s1,4
    800038e6:	01248b63          	beq	s1,s2,800038fc <itrunc+0x8c>
      if(a[j])
    800038ea:	408c                	lw	a1,0(s1)
    800038ec:	dde5                	beqz	a1,800038e4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038ee:	0009a503          	lw	a0,0(s3)
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	8a4080e7          	jalr	-1884(ra) # 80003196 <bfree>
    800038fa:	b7ed                	j	800038e4 <itrunc+0x74>
    brelse(bp);
    800038fc:	8552                	mv	a0,s4
    800038fe:	fffff097          	auipc	ra,0xfffff
    80003902:	784080e7          	jalr	1924(ra) # 80003082 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003906:	0809a583          	lw	a1,128(s3)
    8000390a:	0009a503          	lw	a0,0(s3)
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	888080e7          	jalr	-1912(ra) # 80003196 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003916:	0809a023          	sw	zero,128(s3)
    8000391a:	bf51                	j	800038ae <itrunc+0x3e>

000000008000391c <iput>:
{
    8000391c:	1101                	addi	sp,sp,-32
    8000391e:	ec06                	sd	ra,24(sp)
    80003920:	e822                	sd	s0,16(sp)
    80003922:	e426                	sd	s1,8(sp)
    80003924:	e04a                	sd	s2,0(sp)
    80003926:	1000                	addi	s0,sp,32
    80003928:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	a2e50513          	addi	a0,a0,-1490 # 8001f358 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	316080e7          	jalr	790(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393a:	4498                	lw	a4,8(s1)
    8000393c:	4785                	li	a5,1
    8000393e:	02f70363          	beq	a4,a5,80003964 <iput+0x48>
  ip->ref--;
    80003942:	449c                	lw	a5,8(s1)
    80003944:	37fd                	addiw	a5,a5,-1
    80003946:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003948:	0001c517          	auipc	a0,0x1c
    8000394c:	a1050513          	addi	a0,a0,-1520 # 8001f358 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	3ac080e7          	jalr	940(ra) # 80000cfc <release>
}
    80003958:	60e2                	ld	ra,24(sp)
    8000395a:	6442                	ld	s0,16(sp)
    8000395c:	64a2                	ld	s1,8(sp)
    8000395e:	6902                	ld	s2,0(sp)
    80003960:	6105                	addi	sp,sp,32
    80003962:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003964:	40bc                	lw	a5,64(s1)
    80003966:	dff1                	beqz	a5,80003942 <iput+0x26>
    80003968:	04a49783          	lh	a5,74(s1)
    8000396c:	fbf9                	bnez	a5,80003942 <iput+0x26>
    acquiresleep(&ip->lock);
    8000396e:	01048913          	addi	s2,s1,16
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	a84080e7          	jalr	-1404(ra) # 800043f8 <acquiresleep>
    release(&itable.lock);
    8000397c:	0001c517          	auipc	a0,0x1c
    80003980:	9dc50513          	addi	a0,a0,-1572 # 8001f358 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	378080e7          	jalr	888(ra) # 80000cfc <release>
    itrunc(ip);
    8000398c:	8526                	mv	a0,s1
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	ee2080e7          	jalr	-286(ra) # 80003870 <itrunc>
    ip->type = 0;
    80003996:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000399a:	8526                	mv	a0,s1
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	cfa080e7          	jalr	-774(ra) # 80003696 <iupdate>
    ip->valid = 0;
    800039a4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	aa4080e7          	jalr	-1372(ra) # 8000444e <releasesleep>
    acquire(&itable.lock);
    800039b2:	0001c517          	auipc	a0,0x1c
    800039b6:	9a650513          	addi	a0,a0,-1626 # 8001f358 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	28e080e7          	jalr	654(ra) # 80000c48 <acquire>
    800039c2:	b741                	j	80003942 <iput+0x26>

00000000800039c4 <iunlockput>:
{
    800039c4:	1101                	addi	sp,sp,-32
    800039c6:	ec06                	sd	ra,24(sp)
    800039c8:	e822                	sd	s0,16(sp)
    800039ca:	e426                	sd	s1,8(sp)
    800039cc:	1000                	addi	s0,sp,32
    800039ce:	84aa                	mv	s1,a0
  iunlock(ip);
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	e54080e7          	jalr	-428(ra) # 80003824 <iunlock>
  iput(ip);
    800039d8:	8526                	mv	a0,s1
    800039da:	00000097          	auipc	ra,0x0
    800039de:	f42080e7          	jalr	-190(ra) # 8000391c <iput>
}
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret

00000000800039ec <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039ec:	1141                	addi	sp,sp,-16
    800039ee:	e422                	sd	s0,8(sp)
    800039f0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039f2:	411c                	lw	a5,0(a0)
    800039f4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039f6:	415c                	lw	a5,4(a0)
    800039f8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039fa:	04451783          	lh	a5,68(a0)
    800039fe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a02:	04a51783          	lh	a5,74(a0)
    80003a06:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a0a:	04c56783          	lwu	a5,76(a0)
    80003a0e:	e99c                	sd	a5,16(a1)
}
    80003a10:	6422                	ld	s0,8(sp)
    80003a12:	0141                	addi	sp,sp,16
    80003a14:	8082                	ret

0000000080003a16 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a16:	457c                	lw	a5,76(a0)
    80003a18:	0ed7e963          	bltu	a5,a3,80003b0a <readi+0xf4>
{
    80003a1c:	7159                	addi	sp,sp,-112
    80003a1e:	f486                	sd	ra,104(sp)
    80003a20:	f0a2                	sd	s0,96(sp)
    80003a22:	eca6                	sd	s1,88(sp)
    80003a24:	e8ca                	sd	s2,80(sp)
    80003a26:	e4ce                	sd	s3,72(sp)
    80003a28:	e0d2                	sd	s4,64(sp)
    80003a2a:	fc56                	sd	s5,56(sp)
    80003a2c:	f85a                	sd	s6,48(sp)
    80003a2e:	f45e                	sd	s7,40(sp)
    80003a30:	f062                	sd	s8,32(sp)
    80003a32:	ec66                	sd	s9,24(sp)
    80003a34:	e86a                	sd	s10,16(sp)
    80003a36:	e46e                	sd	s11,8(sp)
    80003a38:	1880                	addi	s0,sp,112
    80003a3a:	8b2a                	mv	s6,a0
    80003a3c:	8bae                	mv	s7,a1
    80003a3e:	8a32                	mv	s4,a2
    80003a40:	84b6                	mv	s1,a3
    80003a42:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a44:	9f35                	addw	a4,a4,a3
    return 0;
    80003a46:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a48:	0ad76063          	bltu	a4,a3,80003ae8 <readi+0xd2>
  if(off + n > ip->size)
    80003a4c:	00e7f463          	bgeu	a5,a4,80003a54 <readi+0x3e>
    n = ip->size - off;
    80003a50:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a54:	0a0a8963          	beqz	s5,80003b06 <readi+0xf0>
    80003a58:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a5a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a5e:	5c7d                	li	s8,-1
    80003a60:	a82d                	j	80003a9a <readi+0x84>
    80003a62:	020d1d93          	slli	s11,s10,0x20
    80003a66:	020ddd93          	srli	s11,s11,0x20
    80003a6a:	05890613          	addi	a2,s2,88
    80003a6e:	86ee                	mv	a3,s11
    80003a70:	963a                	add	a2,a2,a4
    80003a72:	85d2                	mv	a1,s4
    80003a74:	855e                	mv	a0,s7
    80003a76:	fffff097          	auipc	ra,0xfffff
    80003a7a:	a8c080e7          	jalr	-1396(ra) # 80002502 <either_copyout>
    80003a7e:	05850d63          	beq	a0,s8,80003ad8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	fffff097          	auipc	ra,0xfffff
    80003a88:	5fe080e7          	jalr	1534(ra) # 80003082 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8c:	013d09bb          	addw	s3,s10,s3
    80003a90:	009d04bb          	addw	s1,s10,s1
    80003a94:	9a6e                	add	s4,s4,s11
    80003a96:	0559f763          	bgeu	s3,s5,80003ae4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a9a:	00a4d59b          	srliw	a1,s1,0xa
    80003a9e:	855a                	mv	a0,s6
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	8a4080e7          	jalr	-1884(ra) # 80003344 <bmap>
    80003aa8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003aac:	cd85                	beqz	a1,80003ae4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003aae:	000b2503          	lw	a0,0(s6)
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	4a0080e7          	jalr	1184(ra) # 80002f52 <bread>
    80003aba:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003abc:	3ff4f713          	andi	a4,s1,1023
    80003ac0:	40ec87bb          	subw	a5,s9,a4
    80003ac4:	413a86bb          	subw	a3,s5,s3
    80003ac8:	8d3e                	mv	s10,a5
    80003aca:	2781                	sext.w	a5,a5
    80003acc:	0006861b          	sext.w	a2,a3
    80003ad0:	f8f679e3          	bgeu	a2,a5,80003a62 <readi+0x4c>
    80003ad4:	8d36                	mv	s10,a3
    80003ad6:	b771                	j	80003a62 <readi+0x4c>
      brelse(bp);
    80003ad8:	854a                	mv	a0,s2
    80003ada:	fffff097          	auipc	ra,0xfffff
    80003ade:	5a8080e7          	jalr	1448(ra) # 80003082 <brelse>
      tot = -1;
    80003ae2:	59fd                	li	s3,-1
  }
  return tot;
    80003ae4:	0009851b          	sext.w	a0,s3
}
    80003ae8:	70a6                	ld	ra,104(sp)
    80003aea:	7406                	ld	s0,96(sp)
    80003aec:	64e6                	ld	s1,88(sp)
    80003aee:	6946                	ld	s2,80(sp)
    80003af0:	69a6                	ld	s3,72(sp)
    80003af2:	6a06                	ld	s4,64(sp)
    80003af4:	7ae2                	ld	s5,56(sp)
    80003af6:	7b42                	ld	s6,48(sp)
    80003af8:	7ba2                	ld	s7,40(sp)
    80003afa:	7c02                	ld	s8,32(sp)
    80003afc:	6ce2                	ld	s9,24(sp)
    80003afe:	6d42                	ld	s10,16(sp)
    80003b00:	6da2                	ld	s11,8(sp)
    80003b02:	6165                	addi	sp,sp,112
    80003b04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b06:	89d6                	mv	s3,s5
    80003b08:	bff1                	j	80003ae4 <readi+0xce>
    return 0;
    80003b0a:	4501                	li	a0,0
}
    80003b0c:	8082                	ret

0000000080003b0e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b0e:	457c                	lw	a5,76(a0)
    80003b10:	10d7e863          	bltu	a5,a3,80003c20 <writei+0x112>
{
    80003b14:	7159                	addi	sp,sp,-112
    80003b16:	f486                	sd	ra,104(sp)
    80003b18:	f0a2                	sd	s0,96(sp)
    80003b1a:	eca6                	sd	s1,88(sp)
    80003b1c:	e8ca                	sd	s2,80(sp)
    80003b1e:	e4ce                	sd	s3,72(sp)
    80003b20:	e0d2                	sd	s4,64(sp)
    80003b22:	fc56                	sd	s5,56(sp)
    80003b24:	f85a                	sd	s6,48(sp)
    80003b26:	f45e                	sd	s7,40(sp)
    80003b28:	f062                	sd	s8,32(sp)
    80003b2a:	ec66                	sd	s9,24(sp)
    80003b2c:	e86a                	sd	s10,16(sp)
    80003b2e:	e46e                	sd	s11,8(sp)
    80003b30:	1880                	addi	s0,sp,112
    80003b32:	8aaa                	mv	s5,a0
    80003b34:	8bae                	mv	s7,a1
    80003b36:	8a32                	mv	s4,a2
    80003b38:	8936                	mv	s2,a3
    80003b3a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b3c:	00e687bb          	addw	a5,a3,a4
    80003b40:	0ed7e263          	bltu	a5,a3,80003c24 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b44:	00043737          	lui	a4,0x43
    80003b48:	0ef76063          	bltu	a4,a5,80003c28 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b4c:	0c0b0863          	beqz	s6,80003c1c <writei+0x10e>
    80003b50:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b52:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b56:	5c7d                	li	s8,-1
    80003b58:	a091                	j	80003b9c <writei+0x8e>
    80003b5a:	020d1d93          	slli	s11,s10,0x20
    80003b5e:	020ddd93          	srli	s11,s11,0x20
    80003b62:	05848513          	addi	a0,s1,88
    80003b66:	86ee                	mv	a3,s11
    80003b68:	8652                	mv	a2,s4
    80003b6a:	85de                	mv	a1,s7
    80003b6c:	953a                	add	a0,a0,a4
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	9ea080e7          	jalr	-1558(ra) # 80002558 <either_copyin>
    80003b76:	07850263          	beq	a0,s8,80003bda <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	75e080e7          	jalr	1886(ra) # 800042da <log_write>
    brelse(bp);
    80003b84:	8526                	mv	a0,s1
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	4fc080e7          	jalr	1276(ra) # 80003082 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b8e:	013d09bb          	addw	s3,s10,s3
    80003b92:	012d093b          	addw	s2,s10,s2
    80003b96:	9a6e                	add	s4,s4,s11
    80003b98:	0569f663          	bgeu	s3,s6,80003be4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b9c:	00a9559b          	srliw	a1,s2,0xa
    80003ba0:	8556                	mv	a0,s5
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	7a2080e7          	jalr	1954(ra) # 80003344 <bmap>
    80003baa:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bae:	c99d                	beqz	a1,80003be4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bb0:	000aa503          	lw	a0,0(s5)
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	39e080e7          	jalr	926(ra) # 80002f52 <bread>
    80003bbc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bbe:	3ff97713          	andi	a4,s2,1023
    80003bc2:	40ec87bb          	subw	a5,s9,a4
    80003bc6:	413b06bb          	subw	a3,s6,s3
    80003bca:	8d3e                	mv	s10,a5
    80003bcc:	2781                	sext.w	a5,a5
    80003bce:	0006861b          	sext.w	a2,a3
    80003bd2:	f8f674e3          	bgeu	a2,a5,80003b5a <writei+0x4c>
    80003bd6:	8d36                	mv	s10,a3
    80003bd8:	b749                	j	80003b5a <writei+0x4c>
      brelse(bp);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	fffff097          	auipc	ra,0xfffff
    80003be0:	4a6080e7          	jalr	1190(ra) # 80003082 <brelse>
  }

  if(off > ip->size)
    80003be4:	04caa783          	lw	a5,76(s5)
    80003be8:	0127f463          	bgeu	a5,s2,80003bf0 <writei+0xe2>
    ip->size = off;
    80003bec:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bf0:	8556                	mv	a0,s5
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	aa4080e7          	jalr	-1372(ra) # 80003696 <iupdate>

  return tot;
    80003bfa:	0009851b          	sext.w	a0,s3
}
    80003bfe:	70a6                	ld	ra,104(sp)
    80003c00:	7406                	ld	s0,96(sp)
    80003c02:	64e6                	ld	s1,88(sp)
    80003c04:	6946                	ld	s2,80(sp)
    80003c06:	69a6                	ld	s3,72(sp)
    80003c08:	6a06                	ld	s4,64(sp)
    80003c0a:	7ae2                	ld	s5,56(sp)
    80003c0c:	7b42                	ld	s6,48(sp)
    80003c0e:	7ba2                	ld	s7,40(sp)
    80003c10:	7c02                	ld	s8,32(sp)
    80003c12:	6ce2                	ld	s9,24(sp)
    80003c14:	6d42                	ld	s10,16(sp)
    80003c16:	6da2                	ld	s11,8(sp)
    80003c18:	6165                	addi	sp,sp,112
    80003c1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c1c:	89da                	mv	s3,s6
    80003c1e:	bfc9                	j	80003bf0 <writei+0xe2>
    return -1;
    80003c20:	557d                	li	a0,-1
}
    80003c22:	8082                	ret
    return -1;
    80003c24:	557d                	li	a0,-1
    80003c26:	bfe1                	j	80003bfe <writei+0xf0>
    return -1;
    80003c28:	557d                	li	a0,-1
    80003c2a:	bfd1                	j	80003bfe <writei+0xf0>

0000000080003c2c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c2c:	1141                	addi	sp,sp,-16
    80003c2e:	e406                	sd	ra,8(sp)
    80003c30:	e022                	sd	s0,0(sp)
    80003c32:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c34:	4639                	li	a2,14
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	1de080e7          	jalr	478(ra) # 80000e14 <strncmp>
}
    80003c3e:	60a2                	ld	ra,8(sp)
    80003c40:	6402                	ld	s0,0(sp)
    80003c42:	0141                	addi	sp,sp,16
    80003c44:	8082                	ret

0000000080003c46 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c46:	7139                	addi	sp,sp,-64
    80003c48:	fc06                	sd	ra,56(sp)
    80003c4a:	f822                	sd	s0,48(sp)
    80003c4c:	f426                	sd	s1,40(sp)
    80003c4e:	f04a                	sd	s2,32(sp)
    80003c50:	ec4e                	sd	s3,24(sp)
    80003c52:	e852                	sd	s4,16(sp)
    80003c54:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c56:	04451703          	lh	a4,68(a0)
    80003c5a:	4785                	li	a5,1
    80003c5c:	00f71a63          	bne	a4,a5,80003c70 <dirlookup+0x2a>
    80003c60:	892a                	mv	s2,a0
    80003c62:	89ae                	mv	s3,a1
    80003c64:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c66:	457c                	lw	a5,76(a0)
    80003c68:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c6a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6c:	e79d                	bnez	a5,80003c9a <dirlookup+0x54>
    80003c6e:	a8a5                	j	80003ce6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c70:	00005517          	auipc	a0,0x5
    80003c74:	98850513          	addi	a0,a0,-1656 # 800085f8 <syscalls+0x1a0>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	8c8080e7          	jalr	-1848(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c80:	00005517          	auipc	a0,0x5
    80003c84:	99050513          	addi	a0,a0,-1648 # 80008610 <syscalls+0x1b8>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	8b8080e7          	jalr	-1864(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c90:	24c1                	addiw	s1,s1,16
    80003c92:	04c92783          	lw	a5,76(s2)
    80003c96:	04f4f763          	bgeu	s1,a5,80003ce4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c9a:	4741                	li	a4,16
    80003c9c:	86a6                	mv	a3,s1
    80003c9e:	fc040613          	addi	a2,s0,-64
    80003ca2:	4581                	li	a1,0
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	d70080e7          	jalr	-656(ra) # 80003a16 <readi>
    80003cae:	47c1                	li	a5,16
    80003cb0:	fcf518e3          	bne	a0,a5,80003c80 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cb4:	fc045783          	lhu	a5,-64(s0)
    80003cb8:	dfe1                	beqz	a5,80003c90 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cba:	fc240593          	addi	a1,s0,-62
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	f6c080e7          	jalr	-148(ra) # 80003c2c <namecmp>
    80003cc8:	f561                	bnez	a0,80003c90 <dirlookup+0x4a>
      if(poff)
    80003cca:	000a0463          	beqz	s4,80003cd2 <dirlookup+0x8c>
        *poff = off;
    80003cce:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cd2:	fc045583          	lhu	a1,-64(s0)
    80003cd6:	00092503          	lw	a0,0(s2)
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	754080e7          	jalr	1876(ra) # 8000342e <iget>
    80003ce2:	a011                	j	80003ce6 <dirlookup+0xa0>
  return 0;
    80003ce4:	4501                	li	a0,0
}
    80003ce6:	70e2                	ld	ra,56(sp)
    80003ce8:	7442                	ld	s0,48(sp)
    80003cea:	74a2                	ld	s1,40(sp)
    80003cec:	7902                	ld	s2,32(sp)
    80003cee:	69e2                	ld	s3,24(sp)
    80003cf0:	6a42                	ld	s4,16(sp)
    80003cf2:	6121                	addi	sp,sp,64
    80003cf4:	8082                	ret

0000000080003cf6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cf6:	711d                	addi	sp,sp,-96
    80003cf8:	ec86                	sd	ra,88(sp)
    80003cfa:	e8a2                	sd	s0,80(sp)
    80003cfc:	e4a6                	sd	s1,72(sp)
    80003cfe:	e0ca                	sd	s2,64(sp)
    80003d00:	fc4e                	sd	s3,56(sp)
    80003d02:	f852                	sd	s4,48(sp)
    80003d04:	f456                	sd	s5,40(sp)
    80003d06:	f05a                	sd	s6,32(sp)
    80003d08:	ec5e                	sd	s7,24(sp)
    80003d0a:	e862                	sd	s8,16(sp)
    80003d0c:	e466                	sd	s9,8(sp)
    80003d0e:	1080                	addi	s0,sp,96
    80003d10:	84aa                	mv	s1,a0
    80003d12:	8b2e                	mv	s6,a1
    80003d14:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d16:	00054703          	lbu	a4,0(a0)
    80003d1a:	02f00793          	li	a5,47
    80003d1e:	02f70263          	beq	a4,a5,80003d42 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d22:	ffffe097          	auipc	ra,0xffffe
    80003d26:	d02080e7          	jalr	-766(ra) # 80001a24 <myproc>
    80003d2a:	15053503          	ld	a0,336(a0)
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	9f6080e7          	jalr	-1546(ra) # 80003724 <idup>
    80003d36:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d38:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d3c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d3e:	4b85                	li	s7,1
    80003d40:	a875                	j	80003dfc <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d42:	4585                	li	a1,1
    80003d44:	4505                	li	a0,1
    80003d46:	fffff097          	auipc	ra,0xfffff
    80003d4a:	6e8080e7          	jalr	1768(ra) # 8000342e <iget>
    80003d4e:	8a2a                	mv	s4,a0
    80003d50:	b7e5                	j	80003d38 <namex+0x42>
      iunlockput(ip);
    80003d52:	8552                	mv	a0,s4
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	c70080e7          	jalr	-912(ra) # 800039c4 <iunlockput>
      return 0;
    80003d5c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d5e:	8552                	mv	a0,s4
    80003d60:	60e6                	ld	ra,88(sp)
    80003d62:	6446                	ld	s0,80(sp)
    80003d64:	64a6                	ld	s1,72(sp)
    80003d66:	6906                	ld	s2,64(sp)
    80003d68:	79e2                	ld	s3,56(sp)
    80003d6a:	7a42                	ld	s4,48(sp)
    80003d6c:	7aa2                	ld	s5,40(sp)
    80003d6e:	7b02                	ld	s6,32(sp)
    80003d70:	6be2                	ld	s7,24(sp)
    80003d72:	6c42                	ld	s8,16(sp)
    80003d74:	6ca2                	ld	s9,8(sp)
    80003d76:	6125                	addi	sp,sp,96
    80003d78:	8082                	ret
      iunlock(ip);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	aa8080e7          	jalr	-1368(ra) # 80003824 <iunlock>
      return ip;
    80003d84:	bfe9                	j	80003d5e <namex+0x68>
      iunlockput(ip);
    80003d86:	8552                	mv	a0,s4
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	c3c080e7          	jalr	-964(ra) # 800039c4 <iunlockput>
      return 0;
    80003d90:	8a4e                	mv	s4,s3
    80003d92:	b7f1                	j	80003d5e <namex+0x68>
  len = path - s;
    80003d94:	40998633          	sub	a2,s3,s1
    80003d98:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d9c:	099c5863          	bge	s8,s9,80003e2c <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003da0:	4639                	li	a2,14
    80003da2:	85a6                	mv	a1,s1
    80003da4:	8556                	mv	a0,s5
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	ffa080e7          	jalr	-6(ra) # 80000da0 <memmove>
    80003dae:	84ce                	mv	s1,s3
  while(*path == '/')
    80003db0:	0004c783          	lbu	a5,0(s1)
    80003db4:	01279763          	bne	a5,s2,80003dc2 <namex+0xcc>
    path++;
    80003db8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	ff278de3          	beq	a5,s2,80003db8 <namex+0xc2>
    ilock(ip);
    80003dc2:	8552                	mv	a0,s4
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	99e080e7          	jalr	-1634(ra) # 80003762 <ilock>
    if(ip->type != T_DIR){
    80003dcc:	044a1783          	lh	a5,68(s4)
    80003dd0:	f97791e3          	bne	a5,s7,80003d52 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003dd4:	000b0563          	beqz	s6,80003dde <namex+0xe8>
    80003dd8:	0004c783          	lbu	a5,0(s1)
    80003ddc:	dfd9                	beqz	a5,80003d7a <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dde:	4601                	li	a2,0
    80003de0:	85d6                	mv	a1,s5
    80003de2:	8552                	mv	a0,s4
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	e62080e7          	jalr	-414(ra) # 80003c46 <dirlookup>
    80003dec:	89aa                	mv	s3,a0
    80003dee:	dd41                	beqz	a0,80003d86 <namex+0x90>
    iunlockput(ip);
    80003df0:	8552                	mv	a0,s4
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	bd2080e7          	jalr	-1070(ra) # 800039c4 <iunlockput>
    ip = next;
    80003dfa:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	01279763          	bne	a5,s2,80003e0e <namex+0x118>
    path++;
    80003e04:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e06:	0004c783          	lbu	a5,0(s1)
    80003e0a:	ff278de3          	beq	a5,s2,80003e04 <namex+0x10e>
  if(*path == 0)
    80003e0e:	cb9d                	beqz	a5,80003e44 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003e10:	0004c783          	lbu	a5,0(s1)
    80003e14:	89a6                	mv	s3,s1
  len = path - s;
    80003e16:	4c81                	li	s9,0
    80003e18:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003e1a:	01278963          	beq	a5,s2,80003e2c <namex+0x136>
    80003e1e:	dbbd                	beqz	a5,80003d94 <namex+0x9e>
    path++;
    80003e20:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e22:	0009c783          	lbu	a5,0(s3)
    80003e26:	ff279ce3          	bne	a5,s2,80003e1e <namex+0x128>
    80003e2a:	b7ad                	j	80003d94 <namex+0x9e>
    memmove(name, s, len);
    80003e2c:	2601                	sext.w	a2,a2
    80003e2e:	85a6                	mv	a1,s1
    80003e30:	8556                	mv	a0,s5
    80003e32:	ffffd097          	auipc	ra,0xffffd
    80003e36:	f6e080e7          	jalr	-146(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003e3a:	9cd6                	add	s9,s9,s5
    80003e3c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e40:	84ce                	mv	s1,s3
    80003e42:	b7bd                	j	80003db0 <namex+0xba>
  if(nameiparent){
    80003e44:	f00b0de3          	beqz	s6,80003d5e <namex+0x68>
    iput(ip);
    80003e48:	8552                	mv	a0,s4
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	ad2080e7          	jalr	-1326(ra) # 8000391c <iput>
    return 0;
    80003e52:	4a01                	li	s4,0
    80003e54:	b729                	j	80003d5e <namex+0x68>

0000000080003e56 <dirlink>:
{
    80003e56:	7139                	addi	sp,sp,-64
    80003e58:	fc06                	sd	ra,56(sp)
    80003e5a:	f822                	sd	s0,48(sp)
    80003e5c:	f426                	sd	s1,40(sp)
    80003e5e:	f04a                	sd	s2,32(sp)
    80003e60:	ec4e                	sd	s3,24(sp)
    80003e62:	e852                	sd	s4,16(sp)
    80003e64:	0080                	addi	s0,sp,64
    80003e66:	892a                	mv	s2,a0
    80003e68:	8a2e                	mv	s4,a1
    80003e6a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e6c:	4601                	li	a2,0
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	dd8080e7          	jalr	-552(ra) # 80003c46 <dirlookup>
    80003e76:	e93d                	bnez	a0,80003eec <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e78:	04c92483          	lw	s1,76(s2)
    80003e7c:	c49d                	beqz	s1,80003eaa <dirlink+0x54>
    80003e7e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e80:	4741                	li	a4,16
    80003e82:	86a6                	mv	a3,s1
    80003e84:	fc040613          	addi	a2,s0,-64
    80003e88:	4581                	li	a1,0
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	b8a080e7          	jalr	-1142(ra) # 80003a16 <readi>
    80003e94:	47c1                	li	a5,16
    80003e96:	06f51163          	bne	a0,a5,80003ef8 <dirlink+0xa2>
    if(de.inum == 0)
    80003e9a:	fc045783          	lhu	a5,-64(s0)
    80003e9e:	c791                	beqz	a5,80003eaa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea0:	24c1                	addiw	s1,s1,16
    80003ea2:	04c92783          	lw	a5,76(s2)
    80003ea6:	fcf4ede3          	bltu	s1,a5,80003e80 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eaa:	4639                	li	a2,14
    80003eac:	85d2                	mv	a1,s4
    80003eae:	fc240513          	addi	a0,s0,-62
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	f9e080e7          	jalr	-98(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003eba:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebe:	4741                	li	a4,16
    80003ec0:	86a6                	mv	a3,s1
    80003ec2:	fc040613          	addi	a2,s0,-64
    80003ec6:	4581                	li	a1,0
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	c44080e7          	jalr	-956(ra) # 80003b0e <writei>
    80003ed2:	1541                	addi	a0,a0,-16
    80003ed4:	00a03533          	snez	a0,a0
    80003ed8:	40a00533          	neg	a0,a0
}
    80003edc:	70e2                	ld	ra,56(sp)
    80003ede:	7442                	ld	s0,48(sp)
    80003ee0:	74a2                	ld	s1,40(sp)
    80003ee2:	7902                	ld	s2,32(sp)
    80003ee4:	69e2                	ld	s3,24(sp)
    80003ee6:	6a42                	ld	s4,16(sp)
    80003ee8:	6121                	addi	sp,sp,64
    80003eea:	8082                	ret
    iput(ip);
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	a30080e7          	jalr	-1488(ra) # 8000391c <iput>
    return -1;
    80003ef4:	557d                	li	a0,-1
    80003ef6:	b7dd                	j	80003edc <dirlink+0x86>
      panic("dirlink read");
    80003ef8:	00004517          	auipc	a0,0x4
    80003efc:	72850513          	addi	a0,a0,1832 # 80008620 <syscalls+0x1c8>
    80003f00:	ffffc097          	auipc	ra,0xffffc
    80003f04:	640080e7          	jalr	1600(ra) # 80000540 <panic>

0000000080003f08 <namei>:

struct inode*
namei(char *path)
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f10:	fe040613          	addi	a2,s0,-32
    80003f14:	4581                	li	a1,0
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	de0080e7          	jalr	-544(ra) # 80003cf6 <namex>
}
    80003f1e:	60e2                	ld	ra,24(sp)
    80003f20:	6442                	ld	s0,16(sp)
    80003f22:	6105                	addi	sp,sp,32
    80003f24:	8082                	ret

0000000080003f26 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f26:	1141                	addi	sp,sp,-16
    80003f28:	e406                	sd	ra,8(sp)
    80003f2a:	e022                	sd	s0,0(sp)
    80003f2c:	0800                	addi	s0,sp,16
    80003f2e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f30:	4585                	li	a1,1
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	dc4080e7          	jalr	-572(ra) # 80003cf6 <namex>
}
    80003f3a:	60a2                	ld	ra,8(sp)
    80003f3c:	6402                	ld	s0,0(sp)
    80003f3e:	0141                	addi	sp,sp,16
    80003f40:	8082                	ret

0000000080003f42 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f42:	1101                	addi	sp,sp,-32
    80003f44:	ec06                	sd	ra,24(sp)
    80003f46:	e822                	sd	s0,16(sp)
    80003f48:	e426                	sd	s1,8(sp)
    80003f4a:	e04a                	sd	s2,0(sp)
    80003f4c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f4e:	0001d917          	auipc	s2,0x1d
    80003f52:	eb290913          	addi	s2,s2,-334 # 80020e00 <log>
    80003f56:	01892583          	lw	a1,24(s2)
    80003f5a:	02892503          	lw	a0,40(s2)
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	ff4080e7          	jalr	-12(ra) # 80002f52 <bread>
    80003f66:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f68:	02c92603          	lw	a2,44(s2)
    80003f6c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f6e:	00c05f63          	blez	a2,80003f8c <write_head+0x4a>
    80003f72:	0001d717          	auipc	a4,0x1d
    80003f76:	ebe70713          	addi	a4,a4,-322 # 80020e30 <log+0x30>
    80003f7a:	87aa                	mv	a5,a0
    80003f7c:	060a                	slli	a2,a2,0x2
    80003f7e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f80:	4314                	lw	a3,0(a4)
    80003f82:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f84:	0711                	addi	a4,a4,4
    80003f86:	0791                	addi	a5,a5,4
    80003f88:	fec79ce3          	bne	a5,a2,80003f80 <write_head+0x3e>
  }
  bwrite(buf);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	0b6080e7          	jalr	182(ra) # 80003044 <bwrite>
  brelse(buf);
    80003f96:	8526                	mv	a0,s1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	0ea080e7          	jalr	234(ra) # 80003082 <brelse>
}
    80003fa0:	60e2                	ld	ra,24(sp)
    80003fa2:	6442                	ld	s0,16(sp)
    80003fa4:	64a2                	ld	s1,8(sp)
    80003fa6:	6902                	ld	s2,0(sp)
    80003fa8:	6105                	addi	sp,sp,32
    80003faa:	8082                	ret

0000000080003fac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fac:	0001d797          	auipc	a5,0x1d
    80003fb0:	e807a783          	lw	a5,-384(a5) # 80020e2c <log+0x2c>
    80003fb4:	0af05d63          	blez	a5,8000406e <install_trans+0xc2>
{
    80003fb8:	7139                	addi	sp,sp,-64
    80003fba:	fc06                	sd	ra,56(sp)
    80003fbc:	f822                	sd	s0,48(sp)
    80003fbe:	f426                	sd	s1,40(sp)
    80003fc0:	f04a                	sd	s2,32(sp)
    80003fc2:	ec4e                	sd	s3,24(sp)
    80003fc4:	e852                	sd	s4,16(sp)
    80003fc6:	e456                	sd	s5,8(sp)
    80003fc8:	e05a                	sd	s6,0(sp)
    80003fca:	0080                	addi	s0,sp,64
    80003fcc:	8b2a                	mv	s6,a0
    80003fce:	0001da97          	auipc	s5,0x1d
    80003fd2:	e62a8a93          	addi	s5,s5,-414 # 80020e30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd8:	0001d997          	auipc	s3,0x1d
    80003fdc:	e2898993          	addi	s3,s3,-472 # 80020e00 <log>
    80003fe0:	a00d                	j	80004002 <install_trans+0x56>
    brelse(lbuf);
    80003fe2:	854a                	mv	a0,s2
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	09e080e7          	jalr	158(ra) # 80003082 <brelse>
    brelse(dbuf);
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	094080e7          	jalr	148(ra) # 80003082 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff6:	2a05                	addiw	s4,s4,1
    80003ff8:	0a91                	addi	s5,s5,4
    80003ffa:	02c9a783          	lw	a5,44(s3)
    80003ffe:	04fa5e63          	bge	s4,a5,8000405a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004002:	0189a583          	lw	a1,24(s3)
    80004006:	014585bb          	addw	a1,a1,s4
    8000400a:	2585                	addiw	a1,a1,1
    8000400c:	0289a503          	lw	a0,40(s3)
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	f42080e7          	jalr	-190(ra) # 80002f52 <bread>
    80004018:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000401a:	000aa583          	lw	a1,0(s5)
    8000401e:	0289a503          	lw	a0,40(s3)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	f30080e7          	jalr	-208(ra) # 80002f52 <bread>
    8000402a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000402c:	40000613          	li	a2,1024
    80004030:	05890593          	addi	a1,s2,88
    80004034:	05850513          	addi	a0,a0,88
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	d68080e7          	jalr	-664(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	002080e7          	jalr	2(ra) # 80003044 <bwrite>
    if(recovering == 0)
    8000404a:	f80b1ce3          	bnez	s6,80003fe2 <install_trans+0x36>
      bunpin(dbuf);
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	10a080e7          	jalr	266(ra) # 8000315a <bunpin>
    80004058:	b769                	j	80003fe2 <install_trans+0x36>
}
    8000405a:	70e2                	ld	ra,56(sp)
    8000405c:	7442                	ld	s0,48(sp)
    8000405e:	74a2                	ld	s1,40(sp)
    80004060:	7902                	ld	s2,32(sp)
    80004062:	69e2                	ld	s3,24(sp)
    80004064:	6a42                	ld	s4,16(sp)
    80004066:	6aa2                	ld	s5,8(sp)
    80004068:	6b02                	ld	s6,0(sp)
    8000406a:	6121                	addi	sp,sp,64
    8000406c:	8082                	ret
    8000406e:	8082                	ret

0000000080004070 <initlog>:
{
    80004070:	7179                	addi	sp,sp,-48
    80004072:	f406                	sd	ra,40(sp)
    80004074:	f022                	sd	s0,32(sp)
    80004076:	ec26                	sd	s1,24(sp)
    80004078:	e84a                	sd	s2,16(sp)
    8000407a:	e44e                	sd	s3,8(sp)
    8000407c:	1800                	addi	s0,sp,48
    8000407e:	892a                	mv	s2,a0
    80004080:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004082:	0001d497          	auipc	s1,0x1d
    80004086:	d7e48493          	addi	s1,s1,-642 # 80020e00 <log>
    8000408a:	00004597          	auipc	a1,0x4
    8000408e:	5a658593          	addi	a1,a1,1446 # 80008630 <syscalls+0x1d8>
    80004092:	8526                	mv	a0,s1
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	b24080e7          	jalr	-1244(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    8000409c:	0149a583          	lw	a1,20(s3)
    800040a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040a2:	0109a783          	lw	a5,16(s3)
    800040a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040ac:	854a                	mv	a0,s2
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	ea4080e7          	jalr	-348(ra) # 80002f52 <bread>
  log.lh.n = lh->n;
    800040b6:	4d30                	lw	a2,88(a0)
    800040b8:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040ba:	00c05f63          	blez	a2,800040d8 <initlog+0x68>
    800040be:	87aa                	mv	a5,a0
    800040c0:	0001d717          	auipc	a4,0x1d
    800040c4:	d7070713          	addi	a4,a4,-656 # 80020e30 <log+0x30>
    800040c8:	060a                	slli	a2,a2,0x2
    800040ca:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800040cc:	4ff4                	lw	a3,92(a5)
    800040ce:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d0:	0791                	addi	a5,a5,4
    800040d2:	0711                	addi	a4,a4,4
    800040d4:	fec79ce3          	bne	a5,a2,800040cc <initlog+0x5c>
  brelse(buf);
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	faa080e7          	jalr	-86(ra) # 80003082 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e0:	4505                	li	a0,1
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	eca080e7          	jalr	-310(ra) # 80003fac <install_trans>
  log.lh.n = 0;
    800040ea:	0001d797          	auipc	a5,0x1d
    800040ee:	d407a123          	sw	zero,-702(a5) # 80020e2c <log+0x2c>
  write_head(); // clear the log
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	e50080e7          	jalr	-432(ra) # 80003f42 <write_head>
}
    800040fa:	70a2                	ld	ra,40(sp)
    800040fc:	7402                	ld	s0,32(sp)
    800040fe:	64e2                	ld	s1,24(sp)
    80004100:	6942                	ld	s2,16(sp)
    80004102:	69a2                	ld	s3,8(sp)
    80004104:	6145                	addi	sp,sp,48
    80004106:	8082                	ret

0000000080004108 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004108:	1101                	addi	sp,sp,-32
    8000410a:	ec06                	sd	ra,24(sp)
    8000410c:	e822                	sd	s0,16(sp)
    8000410e:	e426                	sd	s1,8(sp)
    80004110:	e04a                	sd	s2,0(sp)
    80004112:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004114:	0001d517          	auipc	a0,0x1d
    80004118:	cec50513          	addi	a0,a0,-788 # 80020e00 <log>
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	b2c080e7          	jalr	-1236(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    80004124:	0001d497          	auipc	s1,0x1d
    80004128:	cdc48493          	addi	s1,s1,-804 # 80020e00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000412c:	4979                	li	s2,30
    8000412e:	a039                	j	8000413c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004130:	85a6                	mv	a1,s1
    80004132:	8526                	mv	a0,s1
    80004134:	ffffe097          	auipc	ra,0xffffe
    80004138:	fc6080e7          	jalr	-58(ra) # 800020fa <sleep>
    if(log.committing){
    8000413c:	50dc                	lw	a5,36(s1)
    8000413e:	fbed                	bnez	a5,80004130 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004140:	5098                	lw	a4,32(s1)
    80004142:	2705                	addiw	a4,a4,1
    80004144:	0027179b          	slliw	a5,a4,0x2
    80004148:	9fb9                	addw	a5,a5,a4
    8000414a:	0017979b          	slliw	a5,a5,0x1
    8000414e:	54d4                	lw	a3,44(s1)
    80004150:	9fb5                	addw	a5,a5,a3
    80004152:	00f95963          	bge	s2,a5,80004164 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004156:	85a6                	mv	a1,s1
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffe097          	auipc	ra,0xffffe
    8000415e:	fa0080e7          	jalr	-96(ra) # 800020fa <sleep>
    80004162:	bfe9                	j	8000413c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004164:	0001d517          	auipc	a0,0x1d
    80004168:	c9c50513          	addi	a0,a0,-868 # 80020e00 <log>
    8000416c:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	b8e080e7          	jalr	-1138(ra) # 80000cfc <release>
      break;
    }
  }
}
    80004176:	60e2                	ld	ra,24(sp)
    80004178:	6442                	ld	s0,16(sp)
    8000417a:	64a2                	ld	s1,8(sp)
    8000417c:	6902                	ld	s2,0(sp)
    8000417e:	6105                	addi	sp,sp,32
    80004180:	8082                	ret

0000000080004182 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004182:	7139                	addi	sp,sp,-64
    80004184:	fc06                	sd	ra,56(sp)
    80004186:	f822                	sd	s0,48(sp)
    80004188:	f426                	sd	s1,40(sp)
    8000418a:	f04a                	sd	s2,32(sp)
    8000418c:	ec4e                	sd	s3,24(sp)
    8000418e:	e852                	sd	s4,16(sp)
    80004190:	e456                	sd	s5,8(sp)
    80004192:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004194:	0001d497          	auipc	s1,0x1d
    80004198:	c6c48493          	addi	s1,s1,-916 # 80020e00 <log>
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	aaa080e7          	jalr	-1366(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    800041a6:	509c                	lw	a5,32(s1)
    800041a8:	37fd                	addiw	a5,a5,-1
    800041aa:	0007891b          	sext.w	s2,a5
    800041ae:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041b0:	50dc                	lw	a5,36(s1)
    800041b2:	e7b9                	bnez	a5,80004200 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041b4:	04091e63          	bnez	s2,80004210 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041b8:	0001d497          	auipc	s1,0x1d
    800041bc:	c4848493          	addi	s1,s1,-952 # 80020e00 <log>
    800041c0:	4785                	li	a5,1
    800041c2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041c4:	8526                	mv	a0,s1
    800041c6:	ffffd097          	auipc	ra,0xffffd
    800041ca:	b36080e7          	jalr	-1226(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041ce:	54dc                	lw	a5,44(s1)
    800041d0:	06f04763          	bgtz	a5,8000423e <end_op+0xbc>
    acquire(&log.lock);
    800041d4:	0001d497          	auipc	s1,0x1d
    800041d8:	c2c48493          	addi	s1,s1,-980 # 80020e00 <log>
    800041dc:	8526                	mv	a0,s1
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	a6a080e7          	jalr	-1430(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041e6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffe097          	auipc	ra,0xffffe
    800041f0:	f72080e7          	jalr	-142(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	b06080e7          	jalr	-1274(ra) # 80000cfc <release>
}
    800041fe:	a03d                	j	8000422c <end_op+0xaa>
    panic("log.committing");
    80004200:	00004517          	auipc	a0,0x4
    80004204:	43850513          	addi	a0,a0,1080 # 80008638 <syscalls+0x1e0>
    80004208:	ffffc097          	auipc	ra,0xffffc
    8000420c:	338080e7          	jalr	824(ra) # 80000540 <panic>
    wakeup(&log);
    80004210:	0001d497          	auipc	s1,0x1d
    80004214:	bf048493          	addi	s1,s1,-1040 # 80020e00 <log>
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffe097          	auipc	ra,0xffffe
    8000421e:	f44080e7          	jalr	-188(ra) # 8000215e <wakeup>
  release(&log.lock);
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	ad8080e7          	jalr	-1320(ra) # 80000cfc <release>
}
    8000422c:	70e2                	ld	ra,56(sp)
    8000422e:	7442                	ld	s0,48(sp)
    80004230:	74a2                	ld	s1,40(sp)
    80004232:	7902                	ld	s2,32(sp)
    80004234:	69e2                	ld	s3,24(sp)
    80004236:	6a42                	ld	s4,16(sp)
    80004238:	6aa2                	ld	s5,8(sp)
    8000423a:	6121                	addi	sp,sp,64
    8000423c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423e:	0001da97          	auipc	s5,0x1d
    80004242:	bf2a8a93          	addi	s5,s5,-1038 # 80020e30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004246:	0001da17          	auipc	s4,0x1d
    8000424a:	bbaa0a13          	addi	s4,s4,-1094 # 80020e00 <log>
    8000424e:	018a2583          	lw	a1,24(s4)
    80004252:	012585bb          	addw	a1,a1,s2
    80004256:	2585                	addiw	a1,a1,1
    80004258:	028a2503          	lw	a0,40(s4)
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	cf6080e7          	jalr	-778(ra) # 80002f52 <bread>
    80004264:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004266:	000aa583          	lw	a1,0(s5)
    8000426a:	028a2503          	lw	a0,40(s4)
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	ce4080e7          	jalr	-796(ra) # 80002f52 <bread>
    80004276:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004278:	40000613          	li	a2,1024
    8000427c:	05850593          	addi	a1,a0,88
    80004280:	05848513          	addi	a0,s1,88
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	b1c080e7          	jalr	-1252(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    8000428c:	8526                	mv	a0,s1
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	db6080e7          	jalr	-586(ra) # 80003044 <bwrite>
    brelse(from);
    80004296:	854e                	mv	a0,s3
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	dea080e7          	jalr	-534(ra) # 80003082 <brelse>
    brelse(to);
    800042a0:	8526                	mv	a0,s1
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	de0080e7          	jalr	-544(ra) # 80003082 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042aa:	2905                	addiw	s2,s2,1
    800042ac:	0a91                	addi	s5,s5,4
    800042ae:	02ca2783          	lw	a5,44(s4)
    800042b2:	f8f94ee3          	blt	s2,a5,8000424e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	c8c080e7          	jalr	-884(ra) # 80003f42 <write_head>
    install_trans(0); // Now install writes to home locations
    800042be:	4501                	li	a0,0
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	cec080e7          	jalr	-788(ra) # 80003fac <install_trans>
    log.lh.n = 0;
    800042c8:	0001d797          	auipc	a5,0x1d
    800042cc:	b607a223          	sw	zero,-1180(a5) # 80020e2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	c72080e7          	jalr	-910(ra) # 80003f42 <write_head>
    800042d8:	bdf5                	j	800041d4 <end_op+0x52>

00000000800042da <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	e04a                	sd	s2,0(sp)
    800042e4:	1000                	addi	s0,sp,32
    800042e6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042e8:	0001d917          	auipc	s2,0x1d
    800042ec:	b1890913          	addi	s2,s2,-1256 # 80020e00 <log>
    800042f0:	854a                	mv	a0,s2
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	956080e7          	jalr	-1706(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042fa:	02c92603          	lw	a2,44(s2)
    800042fe:	47f5                	li	a5,29
    80004300:	06c7c563          	blt	a5,a2,8000436a <log_write+0x90>
    80004304:	0001d797          	auipc	a5,0x1d
    80004308:	b187a783          	lw	a5,-1256(a5) # 80020e1c <log+0x1c>
    8000430c:	37fd                	addiw	a5,a5,-1
    8000430e:	04f65e63          	bge	a2,a5,8000436a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004312:	0001d797          	auipc	a5,0x1d
    80004316:	b0e7a783          	lw	a5,-1266(a5) # 80020e20 <log+0x20>
    8000431a:	06f05063          	blez	a5,8000437a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000431e:	4781                	li	a5,0
    80004320:	06c05563          	blez	a2,8000438a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004324:	44cc                	lw	a1,12(s1)
    80004326:	0001d717          	auipc	a4,0x1d
    8000432a:	b0a70713          	addi	a4,a4,-1270 # 80020e30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004330:	4314                	lw	a3,0(a4)
    80004332:	04b68c63          	beq	a3,a1,8000438a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004336:	2785                	addiw	a5,a5,1
    80004338:	0711                	addi	a4,a4,4
    8000433a:	fef61be3          	bne	a2,a5,80004330 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000433e:	0621                	addi	a2,a2,8
    80004340:	060a                	slli	a2,a2,0x2
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	abe78793          	addi	a5,a5,-1346 # 80020e00 <log>
    8000434a:	97b2                	add	a5,a5,a2
    8000434c:	44d8                	lw	a4,12(s1)
    8000434e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	dcc080e7          	jalr	-564(ra) # 8000311e <bpin>
    log.lh.n++;
    8000435a:	0001d717          	auipc	a4,0x1d
    8000435e:	aa670713          	addi	a4,a4,-1370 # 80020e00 <log>
    80004362:	575c                	lw	a5,44(a4)
    80004364:	2785                	addiw	a5,a5,1
    80004366:	d75c                	sw	a5,44(a4)
    80004368:	a82d                	j	800043a2 <log_write+0xc8>
    panic("too big a transaction");
    8000436a:	00004517          	auipc	a0,0x4
    8000436e:	2de50513          	addi	a0,a0,734 # 80008648 <syscalls+0x1f0>
    80004372:	ffffc097          	auipc	ra,0xffffc
    80004376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000437a:	00004517          	auipc	a0,0x4
    8000437e:	2e650513          	addi	a0,a0,742 # 80008660 <syscalls+0x208>
    80004382:	ffffc097          	auipc	ra,0xffffc
    80004386:	1be080e7          	jalr	446(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000438a:	00878693          	addi	a3,a5,8
    8000438e:	068a                	slli	a3,a3,0x2
    80004390:	0001d717          	auipc	a4,0x1d
    80004394:	a7070713          	addi	a4,a4,-1424 # 80020e00 <log>
    80004398:	9736                	add	a4,a4,a3
    8000439a:	44d4                	lw	a3,12(s1)
    8000439c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000439e:	faf609e3          	beq	a2,a5,80004350 <log_write+0x76>
  }
  release(&log.lock);
    800043a2:	0001d517          	auipc	a0,0x1d
    800043a6:	a5e50513          	addi	a0,a0,-1442 # 80020e00 <log>
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	952080e7          	jalr	-1710(ra) # 80000cfc <release>
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
    800043ca:	84aa                	mv	s1,a0
    800043cc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043ce:	00004597          	auipc	a1,0x4
    800043d2:	2b258593          	addi	a1,a1,690 # 80008680 <syscalls+0x228>
    800043d6:	0521                	addi	a0,a0,8
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	7e0080e7          	jalr	2016(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043e0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e8:	0204a423          	sw	zero,40(s1)
}
    800043ec:	60e2                	ld	ra,24(sp)
    800043ee:	6442                	ld	s0,16(sp)
    800043f0:	64a2                	ld	s1,8(sp)
    800043f2:	6902                	ld	s2,0(sp)
    800043f4:	6105                	addi	sp,sp,32
    800043f6:	8082                	ret

00000000800043f8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f8:	1101                	addi	sp,sp,-32
    800043fa:	ec06                	sd	ra,24(sp)
    800043fc:	e822                	sd	s0,16(sp)
    800043fe:	e426                	sd	s1,8(sp)
    80004400:	e04a                	sd	s2,0(sp)
    80004402:	1000                	addi	s0,sp,32
    80004404:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004406:	00850913          	addi	s2,a0,8
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	83c080e7          	jalr	-1988(ra) # 80000c48 <acquire>
  while (lk->locked) {
    80004414:	409c                	lw	a5,0(s1)
    80004416:	cb89                	beqz	a5,80004428 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004418:	85ca                	mv	a1,s2
    8000441a:	8526                	mv	a0,s1
    8000441c:	ffffe097          	auipc	ra,0xffffe
    80004420:	cde080e7          	jalr	-802(ra) # 800020fa <sleep>
  while (lk->locked) {
    80004424:	409c                	lw	a5,0(s1)
    80004426:	fbed                	bnez	a5,80004418 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004428:	4785                	li	a5,1
    8000442a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	5f8080e7          	jalr	1528(ra) # 80001a24 <myproc>
    80004434:	591c                	lw	a5,48(a0)
    80004436:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004438:	854a                	mv	a0,s2
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	8c2080e7          	jalr	-1854(ra) # 80000cfc <release>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
    8000445a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000445c:	00850913          	addi	s2,a0,8
    80004460:	854a                	mv	a0,s2
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	7e6080e7          	jalr	2022(ra) # 80000c48 <acquire>
  lk->locked = 0;
    8000446a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004472:	8526                	mv	a0,s1
    80004474:	ffffe097          	auipc	ra,0xffffe
    80004478:	cea080e7          	jalr	-790(ra) # 8000215e <wakeup>
  release(&lk->lk);
    8000447c:	854a                	mv	a0,s2
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	87e080e7          	jalr	-1922(ra) # 80000cfc <release>
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004492:	7179                	addi	sp,sp,-48
    80004494:	f406                	sd	ra,40(sp)
    80004496:	f022                	sd	s0,32(sp)
    80004498:	ec26                	sd	s1,24(sp)
    8000449a:	e84a                	sd	s2,16(sp)
    8000449c:	e44e                	sd	s3,8(sp)
    8000449e:	1800                	addi	s0,sp,48
    800044a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044a2:	00850913          	addi	s2,a0,8
    800044a6:	854a                	mv	a0,s2
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	7a0080e7          	jalr	1952(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b0:	409c                	lw	a5,0(s1)
    800044b2:	ef99                	bnez	a5,800044d0 <holdingsleep+0x3e>
    800044b4:	4481                	li	s1,0
  release(&lk->lk);
    800044b6:	854a                	mv	a0,s2
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	844080e7          	jalr	-1980(ra) # 80000cfc <release>
  return r;
}
    800044c0:	8526                	mv	a0,s1
    800044c2:	70a2                	ld	ra,40(sp)
    800044c4:	7402                	ld	s0,32(sp)
    800044c6:	64e2                	ld	s1,24(sp)
    800044c8:	6942                	ld	s2,16(sp)
    800044ca:	69a2                	ld	s3,8(sp)
    800044cc:	6145                	addi	sp,sp,48
    800044ce:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d0:	0284a983          	lw	s3,40(s1)
    800044d4:	ffffd097          	auipc	ra,0xffffd
    800044d8:	550080e7          	jalr	1360(ra) # 80001a24 <myproc>
    800044dc:	5904                	lw	s1,48(a0)
    800044de:	413484b3          	sub	s1,s1,s3
    800044e2:	0014b493          	seqz	s1,s1
    800044e6:	bfc1                	j	800044b6 <holdingsleep+0x24>

00000000800044e8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e8:	1141                	addi	sp,sp,-16
    800044ea:	e406                	sd	ra,8(sp)
    800044ec:	e022                	sd	s0,0(sp)
    800044ee:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044f0:	00004597          	auipc	a1,0x4
    800044f4:	1a058593          	addi	a1,a1,416 # 80008690 <syscalls+0x238>
    800044f8:	0001d517          	auipc	a0,0x1d
    800044fc:	a5050513          	addi	a0,a0,-1456 # 80020f48 <ftable>
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	6b8080e7          	jalr	1720(ra) # 80000bb8 <initlock>
}
    80004508:	60a2                	ld	ra,8(sp)
    8000450a:	6402                	ld	s0,0(sp)
    8000450c:	0141                	addi	sp,sp,16
    8000450e:	8082                	ret

0000000080004510 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000451a:	0001d517          	auipc	a0,0x1d
    8000451e:	a2e50513          	addi	a0,a0,-1490 # 80020f48 <ftable>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	726080e7          	jalr	1830(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000452a:	0001d497          	auipc	s1,0x1d
    8000452e:	a3648493          	addi	s1,s1,-1482 # 80020f60 <ftable+0x18>
    80004532:	0001e717          	auipc	a4,0x1e
    80004536:	9ce70713          	addi	a4,a4,-1586 # 80021f00 <disk>
    if(f->ref == 0){
    8000453a:	40dc                	lw	a5,4(s1)
    8000453c:	cf99                	beqz	a5,8000455a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453e:	02848493          	addi	s1,s1,40
    80004542:	fee49ce3          	bne	s1,a4,8000453a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004546:	0001d517          	auipc	a0,0x1d
    8000454a:	a0250513          	addi	a0,a0,-1534 # 80020f48 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	7ae080e7          	jalr	1966(ra) # 80000cfc <release>
  return 0;
    80004556:	4481                	li	s1,0
    80004558:	a819                	j	8000456e <filealloc+0x5e>
      f->ref = 1;
    8000455a:	4785                	li	a5,1
    8000455c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000455e:	0001d517          	auipc	a0,0x1d
    80004562:	9ea50513          	addi	a0,a0,-1558 # 80020f48 <ftable>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	796080e7          	jalr	1942(ra) # 80000cfc <release>
}
    8000456e:	8526                	mv	a0,s1
    80004570:	60e2                	ld	ra,24(sp)
    80004572:	6442                	ld	s0,16(sp)
    80004574:	64a2                	ld	s1,8(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	1000                	addi	s0,sp,32
    80004584:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	9c250513          	addi	a0,a0,-1598 # 80020f48 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6ba080e7          	jalr	1722(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    80004596:	40dc                	lw	a5,4(s1)
    80004598:	02f05263          	blez	a5,800045bc <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000459c:	2785                	addiw	a5,a5,1
    8000459e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	9a850513          	addi	a0,a0,-1624 # 80020f48 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	754080e7          	jalr	1876(ra) # 80000cfc <release>
  return f;
}
    800045b0:	8526                	mv	a0,s1
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret
    panic("filedup");
    800045bc:	00004517          	auipc	a0,0x4
    800045c0:	0dc50513          	addi	a0,a0,220 # 80008698 <syscalls+0x240>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	f7c080e7          	jalr	-132(ra) # 80000540 <panic>

00000000800045cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045cc:	7139                	addi	sp,sp,-64
    800045ce:	fc06                	sd	ra,56(sp)
    800045d0:	f822                	sd	s0,48(sp)
    800045d2:	f426                	sd	s1,40(sp)
    800045d4:	f04a                	sd	s2,32(sp)
    800045d6:	ec4e                	sd	s3,24(sp)
    800045d8:	e852                	sd	s4,16(sp)
    800045da:	e456                	sd	s5,8(sp)
    800045dc:	0080                	addi	s0,sp,64
    800045de:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	96850513          	addi	a0,a0,-1688 # 80020f48 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	660080e7          	jalr	1632(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045f0:	40dc                	lw	a5,4(s1)
    800045f2:	06f05163          	blez	a5,80004654 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045f6:	37fd                	addiw	a5,a5,-1
    800045f8:	0007871b          	sext.w	a4,a5
    800045fc:	c0dc                	sw	a5,4(s1)
    800045fe:	06e04363          	bgtz	a4,80004664 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004602:	0004a903          	lw	s2,0(s1)
    80004606:	0094ca83          	lbu	s5,9(s1)
    8000460a:	0104ba03          	ld	s4,16(s1)
    8000460e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004612:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004616:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	92e50513          	addi	a0,a0,-1746 # 80020f48 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	6da080e7          	jalr	1754(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    8000462a:	4785                	li	a5,1
    8000462c:	04f90d63          	beq	s2,a5,80004686 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004630:	3979                	addiw	s2,s2,-2
    80004632:	4785                	li	a5,1
    80004634:	0527e063          	bltu	a5,s2,80004674 <fileclose+0xa8>
    begin_op();
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	ad0080e7          	jalr	-1328(ra) # 80004108 <begin_op>
    iput(ff.ip);
    80004640:	854e                	mv	a0,s3
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	2da080e7          	jalr	730(ra) # 8000391c <iput>
    end_op();
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	b38080e7          	jalr	-1224(ra) # 80004182 <end_op>
    80004652:	a00d                	j	80004674 <fileclose+0xa8>
    panic("fileclose");
    80004654:	00004517          	auipc	a0,0x4
    80004658:	04c50513          	addi	a0,a0,76 # 800086a0 <syscalls+0x248>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	ee4080e7          	jalr	-284(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	8e450513          	addi	a0,a0,-1820 # 80020f48 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	690080e7          	jalr	1680(ra) # 80000cfc <release>
  }
}
    80004674:	70e2                	ld	ra,56(sp)
    80004676:	7442                	ld	s0,48(sp)
    80004678:	74a2                	ld	s1,40(sp)
    8000467a:	7902                	ld	s2,32(sp)
    8000467c:	69e2                	ld	s3,24(sp)
    8000467e:	6a42                	ld	s4,16(sp)
    80004680:	6aa2                	ld	s5,8(sp)
    80004682:	6121                	addi	sp,sp,64
    80004684:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004686:	85d6                	mv	a1,s5
    80004688:	8552                	mv	a0,s4
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	348080e7          	jalr	840(ra) # 800049d2 <pipeclose>
    80004692:	b7cd                	j	80004674 <fileclose+0xa8>

0000000080004694 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004694:	715d                	addi	sp,sp,-80
    80004696:	e486                	sd	ra,72(sp)
    80004698:	e0a2                	sd	s0,64(sp)
    8000469a:	fc26                	sd	s1,56(sp)
    8000469c:	f84a                	sd	s2,48(sp)
    8000469e:	f44e                	sd	s3,40(sp)
    800046a0:	0880                	addi	s0,sp,80
    800046a2:	84aa                	mv	s1,a0
    800046a4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046a6:	ffffd097          	auipc	ra,0xffffd
    800046aa:	37e080e7          	jalr	894(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ae:	409c                	lw	a5,0(s1)
    800046b0:	37f9                	addiw	a5,a5,-2
    800046b2:	4705                	li	a4,1
    800046b4:	04f76763          	bltu	a4,a5,80004702 <filestat+0x6e>
    800046b8:	892a                	mv	s2,a0
    ilock(f->ip);
    800046ba:	6c88                	ld	a0,24(s1)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	0a6080e7          	jalr	166(ra) # 80003762 <ilock>
    stati(f->ip, &st);
    800046c4:	fb840593          	addi	a1,s0,-72
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	322080e7          	jalr	802(ra) # 800039ec <stati>
    iunlock(f->ip);
    800046d2:	6c88                	ld	a0,24(s1)
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	150080e7          	jalr	336(ra) # 80003824 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046dc:	46e1                	li	a3,24
    800046de:	fb840613          	addi	a2,s0,-72
    800046e2:	85ce                	mv	a1,s3
    800046e4:	05093503          	ld	a0,80(s2)
    800046e8:	ffffd097          	auipc	ra,0xffffd
    800046ec:	ffc080e7          	jalr	-4(ra) # 800016e4 <copyout>
    800046f0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046f4:	60a6                	ld	ra,72(sp)
    800046f6:	6406                	ld	s0,64(sp)
    800046f8:	74e2                	ld	s1,56(sp)
    800046fa:	7942                	ld	s2,48(sp)
    800046fc:	79a2                	ld	s3,40(sp)
    800046fe:	6161                	addi	sp,sp,80
    80004700:	8082                	ret
  return -1;
    80004702:	557d                	li	a0,-1
    80004704:	bfc5                	j	800046f4 <filestat+0x60>

0000000080004706 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004706:	7179                	addi	sp,sp,-48
    80004708:	f406                	sd	ra,40(sp)
    8000470a:	f022                	sd	s0,32(sp)
    8000470c:	ec26                	sd	s1,24(sp)
    8000470e:	e84a                	sd	s2,16(sp)
    80004710:	e44e                	sd	s3,8(sp)
    80004712:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004714:	00854783          	lbu	a5,8(a0)
    80004718:	c3d5                	beqz	a5,800047bc <fileread+0xb6>
    8000471a:	84aa                	mv	s1,a0
    8000471c:	89ae                	mv	s3,a1
    8000471e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004720:	411c                	lw	a5,0(a0)
    80004722:	4705                	li	a4,1
    80004724:	04e78963          	beq	a5,a4,80004776 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004728:	470d                	li	a4,3
    8000472a:	04e78d63          	beq	a5,a4,80004784 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472e:	4709                	li	a4,2
    80004730:	06e79e63          	bne	a5,a4,800047ac <fileread+0xa6>
    ilock(f->ip);
    80004734:	6d08                	ld	a0,24(a0)
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	02c080e7          	jalr	44(ra) # 80003762 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000473e:	874a                	mv	a4,s2
    80004740:	5094                	lw	a3,32(s1)
    80004742:	864e                	mv	a2,s3
    80004744:	4585                	li	a1,1
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2ce080e7          	jalr	718(ra) # 80003a16 <readi>
    80004750:	892a                	mv	s2,a0
    80004752:	00a05563          	blez	a0,8000475c <fileread+0x56>
      f->off += r;
    80004756:	509c                	lw	a5,32(s1)
    80004758:	9fa9                	addw	a5,a5,a0
    8000475a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000475c:	6c88                	ld	a0,24(s1)
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	0c6080e7          	jalr	198(ra) # 80003824 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004766:	854a                	mv	a0,s2
    80004768:	70a2                	ld	ra,40(sp)
    8000476a:	7402                	ld	s0,32(sp)
    8000476c:	64e2                	ld	s1,24(sp)
    8000476e:	6942                	ld	s2,16(sp)
    80004770:	69a2                	ld	s3,8(sp)
    80004772:	6145                	addi	sp,sp,48
    80004774:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004776:	6908                	ld	a0,16(a0)
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	3c2080e7          	jalr	962(ra) # 80004b3a <piperead>
    80004780:	892a                	mv	s2,a0
    80004782:	b7d5                	j	80004766 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004784:	02451783          	lh	a5,36(a0)
    80004788:	03079693          	slli	a3,a5,0x30
    8000478c:	92c1                	srli	a3,a3,0x30
    8000478e:	4725                	li	a4,9
    80004790:	02d76863          	bltu	a4,a3,800047c0 <fileread+0xba>
    80004794:	0792                	slli	a5,a5,0x4
    80004796:	0001c717          	auipc	a4,0x1c
    8000479a:	71270713          	addi	a4,a4,1810 # 80020ea8 <devsw>
    8000479e:	97ba                	add	a5,a5,a4
    800047a0:	639c                	ld	a5,0(a5)
    800047a2:	c38d                	beqz	a5,800047c4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047a4:	4505                	li	a0,1
    800047a6:	9782                	jalr	a5
    800047a8:	892a                	mv	s2,a0
    800047aa:	bf75                	j	80004766 <fileread+0x60>
    panic("fileread");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	f0450513          	addi	a0,a0,-252 # 800086b0 <syscalls+0x258>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d8c080e7          	jalr	-628(ra) # 80000540 <panic>
    return -1;
    800047bc:	597d                	li	s2,-1
    800047be:	b765                	j	80004766 <fileread+0x60>
      return -1;
    800047c0:	597d                	li	s2,-1
    800047c2:	b755                	j	80004766 <fileread+0x60>
    800047c4:	597d                	li	s2,-1
    800047c6:	b745                	j	80004766 <fileread+0x60>

00000000800047c8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047c8:	00954783          	lbu	a5,9(a0)
    800047cc:	10078e63          	beqz	a5,800048e8 <filewrite+0x120>
{
    800047d0:	715d                	addi	sp,sp,-80
    800047d2:	e486                	sd	ra,72(sp)
    800047d4:	e0a2                	sd	s0,64(sp)
    800047d6:	fc26                	sd	s1,56(sp)
    800047d8:	f84a                	sd	s2,48(sp)
    800047da:	f44e                	sd	s3,40(sp)
    800047dc:	f052                	sd	s4,32(sp)
    800047de:	ec56                	sd	s5,24(sp)
    800047e0:	e85a                	sd	s6,16(sp)
    800047e2:	e45e                	sd	s7,8(sp)
    800047e4:	e062                	sd	s8,0(sp)
    800047e6:	0880                	addi	s0,sp,80
    800047e8:	892a                	mv	s2,a0
    800047ea:	8b2e                	mv	s6,a1
    800047ec:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ee:	411c                	lw	a5,0(a0)
    800047f0:	4705                	li	a4,1
    800047f2:	02e78263          	beq	a5,a4,80004816 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f6:	470d                	li	a4,3
    800047f8:	02e78563          	beq	a5,a4,80004822 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047fc:	4709                	li	a4,2
    800047fe:	0ce79d63          	bne	a5,a4,800048d8 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004802:	0ac05b63          	blez	a2,800048b8 <filewrite+0xf0>
    int i = 0;
    80004806:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004808:	6b85                	lui	s7,0x1
    8000480a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000480e:	6c05                	lui	s8,0x1
    80004810:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004814:	a851                	j	800048a8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004816:	6908                	ld	a0,16(a0)
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	22a080e7          	jalr	554(ra) # 80004a42 <pipewrite>
    80004820:	a045                	j	800048c0 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004822:	02451783          	lh	a5,36(a0)
    80004826:	03079693          	slli	a3,a5,0x30
    8000482a:	92c1                	srli	a3,a3,0x30
    8000482c:	4725                	li	a4,9
    8000482e:	0ad76f63          	bltu	a4,a3,800048ec <filewrite+0x124>
    80004832:	0792                	slli	a5,a5,0x4
    80004834:	0001c717          	auipc	a4,0x1c
    80004838:	67470713          	addi	a4,a4,1652 # 80020ea8 <devsw>
    8000483c:	97ba                	add	a5,a5,a4
    8000483e:	679c                	ld	a5,8(a5)
    80004840:	cbc5                	beqz	a5,800048f0 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004842:	4505                	li	a0,1
    80004844:	9782                	jalr	a5
    80004846:	a8ad                	j	800048c0 <filewrite+0xf8>
      if(n1 > max)
    80004848:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	8bc080e7          	jalr	-1860(ra) # 80004108 <begin_op>
      ilock(f->ip);
    80004854:	01893503          	ld	a0,24(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	f0a080e7          	jalr	-246(ra) # 80003762 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004860:	8756                	mv	a4,s5
    80004862:	02092683          	lw	a3,32(s2)
    80004866:	01698633          	add	a2,s3,s6
    8000486a:	4585                	li	a1,1
    8000486c:	01893503          	ld	a0,24(s2)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	29e080e7          	jalr	670(ra) # 80003b0e <writei>
    80004878:	84aa                	mv	s1,a0
    8000487a:	00a05763          	blez	a0,80004888 <filewrite+0xc0>
        f->off += r;
    8000487e:	02092783          	lw	a5,32(s2)
    80004882:	9fa9                	addw	a5,a5,a0
    80004884:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004888:	01893503          	ld	a0,24(s2)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	f98080e7          	jalr	-104(ra) # 80003824 <iunlock>
      end_op();
    80004894:	00000097          	auipc	ra,0x0
    80004898:	8ee080e7          	jalr	-1810(ra) # 80004182 <end_op>

      if(r != n1){
    8000489c:	009a9f63          	bne	s5,s1,800048ba <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800048a0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a4:	0149db63          	bge	s3,s4,800048ba <filewrite+0xf2>
      int n1 = n - i;
    800048a8:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800048ac:	0004879b          	sext.w	a5,s1
    800048b0:	f8fbdce3          	bge	s7,a5,80004848 <filewrite+0x80>
    800048b4:	84e2                	mv	s1,s8
    800048b6:	bf49                	j	80004848 <filewrite+0x80>
    int i = 0;
    800048b8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048ba:	033a1d63          	bne	s4,s3,800048f4 <filewrite+0x12c>
    800048be:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048c0:	60a6                	ld	ra,72(sp)
    800048c2:	6406                	ld	s0,64(sp)
    800048c4:	74e2                	ld	s1,56(sp)
    800048c6:	7942                	ld	s2,48(sp)
    800048c8:	79a2                	ld	s3,40(sp)
    800048ca:	7a02                	ld	s4,32(sp)
    800048cc:	6ae2                	ld	s5,24(sp)
    800048ce:	6b42                	ld	s6,16(sp)
    800048d0:	6ba2                	ld	s7,8(sp)
    800048d2:	6c02                	ld	s8,0(sp)
    800048d4:	6161                	addi	sp,sp,80
    800048d6:	8082                	ret
    panic("filewrite");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	de850513          	addi	a0,a0,-536 # 800086c0 <syscalls+0x268>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
    return -1;
    800048e8:	557d                	li	a0,-1
}
    800048ea:	8082                	ret
      return -1;
    800048ec:	557d                	li	a0,-1
    800048ee:	bfc9                	j	800048c0 <filewrite+0xf8>
    800048f0:	557d                	li	a0,-1
    800048f2:	b7f9                	j	800048c0 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048f4:	557d                	li	a0,-1
    800048f6:	b7e9                	j	800048c0 <filewrite+0xf8>

00000000800048f8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048f8:	7179                	addi	sp,sp,-48
    800048fa:	f406                	sd	ra,40(sp)
    800048fc:	f022                	sd	s0,32(sp)
    800048fe:	ec26                	sd	s1,24(sp)
    80004900:	e84a                	sd	s2,16(sp)
    80004902:	e44e                	sd	s3,8(sp)
    80004904:	e052                	sd	s4,0(sp)
    80004906:	1800                	addi	s0,sp,48
    80004908:	84aa                	mv	s1,a0
    8000490a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000490c:	0005b023          	sd	zero,0(a1)
    80004910:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004914:	00000097          	auipc	ra,0x0
    80004918:	bfc080e7          	jalr	-1028(ra) # 80004510 <filealloc>
    8000491c:	e088                	sd	a0,0(s1)
    8000491e:	c551                	beqz	a0,800049aa <pipealloc+0xb2>
    80004920:	00000097          	auipc	ra,0x0
    80004924:	bf0080e7          	jalr	-1040(ra) # 80004510 <filealloc>
    80004928:	00aa3023          	sd	a0,0(s4)
    8000492c:	c92d                	beqz	a0,8000499e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	22a080e7          	jalr	554(ra) # 80000b58 <kalloc>
    80004936:	892a                	mv	s2,a0
    80004938:	c125                	beqz	a0,80004998 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000493a:	4985                	li	s3,1
    8000493c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004940:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004944:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004948:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000494c:	00004597          	auipc	a1,0x4
    80004950:	d8458593          	addi	a1,a1,-636 # 800086d0 <syscalls+0x278>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	264080e7          	jalr	612(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    8000495c:	609c                	ld	a5,0(s1)
    8000495e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004962:	609c                	ld	a5,0(s1)
    80004964:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004968:	609c                	ld	a5,0(s1)
    8000496a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000496e:	609c                	ld	a5,0(s1)
    80004970:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004974:	000a3783          	ld	a5,0(s4)
    80004978:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000497c:	000a3783          	ld	a5,0(s4)
    80004980:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004984:	000a3783          	ld	a5,0(s4)
    80004988:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000498c:	000a3783          	ld	a5,0(s4)
    80004990:	0127b823          	sd	s2,16(a5)
  return 0;
    80004994:	4501                	li	a0,0
    80004996:	a025                	j	800049be <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004998:	6088                	ld	a0,0(s1)
    8000499a:	e501                	bnez	a0,800049a2 <pipealloc+0xaa>
    8000499c:	a039                	j	800049aa <pipealloc+0xb2>
    8000499e:	6088                	ld	a0,0(s1)
    800049a0:	c51d                	beqz	a0,800049ce <pipealloc+0xd6>
    fileclose(*f0);
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	c2a080e7          	jalr	-982(ra) # 800045cc <fileclose>
  if(*f1)
    800049aa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ae:	557d                	li	a0,-1
  if(*f1)
    800049b0:	c799                	beqz	a5,800049be <pipealloc+0xc6>
    fileclose(*f1);
    800049b2:	853e                	mv	a0,a5
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	c18080e7          	jalr	-1000(ra) # 800045cc <fileclose>
  return -1;
    800049bc:	557d                	li	a0,-1
}
    800049be:	70a2                	ld	ra,40(sp)
    800049c0:	7402                	ld	s0,32(sp)
    800049c2:	64e2                	ld	s1,24(sp)
    800049c4:	6942                	ld	s2,16(sp)
    800049c6:	69a2                	ld	s3,8(sp)
    800049c8:	6a02                	ld	s4,0(sp)
    800049ca:	6145                	addi	sp,sp,48
    800049cc:	8082                	ret
  return -1;
    800049ce:	557d                	li	a0,-1
    800049d0:	b7fd                	j	800049be <pipealloc+0xc6>

00000000800049d2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049d2:	1101                	addi	sp,sp,-32
    800049d4:	ec06                	sd	ra,24(sp)
    800049d6:	e822                	sd	s0,16(sp)
    800049d8:	e426                	sd	s1,8(sp)
    800049da:	e04a                	sd	s2,0(sp)
    800049dc:	1000                	addi	s0,sp,32
    800049de:	84aa                	mv	s1,a0
    800049e0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	266080e7          	jalr	614(ra) # 80000c48 <acquire>
  if(writable){
    800049ea:	02090d63          	beqz	s2,80004a24 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ee:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049f2:	21848513          	addi	a0,s1,536
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	768080e7          	jalr	1896(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049fe:	2204b783          	ld	a5,544(s1)
    80004a02:	eb95                	bnez	a5,80004a36 <pipeclose+0x64>
    release(&pi->lock);
    80004a04:	8526                	mv	a0,s1
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	2f6080e7          	jalr	758(ra) # 80000cfc <release>
    kfree((char*)pi);
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	04a080e7          	jalr	74(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    80004a18:	60e2                	ld	ra,24(sp)
    80004a1a:	6442                	ld	s0,16(sp)
    80004a1c:	64a2                	ld	s1,8(sp)
    80004a1e:	6902                	ld	s2,0(sp)
    80004a20:	6105                	addi	sp,sp,32
    80004a22:	8082                	ret
    pi->readopen = 0;
    80004a24:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a28:	21c48513          	addi	a0,s1,540
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	732080e7          	jalr	1842(ra) # 8000215e <wakeup>
    80004a34:	b7e9                	j	800049fe <pipeclose+0x2c>
    release(&pi->lock);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	2c4080e7          	jalr	708(ra) # 80000cfc <release>
}
    80004a40:	bfe1                	j	80004a18 <pipeclose+0x46>

0000000080004a42 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a42:	711d                	addi	sp,sp,-96
    80004a44:	ec86                	sd	ra,88(sp)
    80004a46:	e8a2                	sd	s0,80(sp)
    80004a48:	e4a6                	sd	s1,72(sp)
    80004a4a:	e0ca                	sd	s2,64(sp)
    80004a4c:	fc4e                	sd	s3,56(sp)
    80004a4e:	f852                	sd	s4,48(sp)
    80004a50:	f456                	sd	s5,40(sp)
    80004a52:	f05a                	sd	s6,32(sp)
    80004a54:	ec5e                	sd	s7,24(sp)
    80004a56:	e862                	sd	s8,16(sp)
    80004a58:	1080                	addi	s0,sp,96
    80004a5a:	84aa                	mv	s1,a0
    80004a5c:	8aae                	mv	s5,a1
    80004a5e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	fc4080e7          	jalr	-60(ra) # 80001a24 <myproc>
    80004a68:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	1dc080e7          	jalr	476(ra) # 80000c48 <acquire>
  while(i < n){
    80004a74:	0b405663          	blez	s4,80004b20 <pipewrite+0xde>
  int i = 0;
    80004a78:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a7a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a7c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a80:	21c48b93          	addi	s7,s1,540
    80004a84:	a089                	j	80004ac6 <pipewrite+0x84>
      release(&pi->lock);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	274080e7          	jalr	628(ra) # 80000cfc <release>
      return -1;
    80004a90:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a92:	854a                	mv	a0,s2
    80004a94:	60e6                	ld	ra,88(sp)
    80004a96:	6446                	ld	s0,80(sp)
    80004a98:	64a6                	ld	s1,72(sp)
    80004a9a:	6906                	ld	s2,64(sp)
    80004a9c:	79e2                	ld	s3,56(sp)
    80004a9e:	7a42                	ld	s4,48(sp)
    80004aa0:	7aa2                	ld	s5,40(sp)
    80004aa2:	7b02                	ld	s6,32(sp)
    80004aa4:	6be2                	ld	s7,24(sp)
    80004aa6:	6c42                	ld	s8,16(sp)
    80004aa8:	6125                	addi	sp,sp,96
    80004aaa:	8082                	ret
      wakeup(&pi->nread);
    80004aac:	8562                	mv	a0,s8
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	6b0080e7          	jalr	1712(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ab6:	85a6                	mv	a1,s1
    80004ab8:	855e                	mv	a0,s7
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	640080e7          	jalr	1600(ra) # 800020fa <sleep>
  while(i < n){
    80004ac2:	07495063          	bge	s2,s4,80004b22 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ac6:	2204a783          	lw	a5,544(s1)
    80004aca:	dfd5                	beqz	a5,80004a86 <pipewrite+0x44>
    80004acc:	854e                	mv	a0,s3
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	8d4080e7          	jalr	-1836(ra) # 800023a2 <killed>
    80004ad6:	f945                	bnez	a0,80004a86 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ad8:	2184a783          	lw	a5,536(s1)
    80004adc:	21c4a703          	lw	a4,540(s1)
    80004ae0:	2007879b          	addiw	a5,a5,512
    80004ae4:	fcf704e3          	beq	a4,a5,80004aac <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae8:	4685                	li	a3,1
    80004aea:	01590633          	add	a2,s2,s5
    80004aee:	faf40593          	addi	a1,s0,-81
    80004af2:	0509b503          	ld	a0,80(s3)
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	c7a080e7          	jalr	-902(ra) # 80001770 <copyin>
    80004afe:	03650263          	beq	a0,s6,80004b22 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b02:	21c4a783          	lw	a5,540(s1)
    80004b06:	0017871b          	addiw	a4,a5,1
    80004b0a:	20e4ae23          	sw	a4,540(s1)
    80004b0e:	1ff7f793          	andi	a5,a5,511
    80004b12:	97a6                	add	a5,a5,s1
    80004b14:	faf44703          	lbu	a4,-81(s0)
    80004b18:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b1c:	2905                	addiw	s2,s2,1
    80004b1e:	b755                	j	80004ac2 <pipewrite+0x80>
  int i = 0;
    80004b20:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b22:	21848513          	addi	a0,s1,536
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	638080e7          	jalr	1592(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	1cc080e7          	jalr	460(ra) # 80000cfc <release>
  return i;
    80004b38:	bfa9                	j	80004a92 <pipewrite+0x50>

0000000080004b3a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b3a:	715d                	addi	sp,sp,-80
    80004b3c:	e486                	sd	ra,72(sp)
    80004b3e:	e0a2                	sd	s0,64(sp)
    80004b40:	fc26                	sd	s1,56(sp)
    80004b42:	f84a                	sd	s2,48(sp)
    80004b44:	f44e                	sd	s3,40(sp)
    80004b46:	f052                	sd	s4,32(sp)
    80004b48:	ec56                	sd	s5,24(sp)
    80004b4a:	e85a                	sd	s6,16(sp)
    80004b4c:	0880                	addi	s0,sp,80
    80004b4e:	84aa                	mv	s1,a0
    80004b50:	892e                	mv	s2,a1
    80004b52:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	ed0080e7          	jalr	-304(ra) # 80001a24 <myproc>
    80004b5c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	0e8080e7          	jalr	232(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b68:	2184a703          	lw	a4,536(s1)
    80004b6c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b70:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b74:	02f71763          	bne	a4,a5,80004ba2 <piperead+0x68>
    80004b78:	2244a783          	lw	a5,548(s1)
    80004b7c:	c39d                	beqz	a5,80004ba2 <piperead+0x68>
    if(killed(pr)){
    80004b7e:	8552                	mv	a0,s4
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	822080e7          	jalr	-2014(ra) # 800023a2 <killed>
    80004b88:	e949                	bnez	a0,80004c1a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8a:	85a6                	mv	a1,s1
    80004b8c:	854e                	mv	a0,s3
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	56c080e7          	jalr	1388(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b96:	2184a703          	lw	a4,536(s1)
    80004b9a:	21c4a783          	lw	a5,540(s1)
    80004b9e:	fcf70de3          	beq	a4,a5,80004b78 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ba4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba6:	05505463          	blez	s5,80004bee <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004baa:	2184a783          	lw	a5,536(s1)
    80004bae:	21c4a703          	lw	a4,540(s1)
    80004bb2:	02f70e63          	beq	a4,a5,80004bee <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bb6:	0017871b          	addiw	a4,a5,1
    80004bba:	20e4ac23          	sw	a4,536(s1)
    80004bbe:	1ff7f793          	andi	a5,a5,511
    80004bc2:	97a6                	add	a5,a5,s1
    80004bc4:	0187c783          	lbu	a5,24(a5)
    80004bc8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bcc:	4685                	li	a3,1
    80004bce:	fbf40613          	addi	a2,s0,-65
    80004bd2:	85ca                	mv	a1,s2
    80004bd4:	050a3503          	ld	a0,80(s4)
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	b0c080e7          	jalr	-1268(ra) # 800016e4 <copyout>
    80004be0:	01650763          	beq	a0,s6,80004bee <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be4:	2985                	addiw	s3,s3,1
    80004be6:	0905                	addi	s2,s2,1
    80004be8:	fd3a91e3          	bne	s5,s3,80004baa <piperead+0x70>
    80004bec:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bee:	21c48513          	addi	a0,s1,540
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	56c080e7          	jalr	1388(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	100080e7          	jalr	256(ra) # 80000cfc <release>
  return i;
}
    80004c04:	854e                	mv	a0,s3
    80004c06:	60a6                	ld	ra,72(sp)
    80004c08:	6406                	ld	s0,64(sp)
    80004c0a:	74e2                	ld	s1,56(sp)
    80004c0c:	7942                	ld	s2,48(sp)
    80004c0e:	79a2                	ld	s3,40(sp)
    80004c10:	7a02                	ld	s4,32(sp)
    80004c12:	6ae2                	ld	s5,24(sp)
    80004c14:	6b42                	ld	s6,16(sp)
    80004c16:	6161                	addi	sp,sp,80
    80004c18:	8082                	ret
      release(&pi->lock);
    80004c1a:	8526                	mv	a0,s1
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	0e0080e7          	jalr	224(ra) # 80000cfc <release>
      return -1;
    80004c24:	59fd                	li	s3,-1
    80004c26:	bff9                	j	80004c04 <piperead+0xca>

0000000080004c28 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c28:	1141                	addi	sp,sp,-16
    80004c2a:	e422                	sd	s0,8(sp)
    80004c2c:	0800                	addi	s0,sp,16
    80004c2e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c30:	8905                	andi	a0,a0,1
    80004c32:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c34:	8b89                	andi	a5,a5,2
    80004c36:	c399                	beqz	a5,80004c3c <flags2perm+0x14>
      perm |= PTE_W;
    80004c38:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c3c:	6422                	ld	s0,8(sp)
    80004c3e:	0141                	addi	sp,sp,16
    80004c40:	8082                	ret

0000000080004c42 <exec>:

int
exec(char *path, char **argv)
{
    80004c42:	df010113          	addi	sp,sp,-528
    80004c46:	20113423          	sd	ra,520(sp)
    80004c4a:	20813023          	sd	s0,512(sp)
    80004c4e:	ffa6                	sd	s1,504(sp)
    80004c50:	fbca                	sd	s2,496(sp)
    80004c52:	f7ce                	sd	s3,488(sp)
    80004c54:	f3d2                	sd	s4,480(sp)
    80004c56:	efd6                	sd	s5,472(sp)
    80004c58:	ebda                	sd	s6,464(sp)
    80004c5a:	e7de                	sd	s7,456(sp)
    80004c5c:	e3e2                	sd	s8,448(sp)
    80004c5e:	ff66                	sd	s9,440(sp)
    80004c60:	fb6a                	sd	s10,432(sp)
    80004c62:	f76e                	sd	s11,424(sp)
    80004c64:	0c00                	addi	s0,sp,528
    80004c66:	892a                	mv	s2,a0
    80004c68:	dea43c23          	sd	a0,-520(s0)
    80004c6c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	db4080e7          	jalr	-588(ra) # 80001a24 <myproc>
    80004c78:	84aa                	mv	s1,a0

  begin_op();
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	48e080e7          	jalr	1166(ra) # 80004108 <begin_op>

  if((ip = namei(path)) == 0){
    80004c82:	854a                	mv	a0,s2
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	284080e7          	jalr	644(ra) # 80003f08 <namei>
    80004c8c:	c92d                	beqz	a0,80004cfe <exec+0xbc>
    80004c8e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c90:	fffff097          	auipc	ra,0xfffff
    80004c94:	ad2080e7          	jalr	-1326(ra) # 80003762 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c98:	04000713          	li	a4,64
    80004c9c:	4681                	li	a3,0
    80004c9e:	e5040613          	addi	a2,s0,-432
    80004ca2:	4581                	li	a1,0
    80004ca4:	8552                	mv	a0,s4
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	d70080e7          	jalr	-656(ra) # 80003a16 <readi>
    80004cae:	04000793          	li	a5,64
    80004cb2:	00f51a63          	bne	a0,a5,80004cc6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cb6:	e5042703          	lw	a4,-432(s0)
    80004cba:	464c47b7          	lui	a5,0x464c4
    80004cbe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc2:	04f70463          	beq	a4,a5,80004d0a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cc6:	8552                	mv	a0,s4
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	cfc080e7          	jalr	-772(ra) # 800039c4 <iunlockput>
    end_op();
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	4b2080e7          	jalr	1202(ra) # 80004182 <end_op>
  }
  return -1;
    80004cd8:	557d                	li	a0,-1
}
    80004cda:	20813083          	ld	ra,520(sp)
    80004cde:	20013403          	ld	s0,512(sp)
    80004ce2:	74fe                	ld	s1,504(sp)
    80004ce4:	795e                	ld	s2,496(sp)
    80004ce6:	79be                	ld	s3,488(sp)
    80004ce8:	7a1e                	ld	s4,480(sp)
    80004cea:	6afe                	ld	s5,472(sp)
    80004cec:	6b5e                	ld	s6,464(sp)
    80004cee:	6bbe                	ld	s7,456(sp)
    80004cf0:	6c1e                	ld	s8,448(sp)
    80004cf2:	7cfa                	ld	s9,440(sp)
    80004cf4:	7d5a                	ld	s10,432(sp)
    80004cf6:	7dba                	ld	s11,424(sp)
    80004cf8:	21010113          	addi	sp,sp,528
    80004cfc:	8082                	ret
    end_op();
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	484080e7          	jalr	1156(ra) # 80004182 <end_op>
    return -1;
    80004d06:	557d                	li	a0,-1
    80004d08:	bfc9                	j	80004cda <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	ddc080e7          	jalr	-548(ra) # 80001ae8 <proc_pagetable>
    80004d14:	8b2a                	mv	s6,a0
    80004d16:	d945                	beqz	a0,80004cc6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d18:	e7042d03          	lw	s10,-400(s0)
    80004d1c:	e8845783          	lhu	a5,-376(s0)
    80004d20:	10078463          	beqz	a5,80004e28 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d24:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d26:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004d28:	6c85                	lui	s9,0x1
    80004d2a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d2e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d32:	6a85                	lui	s5,0x1
    80004d34:	a0b5                	j	80004da0 <exec+0x15e>
      panic("loadseg: address should exist");
    80004d36:	00004517          	auipc	a0,0x4
    80004d3a:	9a250513          	addi	a0,a0,-1630 # 800086d8 <syscalls+0x280>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	802080e7          	jalr	-2046(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d46:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d48:	8726                	mv	a4,s1
    80004d4a:	012c06bb          	addw	a3,s8,s2
    80004d4e:	4581                	li	a1,0
    80004d50:	8552                	mv	a0,s4
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	cc4080e7          	jalr	-828(ra) # 80003a16 <readi>
    80004d5a:	2501                	sext.w	a0,a0
    80004d5c:	2aa49d63          	bne	s1,a0,80005016 <exec+0x3d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004d60:	012a893b          	addw	s2,s5,s2
    80004d64:	03397563          	bgeu	s2,s3,80004d8e <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d68:	02091593          	slli	a1,s2,0x20
    80004d6c:	9181                	srli	a1,a1,0x20
    80004d6e:	95de                	add	a1,a1,s7
    80004d70:	855a                	mv	a0,s6
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	362080e7          	jalr	866(ra) # 800010d4 <walkaddr>
    80004d7a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d7c:	dd4d                	beqz	a0,80004d36 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d7e:	412984bb          	subw	s1,s3,s2
    80004d82:	0004879b          	sext.w	a5,s1
    80004d86:	fcfcf0e3          	bgeu	s9,a5,80004d46 <exec+0x104>
    80004d8a:	84d6                	mv	s1,s5
    80004d8c:	bf6d                	j	80004d46 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d8e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d92:	2d85                	addiw	s11,s11,1
    80004d94:	038d0d1b          	addiw	s10,s10,56
    80004d98:	e8845783          	lhu	a5,-376(s0)
    80004d9c:	08fdd763          	bge	s11,a5,80004e2a <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004da0:	2d01                	sext.w	s10,s10
    80004da2:	03800713          	li	a4,56
    80004da6:	86ea                	mv	a3,s10
    80004da8:	e1840613          	addi	a2,s0,-488
    80004dac:	4581                	li	a1,0
    80004dae:	8552                	mv	a0,s4
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	c66080e7          	jalr	-922(ra) # 80003a16 <readi>
    80004db8:	03800793          	li	a5,56
    80004dbc:	24f51b63          	bne	a0,a5,80005012 <exec+0x3d0>
    if(ph.type != ELF_PROG_LOAD)
    80004dc0:	e1842783          	lw	a5,-488(s0)
    80004dc4:	4705                	li	a4,1
    80004dc6:	fce796e3          	bne	a5,a4,80004d92 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004dca:	e4043483          	ld	s1,-448(s0)
    80004dce:	e3843783          	ld	a5,-456(s0)
    80004dd2:	24f4ed63          	bltu	s1,a5,8000502c <exec+0x3ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004dd6:	e2843783          	ld	a5,-472(s0)
    80004dda:	94be                	add	s1,s1,a5
    80004ddc:	24f4eb63          	bltu	s1,a5,80005032 <exec+0x3f0>
    if(ph.vaddr % PGSIZE != 0)
    80004de0:	df043703          	ld	a4,-528(s0)
    80004de4:	8ff9                	and	a5,a5,a4
    80004de6:	24079963          	bnez	a5,80005038 <exec+0x3f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dea:	e1c42503          	lw	a0,-484(s0)
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	e3a080e7          	jalr	-454(ra) # 80004c28 <flags2perm>
    80004df6:	86aa                	mv	a3,a0
    80004df8:	8626                	mv	a2,s1
    80004dfa:	85ca                	mv	a1,s2
    80004dfc:	855a                	mv	a0,s6
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	68a080e7          	jalr	1674(ra) # 80001488 <uvmalloc>
    80004e06:	e0a43423          	sd	a0,-504(s0)
    80004e0a:	22050a63          	beqz	a0,8000503e <exec+0x3fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e0e:	e2843b83          	ld	s7,-472(s0)
    80004e12:	e2042c03          	lw	s8,-480(s0)
    80004e16:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e1a:	00098463          	beqz	s3,80004e22 <exec+0x1e0>
    80004e1e:	4901                	li	s2,0
    80004e20:	b7a1                	j	80004d68 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e22:	e0843903          	ld	s2,-504(s0)
    80004e26:	b7b5                	j	80004d92 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e28:	4901                	li	s2,0
  iunlockput(ip);
    80004e2a:	8552                	mv	a0,s4
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	b98080e7          	jalr	-1128(ra) # 800039c4 <iunlockput>
  end_op();
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	34e080e7          	jalr	846(ra) # 80004182 <end_op>
  p = myproc();
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	be8080e7          	jalr	-1048(ra) # 80001a24 <myproc>
    80004e44:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e46:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e4a:	6985                	lui	s3,0x1
    80004e4c:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e4e:	99ca                	add	s3,s3,s2
    80004e50:	77fd                	lui	a5,0xfffff
    80004e52:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e56:	4691                	li	a3,4
    80004e58:	6609                	lui	a2,0x2
    80004e5a:	964e                	add	a2,a2,s3
    80004e5c:	85ce                	mv	a1,s3
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	628080e7          	jalr	1576(ra) # 80001488 <uvmalloc>
    80004e68:	892a                	mv	s2,a0
    80004e6a:	e0a43423          	sd	a0,-504(s0)
    80004e6e:	e509                	bnez	a0,80004e78 <exec+0x236>
  if(pagetable)
    80004e70:	e1343423          	sd	s3,-504(s0)
    80004e74:	4a01                	li	s4,0
    80004e76:	a245                	j	80005016 <exec+0x3d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e78:	75f9                	lui	a1,0xffffe
    80004e7a:	95aa                	add	a1,a1,a0
    80004e7c:	855a                	mv	a0,s6
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	834080e7          	jalr	-1996(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e86:	7bfd                	lui	s7,0xfffff
    80004e88:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e8a:	e0043783          	ld	a5,-512(s0)
    80004e8e:	6388                	ld	a0,0(a5)
    80004e90:	c52d                	beqz	a0,80004efa <exec+0x2b8>
    80004e92:	e9040993          	addi	s3,s0,-368
    80004e96:	f9040c13          	addi	s8,s0,-112
    80004e9a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	022080e7          	jalr	34(ra) # 80000ebe <strlen>
    80004ea4:	0015079b          	addiw	a5,a0,1
    80004ea8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eac:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004eb0:	19796a63          	bltu	s2,s7,80005044 <exec+0x402>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb4:	e0043d03          	ld	s10,-512(s0)
    80004eb8:	000d3a03          	ld	s4,0(s10)
    80004ebc:	8552                	mv	a0,s4
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	000080e7          	jalr	ra # 80000ebe <strlen>
    80004ec6:	0015069b          	addiw	a3,a0,1
    80004eca:	8652                	mv	a2,s4
    80004ecc:	85ca                	mv	a1,s2
    80004ece:	855a                	mv	a0,s6
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	814080e7          	jalr	-2028(ra) # 800016e4 <copyout>
    80004ed8:	16054863          	bltz	a0,80005048 <exec+0x406>
    ustack[argc] = sp;
    80004edc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ee0:	0485                	addi	s1,s1,1
    80004ee2:	008d0793          	addi	a5,s10,8
    80004ee6:	e0f43023          	sd	a5,-512(s0)
    80004eea:	008d3503          	ld	a0,8(s10)
    80004eee:	c909                	beqz	a0,80004f00 <exec+0x2be>
    if(argc >= MAXARG)
    80004ef0:	09a1                	addi	s3,s3,8
    80004ef2:	fb8995e3          	bne	s3,s8,80004e9c <exec+0x25a>
  ip = 0;
    80004ef6:	4a01                	li	s4,0
    80004ef8:	aa39                	j	80005016 <exec+0x3d4>
  sp = sz;
    80004efa:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004efe:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f00:	00349793          	slli	a5,s1,0x3
    80004f04:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcd08>
    80004f08:	97a2                	add	a5,a5,s0
    80004f0a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f0e:	00148693          	addi	a3,s1,1
    80004f12:	068e                	slli	a3,a3,0x3
    80004f14:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f18:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004f1c:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004f20:	f57968e3          	bltu	s2,s7,80004e70 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f24:	e9040613          	addi	a2,s0,-368
    80004f28:	85ca                	mv	a1,s2
    80004f2a:	855a                	mv	a0,s6
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	7b8080e7          	jalr	1976(ra) # 800016e4 <copyout>
    80004f34:	10054c63          	bltz	a0,8000504c <exec+0x40a>
  p->trapframe->a1 = sp;
    80004f38:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f3c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f40:	df843783          	ld	a5,-520(s0)
    80004f44:	0007c703          	lbu	a4,0(a5)
    80004f48:	cf11                	beqz	a4,80004f64 <exec+0x322>
    80004f4a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f4c:	02f00693          	li	a3,47
    80004f50:	a039                	j	80004f5e <exec+0x31c>
      last = s+1;
    80004f52:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f56:	0785                	addi	a5,a5,1
    80004f58:	fff7c703          	lbu	a4,-1(a5)
    80004f5c:	c701                	beqz	a4,80004f64 <exec+0x322>
    if(*s == '/')
    80004f5e:	fed71ce3          	bne	a4,a3,80004f56 <exec+0x314>
    80004f62:	bfc5                	j	80004f52 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f64:	158a8993          	addi	s3,s5,344
    80004f68:	4641                	li	a2,16
    80004f6a:	df843583          	ld	a1,-520(s0)
    80004f6e:	854e                	mv	a0,s3
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	f1c080e7          	jalr	-228(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f78:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f7c:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f80:	e0843783          	ld	a5,-504(s0)
    80004f84:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f88:	058ab783          	ld	a5,88(s5)
    80004f8c:	e6843703          	ld	a4,-408(s0)
    80004f90:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f92:	058ab783          	ld	a5,88(s5)
    80004f96:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f9a:	85e6                	mv	a1,s9
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	be8080e7          	jalr	-1048(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004fa4:	460d                	li	a2,3
    80004fa6:	00003597          	auipc	a1,0x3
    80004faa:	25a58593          	addi	a1,a1,602 # 80008200 <digits+0x1c0>
    80004fae:	854e                	mv	a0,s3
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	e64080e7          	jalr	-412(ra) # 80000e14 <strncmp>
    80004fb8:	c501                	beqz	a0,80004fc0 <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fba:	0004851b          	sext.w	a0,s1
    80004fbe:	bb31                	j	80004cda <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004fc0:	4691                	li	a3,4
    80004fc2:	20100613          	li	a2,513
    80004fc6:	065a                	slli	a2,a2,0x16
    80004fc8:	4585                	li	a1,1
    80004fca:	05fe                	slli	a1,a1,0x1f
    80004fcc:	855a                	mv	a0,s6
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	4ba080e7          	jalr	1210(ra) # 80001488 <uvmalloc>
    80004fd6:	c11d                	beqz	a0,80004ffc <exec+0x3ba>
    trap_and_emulate_init();  // Initialize the VM's registers and mode
    80004fd8:	00002097          	auipc	ra,0x2
    80004fdc:	98e080e7          	jalr	-1650(ra) # 80006966 <trap_and_emulate_init>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004fe0:	20100613          	li	a2,513
    80004fe4:	065a                	slli	a2,a2,0x16
    80004fe6:	4585                	li	a1,1
    80004fe8:	05fe                	slli	a1,a1,0x1f
    80004fea:	00003517          	auipc	a0,0x3
    80004fee:	74650513          	addi	a0,a0,1862 # 80008730 <syscalls+0x2d8>
    80004ff2:	ffffb097          	auipc	ra,0xffffb
    80004ff6:	598080e7          	jalr	1432(ra) # 8000058a <printf>
    80004ffa:	b7c1                	j	80004fba <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004ffc:	00003517          	auipc	a0,0x3
    80005000:	6fc50513          	addi	a0,a0,1788 # 800086f8 <syscalls+0x2a0>
    80005004:	ffffb097          	auipc	ra,0xffffb
    80005008:	586080e7          	jalr	1414(ra) # 8000058a <printf>
  sz = sz1;
    8000500c:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80005010:	b585                	j	80004e70 <exec+0x22e>
    80005012:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005016:	e0843583          	ld	a1,-504(s0)
    8000501a:	855a                	mv	a0,s6
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	b68080e7          	jalr	-1176(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80005024:	557d                	li	a0,-1
  if(ip){
    80005026:	ca0a0ae3          	beqz	s4,80004cda <exec+0x98>
    8000502a:	b971                	j	80004cc6 <exec+0x84>
    8000502c:	e1243423          	sd	s2,-504(s0)
    80005030:	b7dd                	j	80005016 <exec+0x3d4>
    80005032:	e1243423          	sd	s2,-504(s0)
    80005036:	b7c5                	j	80005016 <exec+0x3d4>
    80005038:	e1243423          	sd	s2,-504(s0)
    8000503c:	bfe9                	j	80005016 <exec+0x3d4>
    8000503e:	e1243423          	sd	s2,-504(s0)
    80005042:	bfd1                	j	80005016 <exec+0x3d4>
  ip = 0;
    80005044:	4a01                	li	s4,0
    80005046:	bfc1                	j	80005016 <exec+0x3d4>
    80005048:	4a01                	li	s4,0
  if(pagetable)
    8000504a:	b7f1                	j	80005016 <exec+0x3d4>
  sz = sz1;
    8000504c:	e0843983          	ld	s3,-504(s0)
    80005050:	b505                	j	80004e70 <exec+0x22e>

0000000080005052 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005052:	7179                	addi	sp,sp,-48
    80005054:	f406                	sd	ra,40(sp)
    80005056:	f022                	sd	s0,32(sp)
    80005058:	ec26                	sd	s1,24(sp)
    8000505a:	e84a                	sd	s2,16(sp)
    8000505c:	1800                	addi	s0,sp,48
    8000505e:	892e                	mv	s2,a1
    80005060:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005062:	fdc40593          	addi	a1,s0,-36
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	b9a080e7          	jalr	-1126(ra) # 80002c00 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000506e:	fdc42703          	lw	a4,-36(s0)
    80005072:	47bd                	li	a5,15
    80005074:	02e7eb63          	bltu	a5,a4,800050aa <argfd+0x58>
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	9ac080e7          	jalr	-1620(ra) # 80001a24 <myproc>
    80005080:	fdc42703          	lw	a4,-36(s0)
    80005084:	01a70793          	addi	a5,a4,26
    80005088:	078e                	slli	a5,a5,0x3
    8000508a:	953e                	add	a0,a0,a5
    8000508c:	611c                	ld	a5,0(a0)
    8000508e:	c385                	beqz	a5,800050ae <argfd+0x5c>
    return -1;
  if(pfd)
    80005090:	00090463          	beqz	s2,80005098 <argfd+0x46>
    *pfd = fd;
    80005094:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005098:	4501                	li	a0,0
  if(pf)
    8000509a:	c091                	beqz	s1,8000509e <argfd+0x4c>
    *pf = f;
    8000509c:	e09c                	sd	a5,0(s1)
}
    8000509e:	70a2                	ld	ra,40(sp)
    800050a0:	7402                	ld	s0,32(sp)
    800050a2:	64e2                	ld	s1,24(sp)
    800050a4:	6942                	ld	s2,16(sp)
    800050a6:	6145                	addi	sp,sp,48
    800050a8:	8082                	ret
    return -1;
    800050aa:	557d                	li	a0,-1
    800050ac:	bfcd                	j	8000509e <argfd+0x4c>
    800050ae:	557d                	li	a0,-1
    800050b0:	b7fd                	j	8000509e <argfd+0x4c>

00000000800050b2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050b2:	1101                	addi	sp,sp,-32
    800050b4:	ec06                	sd	ra,24(sp)
    800050b6:	e822                	sd	s0,16(sp)
    800050b8:	e426                	sd	s1,8(sp)
    800050ba:	1000                	addi	s0,sp,32
    800050bc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050be:	ffffd097          	auipc	ra,0xffffd
    800050c2:	966080e7          	jalr	-1690(ra) # 80001a24 <myproc>
    800050c6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c8:	0d050793          	addi	a5,a0,208
    800050cc:	4501                	li	a0,0
    800050ce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050d0:	6398                	ld	a4,0(a5)
    800050d2:	cb19                	beqz	a4,800050e8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050d4:	2505                	addiw	a0,a0,1
    800050d6:	07a1                	addi	a5,a5,8
    800050d8:	fed51ce3          	bne	a0,a3,800050d0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050dc:	557d                	li	a0,-1
}
    800050de:	60e2                	ld	ra,24(sp)
    800050e0:	6442                	ld	s0,16(sp)
    800050e2:	64a2                	ld	s1,8(sp)
    800050e4:	6105                	addi	sp,sp,32
    800050e6:	8082                	ret
      p->ofile[fd] = f;
    800050e8:	01a50793          	addi	a5,a0,26
    800050ec:	078e                	slli	a5,a5,0x3
    800050ee:	963e                	add	a2,a2,a5
    800050f0:	e204                	sd	s1,0(a2)
      return fd;
    800050f2:	b7f5                	j	800050de <fdalloc+0x2c>

00000000800050f4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050f4:	715d                	addi	sp,sp,-80
    800050f6:	e486                	sd	ra,72(sp)
    800050f8:	e0a2                	sd	s0,64(sp)
    800050fa:	fc26                	sd	s1,56(sp)
    800050fc:	f84a                	sd	s2,48(sp)
    800050fe:	f44e                	sd	s3,40(sp)
    80005100:	f052                	sd	s4,32(sp)
    80005102:	ec56                	sd	s5,24(sp)
    80005104:	e85a                	sd	s6,16(sp)
    80005106:	0880                	addi	s0,sp,80
    80005108:	8b2e                	mv	s6,a1
    8000510a:	89b2                	mv	s3,a2
    8000510c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000510e:	fb040593          	addi	a1,s0,-80
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	e14080e7          	jalr	-492(ra) # 80003f26 <nameiparent>
    8000511a:	84aa                	mv	s1,a0
    8000511c:	14050b63          	beqz	a0,80005272 <create+0x17e>
    return 0;

  ilock(dp);
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	642080e7          	jalr	1602(ra) # 80003762 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005128:	4601                	li	a2,0
    8000512a:	fb040593          	addi	a1,s0,-80
    8000512e:	8526                	mv	a0,s1
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	b16080e7          	jalr	-1258(ra) # 80003c46 <dirlookup>
    80005138:	8aaa                	mv	s5,a0
    8000513a:	c921                	beqz	a0,8000518a <create+0x96>
    iunlockput(dp);
    8000513c:	8526                	mv	a0,s1
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	886080e7          	jalr	-1914(ra) # 800039c4 <iunlockput>
    ilock(ip);
    80005146:	8556                	mv	a0,s5
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	61a080e7          	jalr	1562(ra) # 80003762 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005150:	4789                	li	a5,2
    80005152:	02fb1563          	bne	s6,a5,8000517c <create+0x88>
    80005156:	044ad783          	lhu	a5,68(s5)
    8000515a:	37f9                	addiw	a5,a5,-2
    8000515c:	17c2                	slli	a5,a5,0x30
    8000515e:	93c1                	srli	a5,a5,0x30
    80005160:	4705                	li	a4,1
    80005162:	00f76d63          	bltu	a4,a5,8000517c <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005166:	8556                	mv	a0,s5
    80005168:	60a6                	ld	ra,72(sp)
    8000516a:	6406                	ld	s0,64(sp)
    8000516c:	74e2                	ld	s1,56(sp)
    8000516e:	7942                	ld	s2,48(sp)
    80005170:	79a2                	ld	s3,40(sp)
    80005172:	7a02                	ld	s4,32(sp)
    80005174:	6ae2                	ld	s5,24(sp)
    80005176:	6b42                	ld	s6,16(sp)
    80005178:	6161                	addi	sp,sp,80
    8000517a:	8082                	ret
    iunlockput(ip);
    8000517c:	8556                	mv	a0,s5
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	846080e7          	jalr	-1978(ra) # 800039c4 <iunlockput>
    return 0;
    80005186:	4a81                	li	s5,0
    80005188:	bff9                	j	80005166 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000518a:	85da                	mv	a1,s6
    8000518c:	4088                	lw	a0,0(s1)
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	43c080e7          	jalr	1084(ra) # 800035ca <ialloc>
    80005196:	8a2a                	mv	s4,a0
    80005198:	c529                	beqz	a0,800051e2 <create+0xee>
  ilock(ip);
    8000519a:	ffffe097          	auipc	ra,0xffffe
    8000519e:	5c8080e7          	jalr	1480(ra) # 80003762 <ilock>
  ip->major = major;
    800051a2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051a6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051aa:	4905                	li	s2,1
    800051ac:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051b0:	8552                	mv	a0,s4
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	4e4080e7          	jalr	1252(ra) # 80003696 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ba:	032b0b63          	beq	s6,s2,800051f0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051be:	004a2603          	lw	a2,4(s4)
    800051c2:	fb040593          	addi	a1,s0,-80
    800051c6:	8526                	mv	a0,s1
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	c8e080e7          	jalr	-882(ra) # 80003e56 <dirlink>
    800051d0:	06054f63          	bltz	a0,8000524e <create+0x15a>
  iunlockput(dp);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	7ee080e7          	jalr	2030(ra) # 800039c4 <iunlockput>
  return ip;
    800051de:	8ad2                	mv	s5,s4
    800051e0:	b759                	j	80005166 <create+0x72>
    iunlockput(dp);
    800051e2:	8526                	mv	a0,s1
    800051e4:	ffffe097          	auipc	ra,0xffffe
    800051e8:	7e0080e7          	jalr	2016(ra) # 800039c4 <iunlockput>
    return 0;
    800051ec:	8ad2                	mv	s5,s4
    800051ee:	bfa5                	j	80005166 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f0:	004a2603          	lw	a2,4(s4)
    800051f4:	00003597          	auipc	a1,0x3
    800051f8:	57c58593          	addi	a1,a1,1404 # 80008770 <syscalls+0x318>
    800051fc:	8552                	mv	a0,s4
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	c58080e7          	jalr	-936(ra) # 80003e56 <dirlink>
    80005206:	04054463          	bltz	a0,8000524e <create+0x15a>
    8000520a:	40d0                	lw	a2,4(s1)
    8000520c:	00003597          	auipc	a1,0x3
    80005210:	56c58593          	addi	a1,a1,1388 # 80008778 <syscalls+0x320>
    80005214:	8552                	mv	a0,s4
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	c40080e7          	jalr	-960(ra) # 80003e56 <dirlink>
    8000521e:	02054863          	bltz	a0,8000524e <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005222:	004a2603          	lw	a2,4(s4)
    80005226:	fb040593          	addi	a1,s0,-80
    8000522a:	8526                	mv	a0,s1
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	c2a080e7          	jalr	-982(ra) # 80003e56 <dirlink>
    80005234:	00054d63          	bltz	a0,8000524e <create+0x15a>
    dp->nlink++;  // for ".."
    80005238:	04a4d783          	lhu	a5,74(s1)
    8000523c:	2785                	addiw	a5,a5,1
    8000523e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffe097          	auipc	ra,0xffffe
    80005248:	452080e7          	jalr	1106(ra) # 80003696 <iupdate>
    8000524c:	b761                	j	800051d4 <create+0xe0>
  ip->nlink = 0;
    8000524e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005252:	8552                	mv	a0,s4
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	442080e7          	jalr	1090(ra) # 80003696 <iupdate>
  iunlockput(ip);
    8000525c:	8552                	mv	a0,s4
    8000525e:	ffffe097          	auipc	ra,0xffffe
    80005262:	766080e7          	jalr	1894(ra) # 800039c4 <iunlockput>
  iunlockput(dp);
    80005266:	8526                	mv	a0,s1
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	75c080e7          	jalr	1884(ra) # 800039c4 <iunlockput>
  return 0;
    80005270:	bddd                	j	80005166 <create+0x72>
    return 0;
    80005272:	8aaa                	mv	s5,a0
    80005274:	bdcd                	j	80005166 <create+0x72>

0000000080005276 <sys_dup>:
{
    80005276:	7179                	addi	sp,sp,-48
    80005278:	f406                	sd	ra,40(sp)
    8000527a:	f022                	sd	s0,32(sp)
    8000527c:	ec26                	sd	s1,24(sp)
    8000527e:	e84a                	sd	s2,16(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005282:	fd840613          	addi	a2,s0,-40
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	dc8080e7          	jalr	-568(ra) # 80005052 <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005294:	02054363          	bltz	a0,800052ba <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005298:	fd843903          	ld	s2,-40(s0)
    8000529c:	854a                	mv	a0,s2
    8000529e:	00000097          	auipc	ra,0x0
    800052a2:	e14080e7          	jalr	-492(ra) # 800050b2 <fdalloc>
    800052a6:	84aa                	mv	s1,a0
    return -1;
    800052a8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052aa:	00054863          	bltz	a0,800052ba <sys_dup+0x44>
  filedup(f);
    800052ae:	854a                	mv	a0,s2
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	2ca080e7          	jalr	714(ra) # 8000457a <filedup>
  return fd;
    800052b8:	87a6                	mv	a5,s1
}
    800052ba:	853e                	mv	a0,a5
    800052bc:	70a2                	ld	ra,40(sp)
    800052be:	7402                	ld	s0,32(sp)
    800052c0:	64e2                	ld	s1,24(sp)
    800052c2:	6942                	ld	s2,16(sp)
    800052c4:	6145                	addi	sp,sp,48
    800052c6:	8082                	ret

00000000800052c8 <sys_read>:
{
    800052c8:	7179                	addi	sp,sp,-48
    800052ca:	f406                	sd	ra,40(sp)
    800052cc:	f022                	sd	s0,32(sp)
    800052ce:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d0:	fd840593          	addi	a1,s0,-40
    800052d4:	4505                	li	a0,1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	94a080e7          	jalr	-1718(ra) # 80002c20 <argaddr>
  argint(2, &n);
    800052de:	fe440593          	addi	a1,s0,-28
    800052e2:	4509                	li	a0,2
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	91c080e7          	jalr	-1764(ra) # 80002c00 <argint>
  if(argfd(0, 0, &f) < 0)
    800052ec:	fe840613          	addi	a2,s0,-24
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	d5e080e7          	jalr	-674(ra) # 80005052 <argfd>
    800052fc:	87aa                	mv	a5,a0
    return -1;
    800052fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005300:	0007cc63          	bltz	a5,80005318 <sys_read+0x50>
  return fileread(f, p, n);
    80005304:	fe442603          	lw	a2,-28(s0)
    80005308:	fd843583          	ld	a1,-40(s0)
    8000530c:	fe843503          	ld	a0,-24(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	3f6080e7          	jalr	1014(ra) # 80004706 <fileread>
}
    80005318:	70a2                	ld	ra,40(sp)
    8000531a:	7402                	ld	s0,32(sp)
    8000531c:	6145                	addi	sp,sp,48
    8000531e:	8082                	ret

0000000080005320 <sys_write>:
{
    80005320:	7179                	addi	sp,sp,-48
    80005322:	f406                	sd	ra,40(sp)
    80005324:	f022                	sd	s0,32(sp)
    80005326:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005328:	fd840593          	addi	a1,s0,-40
    8000532c:	4505                	li	a0,1
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	8f2080e7          	jalr	-1806(ra) # 80002c20 <argaddr>
  argint(2, &n);
    80005336:	fe440593          	addi	a1,s0,-28
    8000533a:	4509                	li	a0,2
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	8c4080e7          	jalr	-1852(ra) # 80002c00 <argint>
  if(argfd(0, 0, &f) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	d06080e7          	jalr	-762(ra) # 80005052 <argfd>
    80005354:	87aa                	mv	a5,a0
    return -1;
    80005356:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005358:	0007cc63          	bltz	a5,80005370 <sys_write+0x50>
  return filewrite(f, p, n);
    8000535c:	fe442603          	lw	a2,-28(s0)
    80005360:	fd843583          	ld	a1,-40(s0)
    80005364:	fe843503          	ld	a0,-24(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	460080e7          	jalr	1120(ra) # 800047c8 <filewrite>
}
    80005370:	70a2                	ld	ra,40(sp)
    80005372:	7402                	ld	s0,32(sp)
    80005374:	6145                	addi	sp,sp,48
    80005376:	8082                	ret

0000000080005378 <sys_close>:
{
    80005378:	1101                	addi	sp,sp,-32
    8000537a:	ec06                	sd	ra,24(sp)
    8000537c:	e822                	sd	s0,16(sp)
    8000537e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005380:	fe040613          	addi	a2,s0,-32
    80005384:	fec40593          	addi	a1,s0,-20
    80005388:	4501                	li	a0,0
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	cc8080e7          	jalr	-824(ra) # 80005052 <argfd>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005394:	02054463          	bltz	a0,800053bc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	68c080e7          	jalr	1676(ra) # 80001a24 <myproc>
    800053a0:	fec42783          	lw	a5,-20(s0)
    800053a4:	07e9                	addi	a5,a5,26
    800053a6:	078e                	slli	a5,a5,0x3
    800053a8:	953e                	add	a0,a0,a5
    800053aa:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053ae:	fe043503          	ld	a0,-32(s0)
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	21a080e7          	jalr	538(ra) # 800045cc <fileclose>
  return 0;
    800053ba:	4781                	li	a5,0
}
    800053bc:	853e                	mv	a0,a5
    800053be:	60e2                	ld	ra,24(sp)
    800053c0:	6442                	ld	s0,16(sp)
    800053c2:	6105                	addi	sp,sp,32
    800053c4:	8082                	ret

00000000800053c6 <sys_fstat>:
{
    800053c6:	1101                	addi	sp,sp,-32
    800053c8:	ec06                	sd	ra,24(sp)
    800053ca:	e822                	sd	s0,16(sp)
    800053cc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053ce:	fe040593          	addi	a1,s0,-32
    800053d2:	4505                	li	a0,1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	84c080e7          	jalr	-1972(ra) # 80002c20 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053dc:	fe840613          	addi	a2,s0,-24
    800053e0:	4581                	li	a1,0
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	c6e080e7          	jalr	-914(ra) # 80005052 <argfd>
    800053ec:	87aa                	mv	a5,a0
    return -1;
    800053ee:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f0:	0007ca63          	bltz	a5,80005404 <sys_fstat+0x3e>
  return filestat(f, st);
    800053f4:	fe043583          	ld	a1,-32(s0)
    800053f8:	fe843503          	ld	a0,-24(s0)
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	298080e7          	jalr	664(ra) # 80004694 <filestat>
}
    80005404:	60e2                	ld	ra,24(sp)
    80005406:	6442                	ld	s0,16(sp)
    80005408:	6105                	addi	sp,sp,32
    8000540a:	8082                	ret

000000008000540c <sys_link>:
{
    8000540c:	7169                	addi	sp,sp,-304
    8000540e:	f606                	sd	ra,296(sp)
    80005410:	f222                	sd	s0,288(sp)
    80005412:	ee26                	sd	s1,280(sp)
    80005414:	ea4a                	sd	s2,272(sp)
    80005416:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005418:	08000613          	li	a2,128
    8000541c:	ed040593          	addi	a1,s0,-304
    80005420:	4501                	li	a0,0
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	81e080e7          	jalr	-2018(ra) # 80002c40 <argstr>
    return -1;
    8000542a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542c:	10054e63          	bltz	a0,80005548 <sys_link+0x13c>
    80005430:	08000613          	li	a2,128
    80005434:	f5040593          	addi	a1,s0,-176
    80005438:	4505                	li	a0,1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	806080e7          	jalr	-2042(ra) # 80002c40 <argstr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005444:	10054263          	bltz	a0,80005548 <sys_link+0x13c>
  begin_op();
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	cc0080e7          	jalr	-832(ra) # 80004108 <begin_op>
  if((ip = namei(old)) == 0){
    80005450:	ed040513          	addi	a0,s0,-304
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	ab4080e7          	jalr	-1356(ra) # 80003f08 <namei>
    8000545c:	84aa                	mv	s1,a0
    8000545e:	c551                	beqz	a0,800054ea <sys_link+0xde>
  ilock(ip);
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	302080e7          	jalr	770(ra) # 80003762 <ilock>
  if(ip->type == T_DIR){
    80005468:	04449703          	lh	a4,68(s1)
    8000546c:	4785                	li	a5,1
    8000546e:	08f70463          	beq	a4,a5,800054f6 <sys_link+0xea>
  ip->nlink++;
    80005472:	04a4d783          	lhu	a5,74(s1)
    80005476:	2785                	addiw	a5,a5,1
    80005478:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	218080e7          	jalr	536(ra) # 80003696 <iupdate>
  iunlock(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	39c080e7          	jalr	924(ra) # 80003824 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005490:	fd040593          	addi	a1,s0,-48
    80005494:	f5040513          	addi	a0,s0,-176
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	a8e080e7          	jalr	-1394(ra) # 80003f26 <nameiparent>
    800054a0:	892a                	mv	s2,a0
    800054a2:	c935                	beqz	a0,80005516 <sys_link+0x10a>
  ilock(dp);
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	2be080e7          	jalr	702(ra) # 80003762 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ac:	00092703          	lw	a4,0(s2)
    800054b0:	409c                	lw	a5,0(s1)
    800054b2:	04f71d63          	bne	a4,a5,8000550c <sys_link+0x100>
    800054b6:	40d0                	lw	a2,4(s1)
    800054b8:	fd040593          	addi	a1,s0,-48
    800054bc:	854a                	mv	a0,s2
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	998080e7          	jalr	-1640(ra) # 80003e56 <dirlink>
    800054c6:	04054363          	bltz	a0,8000550c <sys_link+0x100>
  iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	4f8080e7          	jalr	1272(ra) # 800039c4 <iunlockput>
  iput(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	446080e7          	jalr	1094(ra) # 8000391c <iput>
  end_op();
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	ca4080e7          	jalr	-860(ra) # 80004182 <end_op>
  return 0;
    800054e6:	4781                	li	a5,0
    800054e8:	a085                	j	80005548 <sys_link+0x13c>
    end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	c98080e7          	jalr	-872(ra) # 80004182 <end_op>
    return -1;
    800054f2:	57fd                	li	a5,-1
    800054f4:	a891                	j	80005548 <sys_link+0x13c>
    iunlockput(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	4cc080e7          	jalr	1228(ra) # 800039c4 <iunlockput>
    end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	c82080e7          	jalr	-894(ra) # 80004182 <end_op>
    return -1;
    80005508:	57fd                	li	a5,-1
    8000550a:	a83d                	j	80005548 <sys_link+0x13c>
    iunlockput(dp);
    8000550c:	854a                	mv	a0,s2
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	4b6080e7          	jalr	1206(ra) # 800039c4 <iunlockput>
  ilock(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	24a080e7          	jalr	586(ra) # 80003762 <ilock>
  ip->nlink--;
    80005520:	04a4d783          	lhu	a5,74(s1)
    80005524:	37fd                	addiw	a5,a5,-1
    80005526:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	16a080e7          	jalr	362(ra) # 80003696 <iupdate>
  iunlockput(ip);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	48e080e7          	jalr	1166(ra) # 800039c4 <iunlockput>
  end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	c44080e7          	jalr	-956(ra) # 80004182 <end_op>
  return -1;
    80005546:	57fd                	li	a5,-1
}
    80005548:	853e                	mv	a0,a5
    8000554a:	70b2                	ld	ra,296(sp)
    8000554c:	7412                	ld	s0,288(sp)
    8000554e:	64f2                	ld	s1,280(sp)
    80005550:	6952                	ld	s2,272(sp)
    80005552:	6155                	addi	sp,sp,304
    80005554:	8082                	ret

0000000080005556 <sys_unlink>:
{
    80005556:	7151                	addi	sp,sp,-240
    80005558:	f586                	sd	ra,232(sp)
    8000555a:	f1a2                	sd	s0,224(sp)
    8000555c:	eda6                	sd	s1,216(sp)
    8000555e:	e9ca                	sd	s2,208(sp)
    80005560:	e5ce                	sd	s3,200(sp)
    80005562:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005564:	08000613          	li	a2,128
    80005568:	f3040593          	addi	a1,s0,-208
    8000556c:	4501                	li	a0,0
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	6d2080e7          	jalr	1746(ra) # 80002c40 <argstr>
    80005576:	18054163          	bltz	a0,800056f8 <sys_unlink+0x1a2>
  begin_op();
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	b8e080e7          	jalr	-1138(ra) # 80004108 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005582:	fb040593          	addi	a1,s0,-80
    80005586:	f3040513          	addi	a0,s0,-208
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	99c080e7          	jalr	-1636(ra) # 80003f26 <nameiparent>
    80005592:	84aa                	mv	s1,a0
    80005594:	c979                	beqz	a0,8000566a <sys_unlink+0x114>
  ilock(dp);
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	1cc080e7          	jalr	460(ra) # 80003762 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000559e:	00003597          	auipc	a1,0x3
    800055a2:	1d258593          	addi	a1,a1,466 # 80008770 <syscalls+0x318>
    800055a6:	fb040513          	addi	a0,s0,-80
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	682080e7          	jalr	1666(ra) # 80003c2c <namecmp>
    800055b2:	14050a63          	beqz	a0,80005706 <sys_unlink+0x1b0>
    800055b6:	00003597          	auipc	a1,0x3
    800055ba:	1c258593          	addi	a1,a1,450 # 80008778 <syscalls+0x320>
    800055be:	fb040513          	addi	a0,s0,-80
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	66a080e7          	jalr	1642(ra) # 80003c2c <namecmp>
    800055ca:	12050e63          	beqz	a0,80005706 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055ce:	f2c40613          	addi	a2,s0,-212
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	66e080e7          	jalr	1646(ra) # 80003c46 <dirlookup>
    800055e0:	892a                	mv	s2,a0
    800055e2:	12050263          	beqz	a0,80005706 <sys_unlink+0x1b0>
  ilock(ip);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	17c080e7          	jalr	380(ra) # 80003762 <ilock>
  if(ip->nlink < 1)
    800055ee:	04a91783          	lh	a5,74(s2)
    800055f2:	08f05263          	blez	a5,80005676 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f6:	04491703          	lh	a4,68(s2)
    800055fa:	4785                	li	a5,1
    800055fc:	08f70563          	beq	a4,a5,80005686 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005600:	4641                	li	a2,16
    80005602:	4581                	li	a1,0
    80005604:	fc040513          	addi	a0,s0,-64
    80005608:	ffffb097          	auipc	ra,0xffffb
    8000560c:	73c080e7          	jalr	1852(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005610:	4741                	li	a4,16
    80005612:	f2c42683          	lw	a3,-212(s0)
    80005616:	fc040613          	addi	a2,s0,-64
    8000561a:	4581                	li	a1,0
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	4f0080e7          	jalr	1264(ra) # 80003b0e <writei>
    80005626:	47c1                	li	a5,16
    80005628:	0af51563          	bne	a0,a5,800056d2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000562c:	04491703          	lh	a4,68(s2)
    80005630:	4785                	li	a5,1
    80005632:	0af70863          	beq	a4,a5,800056e2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	38c080e7          	jalr	908(ra) # 800039c4 <iunlockput>
  ip->nlink--;
    80005640:	04a95783          	lhu	a5,74(s2)
    80005644:	37fd                	addiw	a5,a5,-1
    80005646:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	04a080e7          	jalr	74(ra) # 80003696 <iupdate>
  iunlockput(ip);
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	36e080e7          	jalr	878(ra) # 800039c4 <iunlockput>
  end_op();
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	b24080e7          	jalr	-1244(ra) # 80004182 <end_op>
  return 0;
    80005666:	4501                	li	a0,0
    80005668:	a84d                	j	8000571a <sys_unlink+0x1c4>
    end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	b18080e7          	jalr	-1256(ra) # 80004182 <end_op>
    return -1;
    80005672:	557d                	li	a0,-1
    80005674:	a05d                	j	8000571a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005676:	00003517          	auipc	a0,0x3
    8000567a:	10a50513          	addi	a0,a0,266 # 80008780 <syscalls+0x328>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	ec2080e7          	jalr	-318(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005686:	04c92703          	lw	a4,76(s2)
    8000568a:	02000793          	li	a5,32
    8000568e:	f6e7f9e3          	bgeu	a5,a4,80005600 <sys_unlink+0xaa>
    80005692:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005696:	4741                	li	a4,16
    80005698:	86ce                	mv	a3,s3
    8000569a:	f1840613          	addi	a2,s0,-232
    8000569e:	4581                	li	a1,0
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	374080e7          	jalr	884(ra) # 80003a16 <readi>
    800056aa:	47c1                	li	a5,16
    800056ac:	00f51b63          	bne	a0,a5,800056c2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b0:	f1845783          	lhu	a5,-232(s0)
    800056b4:	e7a1                	bnez	a5,800056fc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b6:	29c1                	addiw	s3,s3,16
    800056b8:	04c92783          	lw	a5,76(s2)
    800056bc:	fcf9ede3          	bltu	s3,a5,80005696 <sys_unlink+0x140>
    800056c0:	b781                	j	80005600 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c2:	00003517          	auipc	a0,0x3
    800056c6:	0d650513          	addi	a0,a0,214 # 80008798 <syscalls+0x340>
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	e76080e7          	jalr	-394(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056d2:	00003517          	auipc	a0,0x3
    800056d6:	0de50513          	addi	a0,a0,222 # 800087b0 <syscalls+0x358>
    800056da:	ffffb097          	auipc	ra,0xffffb
    800056de:	e66080e7          	jalr	-410(ra) # 80000540 <panic>
    dp->nlink--;
    800056e2:	04a4d783          	lhu	a5,74(s1)
    800056e6:	37fd                	addiw	a5,a5,-1
    800056e8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	fa8080e7          	jalr	-88(ra) # 80003696 <iupdate>
    800056f6:	b781                	j	80005636 <sys_unlink+0xe0>
    return -1;
    800056f8:	557d                	li	a0,-1
    800056fa:	a005                	j	8000571a <sys_unlink+0x1c4>
    iunlockput(ip);
    800056fc:	854a                	mv	a0,s2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	2c6080e7          	jalr	710(ra) # 800039c4 <iunlockput>
  iunlockput(dp);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	2bc080e7          	jalr	700(ra) # 800039c4 <iunlockput>
  end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	a72080e7          	jalr	-1422(ra) # 80004182 <end_op>
  return -1;
    80005718:	557d                	li	a0,-1
}
    8000571a:	70ae                	ld	ra,232(sp)
    8000571c:	740e                	ld	s0,224(sp)
    8000571e:	64ee                	ld	s1,216(sp)
    80005720:	694e                	ld	s2,208(sp)
    80005722:	69ae                	ld	s3,200(sp)
    80005724:	616d                	addi	sp,sp,240
    80005726:	8082                	ret

0000000080005728 <sys_open>:

uint64
sys_open(void)
{
    80005728:	7131                	addi	sp,sp,-192
    8000572a:	fd06                	sd	ra,184(sp)
    8000572c:	f922                	sd	s0,176(sp)
    8000572e:	f526                	sd	s1,168(sp)
    80005730:	f14a                	sd	s2,160(sp)
    80005732:	ed4e                	sd	s3,152(sp)
    80005734:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005736:	f4c40593          	addi	a1,s0,-180
    8000573a:	4505                	li	a0,1
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	4c4080e7          	jalr	1220(ra) # 80002c00 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005744:	08000613          	li	a2,128
    80005748:	f5040593          	addi	a1,s0,-176
    8000574c:	4501                	li	a0,0
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	4f2080e7          	jalr	1266(ra) # 80002c40 <argstr>
    80005756:	87aa                	mv	a5,a0
    return -1;
    80005758:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575a:	0a07c863          	bltz	a5,8000580a <sys_open+0xe2>

  begin_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	9aa080e7          	jalr	-1622(ra) # 80004108 <begin_op>

  if(omode & O_CREATE){
    80005766:	f4c42783          	lw	a5,-180(s0)
    8000576a:	2007f793          	andi	a5,a5,512
    8000576e:	cbdd                	beqz	a5,80005824 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005770:	4681                	li	a3,0
    80005772:	4601                	li	a2,0
    80005774:	4589                	li	a1,2
    80005776:	f5040513          	addi	a0,s0,-176
    8000577a:	00000097          	auipc	ra,0x0
    8000577e:	97a080e7          	jalr	-1670(ra) # 800050f4 <create>
    80005782:	84aa                	mv	s1,a0
    if(ip == 0){
    80005784:	c951                	beqz	a0,80005818 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005786:	04449703          	lh	a4,68(s1)
    8000578a:	478d                	li	a5,3
    8000578c:	00f71763          	bne	a4,a5,8000579a <sys_open+0x72>
    80005790:	0464d703          	lhu	a4,70(s1)
    80005794:	47a5                	li	a5,9
    80005796:	0ce7ec63          	bltu	a5,a4,8000586e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	d76080e7          	jalr	-650(ra) # 80004510 <filealloc>
    800057a2:	892a                	mv	s2,a0
    800057a4:	c56d                	beqz	a0,8000588e <sys_open+0x166>
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	90c080e7          	jalr	-1780(ra) # 800050b2 <fdalloc>
    800057ae:	89aa                	mv	s3,a0
    800057b0:	0c054a63          	bltz	a0,80005884 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b4:	04449703          	lh	a4,68(s1)
    800057b8:	478d                	li	a5,3
    800057ba:	0ef70563          	beq	a4,a5,800058a4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057be:	4789                	li	a5,2
    800057c0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800057c4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800057c8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800057cc:	f4c42783          	lw	a5,-180(s0)
    800057d0:	0017c713          	xori	a4,a5,1
    800057d4:	8b05                	andi	a4,a4,1
    800057d6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057da:	0037f713          	andi	a4,a5,3
    800057de:	00e03733          	snez	a4,a4
    800057e2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e6:	4007f793          	andi	a5,a5,1024
    800057ea:	c791                	beqz	a5,800057f6 <sys_open+0xce>
    800057ec:	04449703          	lh	a4,68(s1)
    800057f0:	4789                	li	a5,2
    800057f2:	0cf70063          	beq	a4,a5,800058b2 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	02c080e7          	jalr	44(ra) # 80003824 <iunlock>
  end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	982080e7          	jalr	-1662(ra) # 80004182 <end_op>

  return fd;
    80005808:	854e                	mv	a0,s3
}
    8000580a:	70ea                	ld	ra,184(sp)
    8000580c:	744a                	ld	s0,176(sp)
    8000580e:	74aa                	ld	s1,168(sp)
    80005810:	790a                	ld	s2,160(sp)
    80005812:	69ea                	ld	s3,152(sp)
    80005814:	6129                	addi	sp,sp,192
    80005816:	8082                	ret
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	96a080e7          	jalr	-1686(ra) # 80004182 <end_op>
      return -1;
    80005820:	557d                	li	a0,-1
    80005822:	b7e5                	j	8000580a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005824:	f5040513          	addi	a0,s0,-176
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	6e0080e7          	jalr	1760(ra) # 80003f08 <namei>
    80005830:	84aa                	mv	s1,a0
    80005832:	c905                	beqz	a0,80005862 <sys_open+0x13a>
    ilock(ip);
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	f2e080e7          	jalr	-210(ra) # 80003762 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000583c:	04449703          	lh	a4,68(s1)
    80005840:	4785                	li	a5,1
    80005842:	f4f712e3          	bne	a4,a5,80005786 <sys_open+0x5e>
    80005846:	f4c42783          	lw	a5,-180(s0)
    8000584a:	dba1                	beqz	a5,8000579a <sys_open+0x72>
      iunlockput(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	176080e7          	jalr	374(ra) # 800039c4 <iunlockput>
      end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	92c080e7          	jalr	-1748(ra) # 80004182 <end_op>
      return -1;
    8000585e:	557d                	li	a0,-1
    80005860:	b76d                	j	8000580a <sys_open+0xe2>
      end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	920080e7          	jalr	-1760(ra) # 80004182 <end_op>
      return -1;
    8000586a:	557d                	li	a0,-1
    8000586c:	bf79                	j	8000580a <sys_open+0xe2>
    iunlockput(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	154080e7          	jalr	340(ra) # 800039c4 <iunlockput>
    end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	90a080e7          	jalr	-1782(ra) # 80004182 <end_op>
    return -1;
    80005880:	557d                	li	a0,-1
    80005882:	b761                	j	8000580a <sys_open+0xe2>
      fileclose(f);
    80005884:	854a                	mv	a0,s2
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	d46080e7          	jalr	-698(ra) # 800045cc <fileclose>
    iunlockput(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	134080e7          	jalr	308(ra) # 800039c4 <iunlockput>
    end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	8ea080e7          	jalr	-1814(ra) # 80004182 <end_op>
    return -1;
    800058a0:	557d                	li	a0,-1
    800058a2:	b7a5                	j	8000580a <sys_open+0xe2>
    f->type = FD_DEVICE;
    800058a4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800058a8:	04649783          	lh	a5,70(s1)
    800058ac:	02f91223          	sh	a5,36(s2)
    800058b0:	bf21                	j	800057c8 <sys_open+0xa0>
    itrunc(ip);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	fbc080e7          	jalr	-68(ra) # 80003870 <itrunc>
    800058bc:	bf2d                	j	800057f6 <sys_open+0xce>

00000000800058be <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058be:	7175                	addi	sp,sp,-144
    800058c0:	e506                	sd	ra,136(sp)
    800058c2:	e122                	sd	s0,128(sp)
    800058c4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	842080e7          	jalr	-1982(ra) # 80004108 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ce:	08000613          	li	a2,128
    800058d2:	f7040593          	addi	a1,s0,-144
    800058d6:	4501                	li	a0,0
    800058d8:	ffffd097          	auipc	ra,0xffffd
    800058dc:	368080e7          	jalr	872(ra) # 80002c40 <argstr>
    800058e0:	02054963          	bltz	a0,80005912 <sys_mkdir+0x54>
    800058e4:	4681                	li	a3,0
    800058e6:	4601                	li	a2,0
    800058e8:	4585                	li	a1,1
    800058ea:	f7040513          	addi	a0,s0,-144
    800058ee:	00000097          	auipc	ra,0x0
    800058f2:	806080e7          	jalr	-2042(ra) # 800050f4 <create>
    800058f6:	cd11                	beqz	a0,80005912 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	0cc080e7          	jalr	204(ra) # 800039c4 <iunlockput>
  end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	882080e7          	jalr	-1918(ra) # 80004182 <end_op>
  return 0;
    80005908:	4501                	li	a0,0
}
    8000590a:	60aa                	ld	ra,136(sp)
    8000590c:	640a                	ld	s0,128(sp)
    8000590e:	6149                	addi	sp,sp,144
    80005910:	8082                	ret
    end_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	870080e7          	jalr	-1936(ra) # 80004182 <end_op>
    return -1;
    8000591a:	557d                	li	a0,-1
    8000591c:	b7fd                	j	8000590a <sys_mkdir+0x4c>

000000008000591e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000591e:	7135                	addi	sp,sp,-160
    80005920:	ed06                	sd	ra,152(sp)
    80005922:	e922                	sd	s0,144(sp)
    80005924:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	7e2080e7          	jalr	2018(ra) # 80004108 <begin_op>
  argint(1, &major);
    8000592e:	f6c40593          	addi	a1,s0,-148
    80005932:	4505                	li	a0,1
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	2cc080e7          	jalr	716(ra) # 80002c00 <argint>
  argint(2, &minor);
    8000593c:	f6840593          	addi	a1,s0,-152
    80005940:	4509                	li	a0,2
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	2be080e7          	jalr	702(ra) # 80002c00 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594a:	08000613          	li	a2,128
    8000594e:	f7040593          	addi	a1,s0,-144
    80005952:	4501                	li	a0,0
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	2ec080e7          	jalr	748(ra) # 80002c40 <argstr>
    8000595c:	02054b63          	bltz	a0,80005992 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005960:	f6841683          	lh	a3,-152(s0)
    80005964:	f6c41603          	lh	a2,-148(s0)
    80005968:	458d                	li	a1,3
    8000596a:	f7040513          	addi	a0,s0,-144
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	786080e7          	jalr	1926(ra) # 800050f4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005976:	cd11                	beqz	a0,80005992 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	04c080e7          	jalr	76(ra) # 800039c4 <iunlockput>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	802080e7          	jalr	-2046(ra) # 80004182 <end_op>
  return 0;
    80005988:	4501                	li	a0,0
}
    8000598a:	60ea                	ld	ra,152(sp)
    8000598c:	644a                	ld	s0,144(sp)
    8000598e:	610d                	addi	sp,sp,160
    80005990:	8082                	ret
    end_op();
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	7f0080e7          	jalr	2032(ra) # 80004182 <end_op>
    return -1;
    8000599a:	557d                	li	a0,-1
    8000599c:	b7fd                	j	8000598a <sys_mknod+0x6c>

000000008000599e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000599e:	7135                	addi	sp,sp,-160
    800059a0:	ed06                	sd	ra,152(sp)
    800059a2:	e922                	sd	s0,144(sp)
    800059a4:	e526                	sd	s1,136(sp)
    800059a6:	e14a                	sd	s2,128(sp)
    800059a8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059aa:	ffffc097          	auipc	ra,0xffffc
    800059ae:	07a080e7          	jalr	122(ra) # 80001a24 <myproc>
    800059b2:	892a                	mv	s2,a0
  
  begin_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	754080e7          	jalr	1876(ra) # 80004108 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059bc:	08000613          	li	a2,128
    800059c0:	f6040593          	addi	a1,s0,-160
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	27a080e7          	jalr	634(ra) # 80002c40 <argstr>
    800059ce:	04054b63          	bltz	a0,80005a24 <sys_chdir+0x86>
    800059d2:	f6040513          	addi	a0,s0,-160
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	532080e7          	jalr	1330(ra) # 80003f08 <namei>
    800059de:	84aa                	mv	s1,a0
    800059e0:	c131                	beqz	a0,80005a24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	d80080e7          	jalr	-640(ra) # 80003762 <ilock>
  if(ip->type != T_DIR){
    800059ea:	04449703          	lh	a4,68(s1)
    800059ee:	4785                	li	a5,1
    800059f0:	04f71063          	bne	a4,a5,80005a30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	e2e080e7          	jalr	-466(ra) # 80003824 <iunlock>
  iput(p->cwd);
    800059fe:	15093503          	ld	a0,336(s2)
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	f1a080e7          	jalr	-230(ra) # 8000391c <iput>
  end_op();
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	778080e7          	jalr	1912(ra) # 80004182 <end_op>
  p->cwd = ip;
    80005a12:	14993823          	sd	s1,336(s2)
  return 0;
    80005a16:	4501                	li	a0,0
}
    80005a18:	60ea                	ld	ra,152(sp)
    80005a1a:	644a                	ld	s0,144(sp)
    80005a1c:	64aa                	ld	s1,136(sp)
    80005a1e:	690a                	ld	s2,128(sp)
    80005a20:	610d                	addi	sp,sp,160
    80005a22:	8082                	ret
    end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	75e080e7          	jalr	1886(ra) # 80004182 <end_op>
    return -1;
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7ed                	j	80005a18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	f92080e7          	jalr	-110(ra) # 800039c4 <iunlockput>
    end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	748080e7          	jalr	1864(ra) # 80004182 <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	bfd1                	j	80005a18 <sys_chdir+0x7a>

0000000080005a46 <sys_exec>:

uint64
sys_exec(void)
{
    80005a46:	7121                	addi	sp,sp,-448
    80005a48:	ff06                	sd	ra,440(sp)
    80005a4a:	fb22                	sd	s0,432(sp)
    80005a4c:	f726                	sd	s1,424(sp)
    80005a4e:	f34a                	sd	s2,416(sp)
    80005a50:	ef4e                	sd	s3,408(sp)
    80005a52:	eb52                	sd	s4,400(sp)
    80005a54:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a56:	e4840593          	addi	a1,s0,-440
    80005a5a:	4505                	li	a0,1
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	1c4080e7          	jalr	452(ra) # 80002c20 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a64:	08000613          	li	a2,128
    80005a68:	f5040593          	addi	a1,s0,-176
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	1d2080e7          	jalr	466(ra) # 80002c40 <argstr>
    80005a76:	87aa                	mv	a5,a0
    return -1;
    80005a78:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a7a:	0c07c263          	bltz	a5,80005b3e <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a7e:	10000613          	li	a2,256
    80005a82:	4581                	li	a1,0
    80005a84:	e5040513          	addi	a0,s0,-432
    80005a88:	ffffb097          	auipc	ra,0xffffb
    80005a8c:	2bc080e7          	jalr	700(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a90:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a94:	89a6                	mv	s3,s1
    80005a96:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a98:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a9c:	00391513          	slli	a0,s2,0x3
    80005aa0:	e4040593          	addi	a1,s0,-448
    80005aa4:	e4843783          	ld	a5,-440(s0)
    80005aa8:	953e                	add	a0,a0,a5
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	0b8080e7          	jalr	184(ra) # 80002b62 <fetchaddr>
    80005ab2:	02054a63          	bltz	a0,80005ae6 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ab6:	e4043783          	ld	a5,-448(s0)
    80005aba:	c3b9                	beqz	a5,80005b00 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005abc:	ffffb097          	auipc	ra,0xffffb
    80005ac0:	09c080e7          	jalr	156(ra) # 80000b58 <kalloc>
    80005ac4:	85aa                	mv	a1,a0
    80005ac6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aca:	cd11                	beqz	a0,80005ae6 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005acc:	6605                	lui	a2,0x1
    80005ace:	e4043503          	ld	a0,-448(s0)
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	0e2080e7          	jalr	226(ra) # 80002bb4 <fetchstr>
    80005ada:	00054663          	bltz	a0,80005ae6 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ade:	0905                	addi	s2,s2,1
    80005ae0:	09a1                	addi	s3,s3,8
    80005ae2:	fb491de3          	bne	s2,s4,80005a9c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae6:	f5040913          	addi	s2,s0,-176
    80005aea:	6088                	ld	a0,0(s1)
    80005aec:	c921                	beqz	a0,80005b3c <sys_exec+0xf6>
    kfree(argv[i]);
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	f6c080e7          	jalr	-148(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af6:	04a1                	addi	s1,s1,8
    80005af8:	ff2499e3          	bne	s1,s2,80005aea <sys_exec+0xa4>
  return -1;
    80005afc:	557d                	li	a0,-1
    80005afe:	a081                	j	80005b3e <sys_exec+0xf8>
      argv[i] = 0;
    80005b00:	0009079b          	sext.w	a5,s2
    80005b04:	078e                	slli	a5,a5,0x3
    80005b06:	fd078793          	addi	a5,a5,-48
    80005b0a:	97a2                	add	a5,a5,s0
    80005b0c:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005b10:	e5040593          	addi	a1,s0,-432
    80005b14:	f5040513          	addi	a0,s0,-176
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	12a080e7          	jalr	298(ra) # 80004c42 <exec>
    80005b20:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b22:	f5040993          	addi	s3,s0,-176
    80005b26:	6088                	ld	a0,0(s1)
    80005b28:	c901                	beqz	a0,80005b38 <sys_exec+0xf2>
    kfree(argv[i]);
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	f30080e7          	jalr	-208(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b32:	04a1                	addi	s1,s1,8
    80005b34:	ff3499e3          	bne	s1,s3,80005b26 <sys_exec+0xe0>
  return ret;
    80005b38:	854a                	mv	a0,s2
    80005b3a:	a011                	j	80005b3e <sys_exec+0xf8>
  return -1;
    80005b3c:	557d                	li	a0,-1
}
    80005b3e:	70fa                	ld	ra,440(sp)
    80005b40:	745a                	ld	s0,432(sp)
    80005b42:	74ba                	ld	s1,424(sp)
    80005b44:	791a                	ld	s2,416(sp)
    80005b46:	69fa                	ld	s3,408(sp)
    80005b48:	6a5a                	ld	s4,400(sp)
    80005b4a:	6139                	addi	sp,sp,448
    80005b4c:	8082                	ret

0000000080005b4e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b4e:	7139                	addi	sp,sp,-64
    80005b50:	fc06                	sd	ra,56(sp)
    80005b52:	f822                	sd	s0,48(sp)
    80005b54:	f426                	sd	s1,40(sp)
    80005b56:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	ecc080e7          	jalr	-308(ra) # 80001a24 <myproc>
    80005b60:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b62:	fd840593          	addi	a1,s0,-40
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	0b8080e7          	jalr	184(ra) # 80002c20 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b70:	fc840593          	addi	a1,s0,-56
    80005b74:	fd040513          	addi	a0,s0,-48
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	d80080e7          	jalr	-640(ra) # 800048f8 <pipealloc>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b82:	0c054463          	bltz	a0,80005c4a <sys_pipe+0xfc>
  fd0 = -1;
    80005b86:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b8a:	fd043503          	ld	a0,-48(s0)
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	524080e7          	jalr	1316(ra) # 800050b2 <fdalloc>
    80005b96:	fca42223          	sw	a0,-60(s0)
    80005b9a:	08054b63          	bltz	a0,80005c30 <sys_pipe+0xe2>
    80005b9e:	fc843503          	ld	a0,-56(s0)
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	510080e7          	jalr	1296(ra) # 800050b2 <fdalloc>
    80005baa:	fca42023          	sw	a0,-64(s0)
    80005bae:	06054863          	bltz	a0,80005c1e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb2:	4691                	li	a3,4
    80005bb4:	fc440613          	addi	a2,s0,-60
    80005bb8:	fd843583          	ld	a1,-40(s0)
    80005bbc:	68a8                	ld	a0,80(s1)
    80005bbe:	ffffc097          	auipc	ra,0xffffc
    80005bc2:	b26080e7          	jalr	-1242(ra) # 800016e4 <copyout>
    80005bc6:	02054063          	bltz	a0,80005be6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bca:	4691                	li	a3,4
    80005bcc:	fc040613          	addi	a2,s0,-64
    80005bd0:	fd843583          	ld	a1,-40(s0)
    80005bd4:	0591                	addi	a1,a1,4
    80005bd6:	68a8                	ld	a0,80(s1)
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	b0c080e7          	jalr	-1268(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005be0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be2:	06055463          	bgez	a0,80005c4a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005be6:	fc442783          	lw	a5,-60(s0)
    80005bea:	07e9                	addi	a5,a5,26
    80005bec:	078e                	slli	a5,a5,0x3
    80005bee:	97a6                	add	a5,a5,s1
    80005bf0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bf4:	fc042783          	lw	a5,-64(s0)
    80005bf8:	07e9                	addi	a5,a5,26
    80005bfa:	078e                	slli	a5,a5,0x3
    80005bfc:	94be                	add	s1,s1,a5
    80005bfe:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c02:	fd043503          	ld	a0,-48(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	9c6080e7          	jalr	-1594(ra) # 800045cc <fileclose>
    fileclose(wf);
    80005c0e:	fc843503          	ld	a0,-56(s0)
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	9ba080e7          	jalr	-1606(ra) # 800045cc <fileclose>
    return -1;
    80005c1a:	57fd                	li	a5,-1
    80005c1c:	a03d                	j	80005c4a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c1e:	fc442783          	lw	a5,-60(s0)
    80005c22:	0007c763          	bltz	a5,80005c30 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c26:	07e9                	addi	a5,a5,26
    80005c28:	078e                	slli	a5,a5,0x3
    80005c2a:	97a6                	add	a5,a5,s1
    80005c2c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c30:	fd043503          	ld	a0,-48(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	998080e7          	jalr	-1640(ra) # 800045cc <fileclose>
    fileclose(wf);
    80005c3c:	fc843503          	ld	a0,-56(s0)
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	98c080e7          	jalr	-1652(ra) # 800045cc <fileclose>
    return -1;
    80005c48:	57fd                	li	a5,-1
}
    80005c4a:	853e                	mv	a0,a5
    80005c4c:	70e2                	ld	ra,56(sp)
    80005c4e:	7442                	ld	s0,48(sp)
    80005c50:	74a2                	ld	s1,40(sp)
    80005c52:	6121                	addi	sp,sp,64
    80005c54:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	d8ffc0ef          	jal	ra,80002a2e <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	cc0080e7          	jalr	-832(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	97aa                	add	a5,a5,a0
    80005d5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c88080e7          	jalr	-888(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5151b          	slliw	a0,a0,0xd
    80005d7c:	0c2017b7          	lui	a5,0xc201
    80005d80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d82:	43c8                	lw	a0,4(a5)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c60080e7          	jalr	-928(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	04a7cc63          	blt	a5,a0,80005e18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001c797          	auipc	a5,0x1c
    80005dc8:	13c78793          	addi	a5,a5,316 # 80021f00 <disk>
    80005dcc:	97aa                	add	a5,a5,a0
    80005dce:	0187c783          	lbu	a5,24(a5)
    80005dd2:	ebb9                	bnez	a5,80005e28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dd4:	00451693          	slli	a3,a0,0x4
    80005dd8:	0001c797          	auipc	a5,0x1c
    80005ddc:	12878793          	addi	a5,a5,296 # 80021f00 <disk>
    80005de0:	6398                	ld	a4,0(a5)
    80005de2:	9736                	add	a4,a4,a3
    80005de4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005de8:	6398                	ld	a4,0(a5)
    80005dea:	9736                	add	a4,a4,a3
    80005dec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005df0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005df4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	4705                	li	a4,1
    80005dfc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e00:	0001c517          	auipc	a0,0x1c
    80005e04:	11850513          	addi	a0,a0,280 # 80021f18 <disk+0x18>
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	356080e7          	jalr	854(ra) # 8000215e <wakeup>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret
    panic("free_desc 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	9a850513          	addi	a0,a0,-1624 # 800087c0 <syscalls+0x368>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	720080e7          	jalr	1824(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	9a850513          	addi	a0,a0,-1624 # 800087d0 <syscalls+0x378>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	710080e7          	jalr	1808(ra) # 80000540 <panic>

0000000080005e38 <virtio_disk_init>:
{
    80005e38:	1101                	addi	sp,sp,-32
    80005e3a:	ec06                	sd	ra,24(sp)
    80005e3c:	e822                	sd	s0,16(sp)
    80005e3e:	e426                	sd	s1,8(sp)
    80005e40:	e04a                	sd	s2,0(sp)
    80005e42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e44:	00003597          	auipc	a1,0x3
    80005e48:	99c58593          	addi	a1,a1,-1636 # 800087e0 <syscalls+0x388>
    80005e4c:	0001c517          	auipc	a0,0x1c
    80005e50:	1dc50513          	addi	a0,a0,476 # 80022028 <disk+0x128>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	d64080e7          	jalr	-668(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e5c:	100017b7          	lui	a5,0x10001
    80005e60:	4398                	lw	a4,0(a5)
    80005e62:	2701                	sext.w	a4,a4
    80005e64:	747277b7          	lui	a5,0x74727
    80005e68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e6c:	14f71b63          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e70:	100017b7          	lui	a5,0x10001
    80005e74:	43dc                	lw	a5,4(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e78:	4709                	li	a4,2
    80005e7a:	14e79463          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	479c                	lw	a5,8(a5)
    80005e84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e86:	12e79e63          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	47d8                	lw	a4,12(a5)
    80005e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e92:	554d47b7          	lui	a5,0x554d4
    80005e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e9a:	12f71463          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	4705                	li	a4,1
    80005ea8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	470d                	li	a4,3
    80005eac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eb0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005eb4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc4d7>
    80005eb8:	8f75                	and	a4,a4,a3
    80005eba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebc:	472d                	li	a4,11
    80005ebe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ec0:	5bbc                	lw	a5,112(a5)
    80005ec2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ec6:	8ba1                	andi	a5,a5,8
    80005ec8:	10078563          	beqz	a5,80005fd2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ecc:	100017b7          	lui	a5,0x10001
    80005ed0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ed4:	43fc                	lw	a5,68(a5)
    80005ed6:	2781                	sext.w	a5,a5
    80005ed8:	10079563          	bnez	a5,80005fe2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	5bdc                	lw	a5,52(a5)
    80005ee2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee4:	10078763          	beqz	a5,80005ff2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ee8:	471d                	li	a4,7
    80005eea:	10f77c63          	bgeu	a4,a5,80006002 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	c6a080e7          	jalr	-918(ra) # 80000b58 <kalloc>
    80005ef6:	0001c497          	auipc	s1,0x1c
    80005efa:	00a48493          	addi	s1,s1,10 # 80021f00 <disk>
    80005efe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	c58080e7          	jalr	-936(ra) # 80000b58 <kalloc>
    80005f08:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f0a:	ffffb097          	auipc	ra,0xffffb
    80005f0e:	c4e080e7          	jalr	-946(ra) # 80000b58 <kalloc>
    80005f12:	87aa                	mv	a5,a0
    80005f14:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f16:	6088                	ld	a0,0(s1)
    80005f18:	cd6d                	beqz	a0,80006012 <virtio_disk_init+0x1da>
    80005f1a:	0001c717          	auipc	a4,0x1c
    80005f1e:	fee73703          	ld	a4,-18(a4) # 80021f08 <disk+0x8>
    80005f22:	cb65                	beqz	a4,80006012 <virtio_disk_init+0x1da>
    80005f24:	c7fd                	beqz	a5,80006012 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f26:	6605                	lui	a2,0x1
    80005f28:	4581                	li	a1,0
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	e1a080e7          	jalr	-486(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f32:	0001c497          	auipc	s1,0x1c
    80005f36:	fce48493          	addi	s1,s1,-50 # 80021f00 <disk>
    80005f3a:	6605                	lui	a2,0x1
    80005f3c:	4581                	li	a1,0
    80005f3e:	6488                	ld	a0,8(s1)
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	e04080e7          	jalr	-508(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f48:	6605                	lui	a2,0x1
    80005f4a:	4581                	li	a1,0
    80005f4c:	6888                	ld	a0,16(s1)
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	df6080e7          	jalr	-522(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f56:	100017b7          	lui	a5,0x10001
    80005f5a:	4721                	li	a4,8
    80005f5c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f5e:	4098                	lw	a4,0(s1)
    80005f60:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f64:	40d8                	lw	a4,4(s1)
    80005f66:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f6a:	6498                	ld	a4,8(s1)
    80005f6c:	0007069b          	sext.w	a3,a4
    80005f70:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f74:	9701                	srai	a4,a4,0x20
    80005f76:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f7a:	6898                	ld	a4,16(s1)
    80005f7c:	0007069b          	sext.w	a3,a4
    80005f80:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f84:	9701                	srai	a4,a4,0x20
    80005f86:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f8a:	4705                	li	a4,1
    80005f8c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f8e:	00e48c23          	sb	a4,24(s1)
    80005f92:	00e48ca3          	sb	a4,25(s1)
    80005f96:	00e48d23          	sb	a4,26(s1)
    80005f9a:	00e48da3          	sb	a4,27(s1)
    80005f9e:	00e48e23          	sb	a4,28(s1)
    80005fa2:	00e48ea3          	sb	a4,29(s1)
    80005fa6:	00e48f23          	sb	a4,30(s1)
    80005faa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb2:	0727a823          	sw	s2,112(a5)
}
    80005fb6:	60e2                	ld	ra,24(sp)
    80005fb8:	6442                	ld	s0,16(sp)
    80005fba:	64a2                	ld	s1,8(sp)
    80005fbc:	6902                	ld	s2,0(sp)
    80005fbe:	6105                	addi	sp,sp,32
    80005fc0:	8082                	ret
    panic("could not find virtio disk");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	82e50513          	addi	a0,a0,-2002 # 800087f0 <syscalls+0x398>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	83e50513          	addi	a0,a0,-1986 # 80008810 <syscalls+0x3b8>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	84e50513          	addi	a0,a0,-1970 # 80008830 <syscalls+0x3d8>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	85e50513          	addi	a0,a0,-1954 # 80008850 <syscalls+0x3f8>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	86e50513          	addi	a0,a0,-1938 # 80008870 <syscalls+0x418>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	87e50513          	addi	a0,a0,-1922 # 80008890 <syscalls+0x438>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>

0000000080006022 <virtio_disk_init_bootloader>:
{
    80006022:	1101                	addi	sp,sp,-32
    80006024:	ec06                	sd	ra,24(sp)
    80006026:	e822                	sd	s0,16(sp)
    80006028:	e426                	sd	s1,8(sp)
    8000602a:	e04a                	sd	s2,0(sp)
    8000602c:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000602e:	00002597          	auipc	a1,0x2
    80006032:	7b258593          	addi	a1,a1,1970 # 800087e0 <syscalls+0x388>
    80006036:	0001c517          	auipc	a0,0x1c
    8000603a:	ff250513          	addi	a0,a0,-14 # 80022028 <disk+0x128>
    8000603e:	ffffb097          	auipc	ra,0xffffb
    80006042:	b7a080e7          	jalr	-1158(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006046:	100017b7          	lui	a5,0x10001
    8000604a:	4398                	lw	a4,0(a5)
    8000604c:	2701                	sext.w	a4,a4
    8000604e:	747277b7          	lui	a5,0x74727
    80006052:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006056:	12f71763          	bne	a4,a5,80006184 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000605a:	100017b7          	lui	a5,0x10001
    8000605e:	43dc                	lw	a5,4(a5)
    80006060:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006062:	4709                	li	a4,2
    80006064:	12e79063          	bne	a5,a4,80006184 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	479c                	lw	a5,8(a5)
    8000606e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006070:	10e79a63          	bne	a5,a4,80006184 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	47d8                	lw	a4,12(a5)
    8000607a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000607c:	554d47b7          	lui	a5,0x554d4
    80006080:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006084:	10f71063          	bne	a4,a5,80006184 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006090:	4705                	li	a4,1
    80006092:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006094:	470d                	li	a4,3
    80006096:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006098:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000609a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000609e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc4d7>
    800060a2:	8f75                	and	a4,a4,a3
    800060a4:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a6:	472d                	li	a4,11
    800060a8:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060aa:	5bbc                	lw	a5,112(a5)
    800060ac:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060b0:	8ba1                	andi	a5,a5,8
    800060b2:	c3ed                	beqz	a5,80006194 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060b4:	100017b7          	lui	a5,0x10001
    800060b8:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060bc:	43fc                	lw	a5,68(a5)
    800060be:	2781                	sext.w	a5,a5
    800060c0:	e3f5                	bnez	a5,800061a4 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060c2:	100017b7          	lui	a5,0x10001
    800060c6:	5bdc                	lw	a5,52(a5)
    800060c8:	2781                	sext.w	a5,a5
  if(max == 0)
    800060ca:	c7ed                	beqz	a5,800061b4 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    800060cc:	471d                	li	a4,7
    800060ce:	0ef77b63          	bgeu	a4,a5,800061c4 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    800060d2:	0001c497          	auipc	s1,0x1c
    800060d6:	e2e48493          	addi	s1,s1,-466 # 80021f00 <disk>
    800060da:	770007b7          	lui	a5,0x77000
    800060de:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060e0:	770017b7          	lui	a5,0x77001
    800060e4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060e6:	770027b7          	lui	a5,0x77002
    800060ea:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060ec:	6605                	lui	a2,0x1
    800060ee:	4581                	li	a1,0
    800060f0:	77000537          	lui	a0,0x77000
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	c50080e7          	jalr	-944(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060fc:	6605                	lui	a2,0x1
    800060fe:	4581                	li	a1,0
    80006100:	6488                	ld	a0,8(s1)
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	c42080e7          	jalr	-958(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    8000610a:	6605                	lui	a2,0x1
    8000610c:	4581                	li	a1,0
    8000610e:	6888                	ld	a0,16(s1)
    80006110:	ffffb097          	auipc	ra,0xffffb
    80006114:	c34080e7          	jalr	-972(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006118:	100017b7          	lui	a5,0x10001
    8000611c:	4721                	li	a4,8
    8000611e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006120:	4098                	lw	a4,0(s1)
    80006122:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006126:	40d8                	lw	a4,4(s1)
    80006128:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000612c:	6498                	ld	a4,8(s1)
    8000612e:	0007069b          	sext.w	a3,a4
    80006132:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006136:	9701                	srai	a4,a4,0x20
    80006138:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000613c:	6898                	ld	a4,16(s1)
    8000613e:	0007069b          	sext.w	a3,a4
    80006142:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006146:	9701                	srai	a4,a4,0x20
    80006148:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000614c:	4705                	li	a4,1
    8000614e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006150:	00e48c23          	sb	a4,24(s1)
    80006154:	00e48ca3          	sb	a4,25(s1)
    80006158:	00e48d23          	sb	a4,26(s1)
    8000615c:	00e48da3          	sb	a4,27(s1)
    80006160:	00e48e23          	sb	a4,28(s1)
    80006164:	00e48ea3          	sb	a4,29(s1)
    80006168:	00e48f23          	sb	a4,30(s1)
    8000616c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006170:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006174:	0727a823          	sw	s2,112(a5)
}
    80006178:	60e2                	ld	ra,24(sp)
    8000617a:	6442                	ld	s0,16(sp)
    8000617c:	64a2                	ld	s1,8(sp)
    8000617e:	6902                	ld	s2,0(sp)
    80006180:	6105                	addi	sp,sp,32
    80006182:	8082                	ret
    panic("could not find virtio disk");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	66c50513          	addi	a0,a0,1644 # 800087f0 <syscalls+0x398>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006194:	00002517          	auipc	a0,0x2
    80006198:	67c50513          	addi	a0,a0,1660 # 80008810 <syscalls+0x3b8>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a4080e7          	jalr	932(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	68c50513          	addi	a0,a0,1676 # 80008830 <syscalls+0x3d8>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	394080e7          	jalr	916(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800061b4:	00002517          	auipc	a0,0x2
    800061b8:	69c50513          	addi	a0,a0,1692 # 80008850 <syscalls+0x3f8>
    800061bc:	ffffa097          	auipc	ra,0xffffa
    800061c0:	384080e7          	jalr	900(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800061c4:	00002517          	auipc	a0,0x2
    800061c8:	6ac50513          	addi	a0,a0,1708 # 80008870 <syscalls+0x418>
    800061cc:	ffffa097          	auipc	ra,0xffffa
    800061d0:	374080e7          	jalr	884(ra) # 80000540 <panic>

00000000800061d4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061d4:	7159                	addi	sp,sp,-112
    800061d6:	f486                	sd	ra,104(sp)
    800061d8:	f0a2                	sd	s0,96(sp)
    800061da:	eca6                	sd	s1,88(sp)
    800061dc:	e8ca                	sd	s2,80(sp)
    800061de:	e4ce                	sd	s3,72(sp)
    800061e0:	e0d2                	sd	s4,64(sp)
    800061e2:	fc56                	sd	s5,56(sp)
    800061e4:	f85a                	sd	s6,48(sp)
    800061e6:	f45e                	sd	s7,40(sp)
    800061e8:	f062                	sd	s8,32(sp)
    800061ea:	ec66                	sd	s9,24(sp)
    800061ec:	e86a                	sd	s10,16(sp)
    800061ee:	1880                	addi	s0,sp,112
    800061f0:	8a2a                	mv	s4,a0
    800061f2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061f4:	00c52c83          	lw	s9,12(a0)
    800061f8:	001c9c9b          	slliw	s9,s9,0x1
    800061fc:	1c82                	slli	s9,s9,0x20
    800061fe:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006202:	0001c517          	auipc	a0,0x1c
    80006206:	e2650513          	addi	a0,a0,-474 # 80022028 <disk+0x128>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a3e080e7          	jalr	-1474(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    80006212:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006214:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006216:	0001cb17          	auipc	s6,0x1c
    8000621a:	ceab0b13          	addi	s6,s6,-790 # 80021f00 <disk>
  for(int i = 0; i < 3; i++){
    8000621e:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006220:	0001cc17          	auipc	s8,0x1c
    80006224:	e08c0c13          	addi	s8,s8,-504 # 80022028 <disk+0x128>
    80006228:	a095                	j	8000628c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000622a:	00fb0733          	add	a4,s6,a5
    8000622e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006232:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006234:	0207c563          	bltz	a5,8000625e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006238:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    8000623a:	0591                	addi	a1,a1,4
    8000623c:	05560d63          	beq	a2,s5,80006296 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006240:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006242:	0001c717          	auipc	a4,0x1c
    80006246:	cbe70713          	addi	a4,a4,-834 # 80021f00 <disk>
    8000624a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000624c:	01874683          	lbu	a3,24(a4)
    80006250:	fee9                	bnez	a3,8000622a <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006252:	2785                	addiw	a5,a5,1
    80006254:	0705                	addi	a4,a4,1
    80006256:	fe979be3          	bne	a5,s1,8000624c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000625a:	57fd                	li	a5,-1
    8000625c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000625e:	00c05e63          	blez	a2,8000627a <virtio_disk_rw+0xa6>
    80006262:	060a                	slli	a2,a2,0x2
    80006264:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006268:	0009a503          	lw	a0,0(s3)
    8000626c:	00000097          	auipc	ra,0x0
    80006270:	b4a080e7          	jalr	-1206(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006274:	0991                	addi	s3,s3,4
    80006276:	ffa999e3          	bne	s3,s10,80006268 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000627a:	85e2                	mv	a1,s8
    8000627c:	0001c517          	auipc	a0,0x1c
    80006280:	c9c50513          	addi	a0,a0,-868 # 80021f18 <disk+0x18>
    80006284:	ffffc097          	auipc	ra,0xffffc
    80006288:	e76080e7          	jalr	-394(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000628c:	f9040993          	addi	s3,s0,-112
{
    80006290:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006292:	864a                	mv	a2,s2
    80006294:	b775                	j	80006240 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006296:	f9042503          	lw	a0,-112(s0)
    8000629a:	00a50713          	addi	a4,a0,10
    8000629e:	0712                	slli	a4,a4,0x4

  if(write)
    800062a0:	0001c797          	auipc	a5,0x1c
    800062a4:	c6078793          	addi	a5,a5,-928 # 80021f00 <disk>
    800062a8:	00e786b3          	add	a3,a5,a4
    800062ac:	01703633          	snez	a2,s7
    800062b0:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062b2:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800062b6:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ba:	f6070613          	addi	a2,a4,-160
    800062be:	6394                	ld	a3,0(a5)
    800062c0:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c2:	00870593          	addi	a1,a4,8
    800062c6:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c8:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062ca:	0007b803          	ld	a6,0(a5)
    800062ce:	9642                	add	a2,a2,a6
    800062d0:	46c1                	li	a3,16
    800062d2:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062d4:	4585                	li	a1,1
    800062d6:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062da:	f9442683          	lw	a3,-108(s0)
    800062de:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e2:	0692                	slli	a3,a3,0x4
    800062e4:	9836                	add	a6,a6,a3
    800062e6:	058a0613          	addi	a2,s4,88
    800062ea:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062ee:	0007b803          	ld	a6,0(a5)
    800062f2:	96c2                	add	a3,a3,a6
    800062f4:	40000613          	li	a2,1024
    800062f8:	c690                	sw	a2,8(a3)
  if(write)
    800062fa:	001bb613          	seqz	a2,s7
    800062fe:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006302:	00166613          	ori	a2,a2,1
    80006306:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000630a:	f9842603          	lw	a2,-104(s0)
    8000630e:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006312:	00250693          	addi	a3,a0,2
    80006316:	0692                	slli	a3,a3,0x4
    80006318:	96be                	add	a3,a3,a5
    8000631a:	58fd                	li	a7,-1
    8000631c:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006320:	0612                	slli	a2,a2,0x4
    80006322:	9832                	add	a6,a6,a2
    80006324:	f9070713          	addi	a4,a4,-112
    80006328:	973e                	add	a4,a4,a5
    8000632a:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000632e:	6398                	ld	a4,0(a5)
    80006330:	9732                	add	a4,a4,a2
    80006332:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006334:	4609                	li	a2,2
    80006336:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    8000633a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000633e:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006342:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006346:	6794                	ld	a3,8(a5)
    80006348:	0026d703          	lhu	a4,2(a3)
    8000634c:	8b1d                	andi	a4,a4,7
    8000634e:	0706                	slli	a4,a4,0x1
    80006350:	96ba                	add	a3,a3,a4
    80006352:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006356:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000635a:	6798                	ld	a4,8(a5)
    8000635c:	00275783          	lhu	a5,2(a4)
    80006360:	2785                	addiw	a5,a5,1
    80006362:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006366:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000636a:	100017b7          	lui	a5,0x10001
    8000636e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006372:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006376:	0001c917          	auipc	s2,0x1c
    8000637a:	cb290913          	addi	s2,s2,-846 # 80022028 <disk+0x128>
  while(b->disk == 1) {
    8000637e:	4485                	li	s1,1
    80006380:	00b79c63          	bne	a5,a1,80006398 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006384:	85ca                	mv	a1,s2
    80006386:	8552                	mv	a0,s4
    80006388:	ffffc097          	auipc	ra,0xffffc
    8000638c:	d72080e7          	jalr	-654(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006390:	004a2783          	lw	a5,4(s4)
    80006394:	fe9788e3          	beq	a5,s1,80006384 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006398:	f9042903          	lw	s2,-112(s0)
    8000639c:	00290713          	addi	a4,s2,2
    800063a0:	0712                	slli	a4,a4,0x4
    800063a2:	0001c797          	auipc	a5,0x1c
    800063a6:	b5e78793          	addi	a5,a5,-1186 # 80021f00 <disk>
    800063aa:	97ba                	add	a5,a5,a4
    800063ac:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063b0:	0001c997          	auipc	s3,0x1c
    800063b4:	b5098993          	addi	s3,s3,-1200 # 80021f00 <disk>
    800063b8:	00491713          	slli	a4,s2,0x4
    800063bc:	0009b783          	ld	a5,0(s3)
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063c6:	854a                	mv	a0,s2
    800063c8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063cc:	00000097          	auipc	ra,0x0
    800063d0:	9ea080e7          	jalr	-1558(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063d4:	8885                	andi	s1,s1,1
    800063d6:	f0ed                	bnez	s1,800063b8 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063d8:	0001c517          	auipc	a0,0x1c
    800063dc:	c5050513          	addi	a0,a0,-944 # 80022028 <disk+0x128>
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	91c080e7          	jalr	-1764(ra) # 80000cfc <release>
}
    800063e8:	70a6                	ld	ra,104(sp)
    800063ea:	7406                	ld	s0,96(sp)
    800063ec:	64e6                	ld	s1,88(sp)
    800063ee:	6946                	ld	s2,80(sp)
    800063f0:	69a6                	ld	s3,72(sp)
    800063f2:	6a06                	ld	s4,64(sp)
    800063f4:	7ae2                	ld	s5,56(sp)
    800063f6:	7b42                	ld	s6,48(sp)
    800063f8:	7ba2                	ld	s7,40(sp)
    800063fa:	7c02                	ld	s8,32(sp)
    800063fc:	6ce2                	ld	s9,24(sp)
    800063fe:	6d42                	ld	s10,16(sp)
    80006400:	6165                	addi	sp,sp,112
    80006402:	8082                	ret

0000000080006404 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006404:	1101                	addi	sp,sp,-32
    80006406:	ec06                	sd	ra,24(sp)
    80006408:	e822                	sd	s0,16(sp)
    8000640a:	e426                	sd	s1,8(sp)
    8000640c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000640e:	0001c497          	auipc	s1,0x1c
    80006412:	af248493          	addi	s1,s1,-1294 # 80021f00 <disk>
    80006416:	0001c517          	auipc	a0,0x1c
    8000641a:	c1250513          	addi	a0,a0,-1006 # 80022028 <disk+0x128>
    8000641e:	ffffb097          	auipc	ra,0xffffb
    80006422:	82a080e7          	jalr	-2006(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006426:	10001737          	lui	a4,0x10001
    8000642a:	533c                	lw	a5,96(a4)
    8000642c:	8b8d                	andi	a5,a5,3
    8000642e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006430:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006434:	689c                	ld	a5,16(s1)
    80006436:	0204d703          	lhu	a4,32(s1)
    8000643a:	0027d783          	lhu	a5,2(a5)
    8000643e:	04f70863          	beq	a4,a5,8000648e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006442:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006446:	6898                	ld	a4,16(s1)
    80006448:	0204d783          	lhu	a5,32(s1)
    8000644c:	8b9d                	andi	a5,a5,7
    8000644e:	078e                	slli	a5,a5,0x3
    80006450:	97ba                	add	a5,a5,a4
    80006452:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006454:	00278713          	addi	a4,a5,2
    80006458:	0712                	slli	a4,a4,0x4
    8000645a:	9726                	add	a4,a4,s1
    8000645c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006460:	e721                	bnez	a4,800064a8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006462:	0789                	addi	a5,a5,2
    80006464:	0792                	slli	a5,a5,0x4
    80006466:	97a6                	add	a5,a5,s1
    80006468:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000646a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000646e:	ffffc097          	auipc	ra,0xffffc
    80006472:	cf0080e7          	jalr	-784(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006476:	0204d783          	lhu	a5,32(s1)
    8000647a:	2785                	addiw	a5,a5,1
    8000647c:	17c2                	slli	a5,a5,0x30
    8000647e:	93c1                	srli	a5,a5,0x30
    80006480:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006484:	6898                	ld	a4,16(s1)
    80006486:	00275703          	lhu	a4,2(a4)
    8000648a:	faf71ce3          	bne	a4,a5,80006442 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000648e:	0001c517          	auipc	a0,0x1c
    80006492:	b9a50513          	addi	a0,a0,-1126 # 80022028 <disk+0x128>
    80006496:	ffffb097          	auipc	ra,0xffffb
    8000649a:	866080e7          	jalr	-1946(ra) # 80000cfc <release>
}
    8000649e:	60e2                	ld	ra,24(sp)
    800064a0:	6442                	ld	s0,16(sp)
    800064a2:	64a2                	ld	s1,8(sp)
    800064a4:	6105                	addi	sp,sp,32
    800064a6:	8082                	ret
      panic("virtio_disk_intr status");
    800064a8:	00002517          	auipc	a0,0x2
    800064ac:	40050513          	addi	a0,a0,1024 # 800088a8 <syscalls+0x450>
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	090080e7          	jalr	144(ra) # 80000540 <panic>

00000000800064b8 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    800064b8:	1141                	addi	sp,sp,-16
    800064ba:	e422                	sd	s0,8(sp)
    800064bc:	0800                	addi	s0,sp,16
}
    800064be:	6422                	ld	s0,8(sp)
    800064c0:	0141                	addi	sp,sp,16
    800064c2:	8082                	ret

00000000800064c4 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    800064c4:	1101                	addi	sp,sp,-32
    800064c6:	ec06                	sd	ra,24(sp)
    800064c8:	e822                	sd	s0,16(sp)
    800064ca:	e426                	sd	s1,8(sp)
    800064cc:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    800064ce:	454c                	lw	a1,12(a0)
    800064d0:	7cf00793          	li	a5,1999
    800064d4:	02b7ea63          	bltu	a5,a1,80006508 <ramdiskrw+0x44>
    800064d8:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    800064da:	00a5959b          	slliw	a1,a1,0xa
    800064de:	1582                	slli	a1,a1,0x20
    800064e0:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064e2:	40000613          	li	a2,1024
    800064e6:	02100793          	li	a5,33
    800064ea:	07ea                	slli	a5,a5,0x1a
    800064ec:	95be                	add	a1,a1,a5
    800064ee:	05850513          	addi	a0,a0,88
    800064f2:	ffffb097          	auipc	ra,0xffffb
    800064f6:	8ae080e7          	jalr	-1874(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064fa:	4785                	li	a5,1
    800064fc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064fe:	60e2                	ld	ra,24(sp)
    80006500:	6442                	ld	s0,16(sp)
    80006502:	64a2                	ld	s1,8(sp)
    80006504:	6105                	addi	sp,sp,32
    80006506:	8082                	ret
    panic("ramdiskrw: blockno too big");
    80006508:	00002517          	auipc	a0,0x2
    8000650c:	3b850513          	addi	a0,a0,952 # 800088c0 <syscalls+0x468>
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	030080e7          	jalr	48(ra) # 80000540 <panic>

0000000080006518 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    80006518:	7119                	addi	sp,sp,-128
    8000651a:	fc86                	sd	ra,120(sp)
    8000651c:	f8a2                	sd	s0,112(sp)
    8000651e:	f4a6                	sd	s1,104(sp)
    80006520:	f0ca                	sd	s2,96(sp)
    80006522:	ecce                	sd	s3,88(sp)
    80006524:	e8d2                	sd	s4,80(sp)
    80006526:	e4d6                	sd	s5,72(sp)
    80006528:	e0da                	sd	s6,64(sp)
    8000652a:	fc5e                	sd	s7,56(sp)
    8000652c:	f862                	sd	s8,48(sp)
    8000652e:	f466                	sd	s9,40(sp)
    80006530:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    80006532:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    80006536:	c5e1                	beqz	a1,800065fe <dump_hex+0xe6>
    80006538:	89ae                	mv	s3,a1
    8000653a:	892a                	mv	s2,a0
    8000653c:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    8000653e:	00002a97          	auipc	s5,0x2
    80006542:	3a2a8a93          	addi	s5,s5,930 # 800088e0 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006546:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000654a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000654e:	00002c17          	auipc	s8,0x2
    80006552:	3a2c0c13          	addi	s8,s8,930 # 800088f0 <syscalls+0x498>
			printf(" ");
    80006556:	00002b97          	auipc	s7,0x2
    8000655a:	392b8b93          	addi	s7,s7,914 # 800088e8 <syscalls+0x490>
    8000655e:	a839                	j	8000657c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006560:	00f4f793          	andi	a5,s1,15
    80006564:	fa078793          	addi	a5,a5,-96
    80006568:	97a2                	add	a5,a5,s0
    8000656a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000656e:	0485                	addi	s1,s1,1
    80006570:	0074f793          	andi	a5,s1,7
    80006574:	cb9d                	beqz	a5,800065aa <dump_hex+0x92>
    80006576:	0b348a63          	beq	s1,s3,8000662a <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000657a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000657c:	00094583          	lbu	a1,0(s2)
    80006580:	8556                	mv	a0,s5
    80006582:	ffffa097          	auipc	ra,0xffffa
    80006586:	008080e7          	jalr	8(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000658a:	00094703          	lbu	a4,0(s2)
    8000658e:	fe07079b          	addiw	a5,a4,-32
    80006592:	0ff7f793          	zext.b	a5,a5
    80006596:	fcfa65e3          	bltu	s4,a5,80006560 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000659a:	00f4f793          	andi	a5,s1,15
    8000659e:	fa078793          	addi	a5,a5,-96
    800065a2:	97a2                	add	a5,a5,s0
    800065a4:	fee78423          	sb	a4,-24(a5)
    800065a8:	b7d9                	j	8000656e <dump_hex+0x56>
			printf(" ");
    800065aa:	855e                	mv	a0,s7
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	fde080e7          	jalr	-34(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    800065b4:	00f4fc93          	andi	s9,s1,15
    800065b8:	080c8263          	beqz	s9,8000663c <dump_hex+0x124>
			} else if (i+1 == size) {
    800065bc:	fb349fe3          	bne	s1,s3,8000657a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    800065c0:	fa0c8793          	addi	a5,s9,-96
    800065c4:	97a2                	add	a5,a5,s0
    800065c6:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    800065ca:	47a1                	li	a5,8
    800065cc:	0597f663          	bgeu	a5,s9,80006618 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    800065d0:	00002917          	auipc	s2,0x2
    800065d4:	32890913          	addi	s2,s2,808 # 800088f8 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065d8:	44bd                	li	s1,15
					printf("   ");
    800065da:	854a                	mv	a0,s2
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	fae080e7          	jalr	-82(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065e4:	0c85                	addi	s9,s9,1
    800065e6:	ff94fae3          	bgeu	s1,s9,800065da <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065ea:	f8840593          	addi	a1,s0,-120
    800065ee:	00002517          	auipc	a0,0x2
    800065f2:	30250513          	addi	a0,a0,770 # 800088f0 <syscalls+0x498>
    800065f6:	ffffa097          	auipc	ra,0xffffa
    800065fa:	f94080e7          	jalr	-108(ra) # 8000058a <printf>
			}
		}
	}
    800065fe:	70e6                	ld	ra,120(sp)
    80006600:	7446                	ld	s0,112(sp)
    80006602:	74a6                	ld	s1,104(sp)
    80006604:	7906                	ld	s2,96(sp)
    80006606:	69e6                	ld	s3,88(sp)
    80006608:	6a46                	ld	s4,80(sp)
    8000660a:	6aa6                	ld	s5,72(sp)
    8000660c:	6b06                	ld	s6,64(sp)
    8000660e:	7be2                	ld	s7,56(sp)
    80006610:	7c42                	ld	s8,48(sp)
    80006612:	7ca2                	ld	s9,40(sp)
    80006614:	6109                	addi	sp,sp,128
    80006616:	8082                	ret
					printf(" ");
    80006618:	00002517          	auipc	a0,0x2
    8000661c:	2d050513          	addi	a0,a0,720 # 800088e8 <syscalls+0x490>
    80006620:	ffffa097          	auipc	ra,0xffffa
    80006624:	f6a080e7          	jalr	-150(ra) # 8000058a <printf>
    80006628:	b765                	j	800065d0 <dump_hex+0xb8>
			printf(" ");
    8000662a:	855e                	mv	a0,s7
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	f5e080e7          	jalr	-162(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006634:	00f9fc93          	andi	s9,s3,15
    80006638:	f80c94e3          	bnez	s9,800065c0 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    8000663c:	f8840593          	addi	a1,s0,-120
    80006640:	8562                	mv	a0,s8
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	f48080e7          	jalr	-184(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000664a:	fb348ae3          	beq	s1,s3,800065fe <dump_hex+0xe6>
    8000664e:	0905                	addi	s2,s2,1
    80006650:	b735                	j	8000657c <dump_hex+0x64>

0000000080006652 <init_all_vm_registers>:
vm_virtual_state vm_state; // Create a global VM state

// -------------------- Function Definitions --------------------

// Function to initialize all the VM's registers to 0
void init_all_vm_registers(void) {
    80006652:	1141                	addi	sp,sp,-16
    80006654:	e422                	sd	s0,8(sp)
    80006656:	0800                	addi	s0,sp,16

    // user trap setup registers
    vm_state.user_status.csr = 0x0000;
    80006658:	0001c797          	auipc	a5,0x1c
    8000665c:	9e878793          	addi	a5,a5,-1560 # 80022040 <vm_state>
    80006660:	0007a023          	sw	zero,0(a5)
    vm_state.user_status.mode = VM_MODE_RESTRICTED;
    80006664:	0007a223          	sw	zero,4(a5)
    vm_state.user_status.val = 0x00000000;
    80006668:	0007b423          	sd	zero,8(a5)

    vm_state.user_interrupt_enable.csr = 0x0004;
    8000666c:	4711                	li	a4,4
    8000666e:	cb98                	sw	a4,16(a5)
    vm_state.user_interrupt_enable.mode = VM_MODE_RESTRICTED;
    80006670:	0007aa23          	sw	zero,20(a5)
    vm_state.user_interrupt_enable.val = 0x00000000;
    80006674:	0007bc23          	sd	zero,24(a5)

    vm_state.user_trap_vector.csr = 0x0005;
    80006678:	4715                	li	a4,5
    8000667a:	d398                	sw	a4,32(a5)
    vm_state.user_trap_vector.mode = VM_MODE_RESTRICTED;
    8000667c:	0207a223          	sw	zero,36(a5)
    vm_state.user_trap_vector.val = 0x00000000;
    80006680:	0207b423          	sd	zero,40(a5)

    // user trap handling registers
    vm_state.user_scratch.csr = 0x0040;
    80006684:	04000713          	li	a4,64
    80006688:	db98                	sw	a4,48(a5)
    vm_state.user_scratch.mode = VM_MODE_RESTRICTED;
    8000668a:	0207aa23          	sw	zero,52(a5)
    vm_state.user_scratch.val = 0x00000000;
    8000668e:	0207bc23          	sd	zero,56(a5)

    vm_state.user_exception_pc.csr = 0x0041;
    80006692:	04100713          	li	a4,65
    80006696:	c3b8                	sw	a4,64(a5)
    vm_state.user_exception_pc.mode = VM_MODE_RESTRICTED;
    80006698:	0407a223          	sw	zero,68(a5)
    vm_state.user_exception_pc.val = 0x00000000;
    8000669c:	0407b423          	sd	zero,72(a5)

    vm_state.user_trap_cause.csr = 0x0042;
    800066a0:	04200713          	li	a4,66
    800066a4:	cbb8                	sw	a4,80(a5)
    vm_state.user_trap_cause.mode = VM_MODE_RESTRICTED;
    800066a6:	0407aa23          	sw	zero,84(a5)
    vm_state.user_trap_cause.val = 0x00000000;
    800066aa:	0407bc23          	sd	zero,88(a5)

    vm_state.user_trap_value.csr = 0x0043;
    800066ae:	04300713          	li	a4,67
    800066b2:	d3b8                	sw	a4,96(a5)
    vm_state.user_trap_value.mode = VM_MODE_RESTRICTED;
    800066b4:	0607a223          	sw	zero,100(a5)
    vm_state.user_trap_value.val = 0x00000000;
    800066b8:	0607b423          	sd	zero,104(a5)

    vm_state.user_interrupt_pending.csr = 0x0044;
    800066bc:	04400713          	li	a4,68
    800066c0:	dbb8                	sw	a4,112(a5)
    vm_state.user_interrupt_pending.mode = VM_MODE_RESTRICTED;
    800066c2:	0607aa23          	sw	zero,116(a5)
    vm_state.user_interrupt_pending.val = 0x00000000;
    800066c6:	0607bc23          	sd	zero,120(a5)

    // supervisor trap setup registers
    vm_state.supervisor_status.csr = 0x0100;
    800066ca:	10000713          	li	a4,256
    800066ce:	08e7a023          	sw	a4,128(a5)
    vm_state.supervisor_status.mode = VM_MODE_UNRESTRICTED;
    800066d2:	4705                	li	a4,1
    800066d4:	08e7a223          	sw	a4,132(a5)
    vm_state.supervisor_status.val = 0x00000000;
    800066d8:	0807b423          	sd	zero,136(a5)

    vm_state.supervisor_exception_delegation.csr = 0x0102;
    800066dc:	10200693          	li	a3,258
    800066e0:	08d7a823          	sw	a3,144(a5)
    vm_state.supervisor_exception_delegation.mode = VM_MODE_UNRESTRICTED;
    800066e4:	08e7aa23          	sw	a4,148(a5)
    vm_state.supervisor_exception_delegation.val = 0x00000000;   
    800066e8:	0807bc23          	sd	zero,152(a5)

    vm_state.supervisor_interrupt_delegation.csr = 0x0103;
    800066ec:	10300693          	li	a3,259
    800066f0:	0ad7a023          	sw	a3,160(a5)
    vm_state.supervisor_interrupt_delegation.mode = VM_MODE_UNRESTRICTED;
    800066f4:	0ae7a223          	sw	a4,164(a5)
    vm_state.supervisor_interrupt_delegation.val = 0x00000000   ;
    800066f8:	0a07b423          	sd	zero,168(a5)

    vm_state.supervisor_interrupt_enable.csr = 0x0104;
    800066fc:	10400693          	li	a3,260
    80006700:	0ad7a823          	sw	a3,176(a5)
    vm_state.supervisor_interrupt_enable.mode = VM_MODE_UNRESTRICTED;
    80006704:	0ae7aa23          	sw	a4,180(a5)
    vm_state.supervisor_interrupt_enable.val = 0x00000000   ;
    80006708:	0a07bc23          	sd	zero,184(a5)

    vm_state.supervisor_trap_vector.csr = 0x0105;
    8000670c:	10500693          	li	a3,261
    80006710:	0cd7a023          	sw	a3,192(a5)
    vm_state.supervisor_trap_vector.mode = VM_MODE_UNRESTRICTED;
    80006714:	0ce7a223          	sw	a4,196(a5)
    vm_state.supervisor_trap_vector.val = 0x00000000;
    80006718:	0c07b423          	sd	zero,200(a5)

    vm_state.supervisor_counter_enable.csr = 0x0106;
    8000671c:	10600693          	li	a3,262
    80006720:	0cd7a823          	sw	a3,208(a5)
    vm_state.supervisor_counter_enable.mode = VM_MODE_UNRESTRICTED;
    80006724:	0ce7aa23          	sw	a4,212(a5)
    vm_state.supervisor_counter_enable.val = 0x00000000;
    80006728:	0c07bc23          	sd	zero,216(a5)

    // supervisor trap handling registers
    vm_state.supervisor_scratch.csr = 0x0140;
    8000672c:	14000693          	li	a3,320
    80006730:	0ed7a023          	sw	a3,224(a5)
    vm_state.supervisor_scratch.mode = VM_MODE_UNRESTRICTED;
    80006734:	0ee7a223          	sw	a4,228(a5)
    vm_state.supervisor_scratch.val = 0x00000000;
    80006738:	0e07b423          	sd	zero,232(a5)

    vm_state.supervisor_exception_pc.csr = 0x0141;
    8000673c:	14100693          	li	a3,321
    80006740:	0ed7a823          	sw	a3,240(a5)
    vm_state.supervisor_exception_pc.mode = VM_MODE_UNRESTRICTED;
    80006744:	0ee7aa23          	sw	a4,244(a5)
    vm_state.supervisor_exception_pc.val = 0x00000000;
    80006748:	0e07bc23          	sd	zero,248(a5)

    vm_state.supervisor_trap_cause.csr = 0x0142;
    8000674c:	14200693          	li	a3,322
    80006750:	10d7a023          	sw	a3,256(a5)
    vm_state.supervisor_trap_cause.mode = VM_MODE_UNRESTRICTED;
    80006754:	10e7a223          	sw	a4,260(a5)
    vm_state.supervisor_trap_cause.val = 0x00000000;
    80006758:	1007b423          	sd	zero,264(a5)

    vm_state.supervisor_trap_value.csr = 0x0143;
    8000675c:	14300693          	li	a3,323
    80006760:	10d7a823          	sw	a3,272(a5)
    vm_state.supervisor_trap_value.mode = VM_MODE_UNRESTRICTED;
    80006764:	10e7aa23          	sw	a4,276(a5)
    vm_state.supervisor_trap_value.val = 0x00000000;
    80006768:	1007bc23          	sd	zero,280(a5)

    vm_state.supervisor_interrupt_pending.csr = 0x0144;
    8000676c:	14400693          	li	a3,324
    80006770:	12d7a023          	sw	a3,288(a5)
    vm_state.supervisor_interrupt_pending.mode = VM_MODE_UNRESTRICTED;
    80006774:	12e7a223          	sw	a4,292(a5)
    vm_state.supervisor_interrupt_pending.val = 0x00000000;
    80006778:	1207b423          	sd	zero,296(a5)

    // supervisor page table register
    vm_state.supervisor_address_translation.csr = 0x0180;
    8000677c:	18000693          	li	a3,384
    80006780:	12d7a823          	sw	a3,304(a5)
    vm_state.supervisor_address_translation.mode = VM_MODE_UNRESTRICTED;
    80006784:	12e7aa23          	sw	a4,308(a5)
    vm_state.supervisor_address_translation.val = 0x00000000;
    80006788:	1207bc23          	sd	zero,312(a5)

    // machine information registers
    vm_state.machine_vendor_id.csr = 0x0f11;
    8000678c:	6685                	lui	a3,0x1
    8000678e:	f1168713          	addi	a4,a3,-239 # f11 <_entry-0x7ffff0ef>
    80006792:	14e7a023          	sw	a4,320(a5)
    vm_state.machine_vendor_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006796:	4709                	li	a4,2
    80006798:	14e7a223          	sw	a4,324(a5)
    vm_state.machine_vendor_id.val = 0x637365353336;          // equals to CSE536 in hexadecimal
    8000679c:	00002617          	auipc	a2,0x2
    800067a0:	86c63603          	ld	a2,-1940(a2) # 80008008 <etext+0x8>
    800067a4:	14c7b423          	sd	a2,328(a5)

    vm_state.machine_architecture_id.csr = 0x0f12;
    800067a8:	f1268613          	addi	a2,a3,-238
    800067ac:	14c7a823          	sw	a2,336(a5)
    vm_state.machine_architecture_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    800067b0:	14e7aa23          	sw	a4,340(a5)
    vm_state.machine_architecture_id.val = 0x00000000;
    800067b4:	1407bc23          	sd	zero,344(a5)

    vm_state.machine_implementation_id.csr = 0x0f13;
    800067b8:	f1368613          	addi	a2,a3,-237
    800067bc:	16c7a023          	sw	a2,352(a5)
    vm_state.machine_implementation_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    800067c0:	16e7a223          	sw	a4,356(a5)
    vm_state.machine_implementation_id.val = 0x00000000;
    800067c4:	1607b423          	sd	zero,360(a5)

    vm_state.machine_hardware_thread_id.csr = 0x0f14;
    800067c8:	f1468693          	addi	a3,a3,-236
    800067cc:	16d7a823          	sw	a3,368(a5)
    vm_state.machine_hardware_thread_id.mode = VM_MODE_FULLY_UNRESTRICTED;
    800067d0:	16e7aa23          	sw	a4,372(a5)
    vm_state.machine_hardware_thread_id.val = 0x00000000;
    800067d4:	1607bc23          	sd	zero,376(a5)

    // machine trap setup registers
    vm_state.machine_status.csr = 0x0300;
    800067d8:	30000693          	li	a3,768
    800067dc:	18d7a023          	sw	a3,384(a5)
    vm_state.machine_status.mode = VM_MODE_FULLY_UNRESTRICTED;
    800067e0:	18e7a223          	sw	a4,388(a5)
    vm_state.machine_status.val = 0x00000000;
    800067e4:	1807b423          	sd	zero,392(a5)

    vm_state.machine_isa.csr = 0x0301;
    800067e8:	30100693          	li	a3,769
    800067ec:	18d7a823          	sw	a3,400(a5)
    vm_state.machine_isa.mode = VM_MODE_FULLY_UNRESTRICTED;
    800067f0:	18e7aa23          	sw	a4,404(a5)
    vm_state.machine_isa.val = 0x00000000;
    800067f4:	1807bc23          	sd	zero,408(a5)

    vm_state.machine_exception_delegation.csr = 0x0302;
    800067f8:	30200693          	li	a3,770
    800067fc:	1ad7a023          	sw	a3,416(a5)
    vm_state.machine_exception_delegation.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006800:	1ae7a223          	sw	a4,420(a5)
    vm_state.machine_exception_delegation.val = 0x00000000;
    80006804:	1a07b423          	sd	zero,424(a5)

    vm_state.machine_interrupt_delegation.csr = 0x0303;
    80006808:	30300693          	li	a3,771
    8000680c:	1ad7a823          	sw	a3,432(a5)
    vm_state.machine_interrupt_delegation.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006810:	1ae7aa23          	sw	a4,436(a5)
    vm_state.machine_interrupt_delegation.val = 0x00000000;
    80006814:	1a07bc23          	sd	zero,440(a5)

    vm_state.machine_interrupt_enable.csr = 0x0304;
    80006818:	30400693          	li	a3,772
    8000681c:	1cd7a023          	sw	a3,448(a5)
    vm_state.machine_interrupt_enable.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006820:	1ce7a223          	sw	a4,452(a5)
    vm_state.machine_interrupt_enable.val = 0x00000000;
    80006824:	1c07b423          	sd	zero,456(a5)

    vm_state.machine_trap_vector.csr = 0x0305;
    80006828:	30500693          	li	a3,773
    8000682c:	1cd7a823          	sw	a3,464(a5)
    vm_state.machine_trap_vector.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006830:	1ce7aa23          	sw	a4,468(a5)
    vm_state.machine_trap_vector.val = 0x00000000;
    80006834:	1c07bc23          	sd	zero,472(a5)

    vm_state.machine_counter_enable.csr = 0x0306;
    80006838:	30600693          	li	a3,774
    8000683c:	1ed7a023          	sw	a3,480(a5)
    vm_state.machine_counter_enable.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006840:	1ee7a223          	sw	a4,484(a5)
    vm_state.machine_counter_enable.val = 0x00000000;
    80006844:	1e07b423          	sd	zero,488(a5)

    // machine trap handling registers
    vm_state.machine_scratch.csr = 0x0340;
    80006848:	34000693          	li	a3,832
    8000684c:	1ed7a823          	sw	a3,496(a5)
    vm_state.machine_scratch.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006850:	1ee7aa23          	sw	a4,500(a5)
    vm_state.machine_scratch.val = 0x00000000;
    80006854:	1e07bc23          	sd	zero,504(a5)

    vm_state.machine_exception_pc.csr = 0x0341;
    80006858:	34100693          	li	a3,833
    8000685c:	20d7a023          	sw	a3,512(a5)
    vm_state.machine_exception_pc.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006860:	20e7a223          	sw	a4,516(a5)
    vm_state.machine_exception_pc.val = 0x00000000;
    80006864:	2007b423          	sd	zero,520(a5)

    vm_state.machine_trap_cause.csr = 0x0342;
    80006868:	34200693          	li	a3,834
    8000686c:	20d7a823          	sw	a3,528(a5)
    vm_state.machine_trap_cause.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006870:	20e7aa23          	sw	a4,532(a5)
    vm_state.machine_trap_cause.val = 0x00000000;
    80006874:	2007bc23          	sd	zero,536(a5)

    vm_state.machine_trap_value.csr = 0x0343;
    80006878:	34300693          	li	a3,835
    8000687c:	22d7a023          	sw	a3,544(a5)
    vm_state.machine_trap_value.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006880:	22e7a223          	sw	a4,548(a5)
    vm_state.machine_trap_value.val = 0x00000000;
    80006884:	2207b423          	sd	zero,552(a5)

    vm_state.machine_interrupt_pending.csr = 0x0344;
    80006888:	34400693          	li	a3,836
    8000688c:	22d7a823          	sw	a3,560(a5)
    vm_state.machine_interrupt_pending.mode = VM_MODE_FULLY_UNRESTRICTED;
    80006890:	22e7aa23          	sw	a4,564(a5)
    vm_state.machine_interrupt_pending.val = 0x00000000;
    80006894:	2207bc23          	sd	zero,568(a5)

   //TO DO: Add the VM's physical memory protection registers

}
    80006898:	6422                	ld	s0,8(sp)
    8000689a:	0141                	addi	sp,sp,16
    8000689c:	8082                	ret

000000008000689e <decode_instruction>:
// In your ECALL, add the following for prints
// struct proc* p = myproc();
// printf("(EC at %p)\n", p->trapframe->epc);

// Function to decode a RISC-V instruction into its components
decoded_inst decode_instruction(uint64 instruction_address, uint32 raw_instruction) {
    8000689e:	1141                	addi	sp,sp,-16
    800068a0:	e422                	sd	s0,8(sp)
    800068a2:	0800                	addi	s0,sp,16
    // Extract instruction fields based on RISC-V encoding format 
    decoded.op = raw_instruction & 0b1111111;          // Extract opcode from bits [6:0]
    decoded.rd = (raw_instruction >> 7) & 0b11111;     // Extract destination register from bits [11:7]
    decoded.funct3 = (raw_instruction >> 12) & 0b111;  // Extract function3 code from bits [14:12]
    decoded.rs1 = (raw_instruction >> 15) & 0b11111;   // Extract source register 1 from bits [19:15]
    decoded.rs2 = (raw_instruction >> 20) & 0b11111;   // Extract source register 2 from bits [24:20]
    800068a4:	0146569b          	srliw	a3,a2,0x14
    decoded.uimm = (raw_instruction >> 20);            // Extract upper immediate value from bits [31:20]
    
    return decoded;
    800068a8:	e10c                	sd	a1,0(a0)
    800068aa:	c510                	sw	a2,8(a0)
    decoded.op = raw_instruction & 0b1111111;          // Extract opcode from bits [6:0]
    800068ac:	07f67713          	andi	a4,a2,127
    return decoded;
    800068b0:	c558                	sw	a4,12(a0)
    decoded.rd = (raw_instruction >> 7) & 0b11111;     // Extract destination register from bits [11:7]
    800068b2:	0076571b          	srliw	a4,a2,0x7
    800068b6:	8b7d                	andi	a4,a4,31
    return decoded;
    800068b8:	c918                	sw	a4,16(a0)
    decoded.rs1 = (raw_instruction >> 15) & 0b11111;   // Extract source register 1 from bits [19:15]
    800068ba:	00f6571b          	srliw	a4,a2,0xf
    800068be:	8b7d                	andi	a4,a4,31
    return decoded;
    800068c0:	c958                	sw	a4,20(a0)
    decoded.rs2 = (raw_instruction >> 20) & 0b11111;   // Extract source register 2 from bits [24:20]
    800068c2:	01f6f713          	andi	a4,a3,31
    return decoded;
    800068c6:	cd18                	sw	a4,24(a0)
    decoded.funct3 = (raw_instruction >> 12) & 0b111;  // Extract function3 code from bits [14:12]
    800068c8:	00c6561b          	srliw	a2,a2,0xc
    800068cc:	8a1d                	andi	a2,a2,7
    return decoded;
    800068ce:	cd50                	sw	a2,28(a0)
    800068d0:	d114                	sw	a3,32(a0)
}
    800068d2:	6422                	ld	s0,8(sp)
    800068d4:	0141                	addi	sp,sp,16
    800068d6:	8082                	ret

00000000800068d8 <print_instruction>:

// Function to print decoded instruction information
void print_instruction(decoded_inst* inst) {
    800068d8:	1141                	addi	sp,sp,-16
    800068da:	e406                	sd	ra,8(sp)
    800068dc:	e022                	sd	s0,0(sp)
    800068de:	0800                	addi	s0,sp,16
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", inst->addr, inst->op, inst->rd, inst->funct3, inst->rs1, inst->uimm);
    800068e0:	02052803          	lw	a6,32(a0)
    800068e4:	495c                	lw	a5,20(a0)
    800068e6:	4d58                	lw	a4,28(a0)
    800068e8:	4914                	lw	a3,16(a0)
    800068ea:	4550                	lw	a2,12(a0)
    800068ec:	610c                	ld	a1,0(a0)
    800068ee:	00002517          	auipc	a0,0x2
    800068f2:	01250513          	addi	a0,a0,18 # 80008900 <syscalls+0x4a8>
    800068f6:	ffffa097          	auipc	ra,0xffffa
    800068fa:	c94080e7          	jalr	-876(ra) # 8000058a <printf>
}
    800068fe:	60a2                	ld	ra,8(sp)
    80006900:	6402                	ld	s0,0(sp)
    80006902:	0141                	addi	sp,sp,16
    80006904:	8082                	ret

0000000080006906 <trap_and_emulate>:

// Function to trap and emulate a RISC-V instruction made by the VM
void trap_and_emulate(void) {
    80006906:	715d                	addi	sp,sp,-80
    80006908:	e486                	sd	ra,72(sp)
    8000690a:	e0a2                	sd	s0,64(sp)
    8000690c:	fc26                	sd	s1,56(sp)
    8000690e:	f84a                	sd	s2,48(sp)
    80006910:	0880                	addi	s0,sp,80
    // Get the current process structure
    struct proc *current_process = myproc();
    80006912:	ffffb097          	auipc	ra,0xffffb
    80006916:	112080e7          	jalr	274(ra) # 80001a24 <myproc>
    8000691a:	84aa                	mv	s1,a0
    
    // Get the instruction address from the trapped Program Counter (PC)
    uint64 instruction_address = current_process->trapframe->epc;
    8000691c:	6d3c                	ld	a5,88(a0)
    8000691e:	0187b903          	ld	s2,24(a5)
    
    uint32 raw_instruction;

    // Read the instruction from user space memory using copyin
    copyin(current_process->pagetable, (char*)&raw_instruction, instruction_address, sizeof(raw_instruction));
    80006922:	4691                	li	a3,4
    80006924:	864a                	mv	a2,s2
    80006926:	fdc40593          	addi	a1,s0,-36
    8000692a:	6928                	ld	a0,80(a0)
    8000692c:	ffffb097          	auipc	ra,0xffffb
    80006930:	e44080e7          	jalr	-444(ra) # 80001770 <copyin>
    
    // Decode the instruction into its components
    decoded_inst decoded_instruction = decode_instruction(instruction_address, raw_instruction);
    80006934:	fdc42603          	lw	a2,-36(s0)
    80006938:	85ca                	mv	a1,s2
    8000693a:	fb040513          	addi	a0,s0,-80
    8000693e:	00000097          	auipc	ra,0x0
    80006942:	f60080e7          	jalr	-160(ra) # 8000689e <decode_instruction>
    
    // Print detailed information about the instruction
    print_instruction(&decoded_instruction);
    80006946:	fb040513          	addi	a0,s0,-80
    8000694a:	00000097          	auipc	ra,0x0
    8000694e:	f8e080e7          	jalr	-114(ra) # 800068d8 <print_instruction>
    
    // Advance the Program Counter to the next instruction (RISC-V instructions are 4 bytes)
    current_process->trapframe->epc += 4;
    80006952:	6cb8                	ld	a4,88(s1)
    80006954:	6f1c                	ld	a5,24(a4)
    80006956:	0791                	addi	a5,a5,4
    80006958:	ef1c                	sd	a5,24(a4)
}
    8000695a:	60a6                	ld	ra,72(sp)
    8000695c:	6406                	ld	s0,64(sp)
    8000695e:	74e2                	ld	s1,56(sp)
    80006960:	7942                	ld	s2,48(sp)
    80006962:	6161                	addi	sp,sp,80
    80006964:	8082                	ret

0000000080006966 <trap_and_emulate_init>:

// Function to initialize the VM's registers and mode
void trap_and_emulate_init(void) {
    80006966:	1141                	addi	sp,sp,-16
    80006968:	e406                	sd	ra,8(sp)
    8000696a:	e022                	sd	s0,0(sp)
    8000696c:	0800                	addi	s0,sp,16
    
    init_all_vm_registers();    // Initialize all the VM's registers to 0 
    8000696e:	00000097          	auipc	ra,0x0
    80006972:	ce4080e7          	jalr	-796(ra) # 80006652 <init_all_vm_registers>
    vm_state.mode = VM_MODE_FULLY_UNRESTRICTED; // Set the mode of the VM to machine mode
    80006976:	4789                	li	a5,2
    80006978:	0001c717          	auipc	a4,0x1c
    8000697c:	90f72423          	sw	a5,-1784(a4) # 80022280 <vm_state+0x240>
}
    80006980:	60a2                	ld	ra,8(sp)
    80006982:	6402                	ld	s0,0(sp)
    80006984:	0141                	addi	sp,sp,16
    80006986:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
