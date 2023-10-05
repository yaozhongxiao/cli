
sample:     file format elf64-littleriscv


Disassembly of section .text:

0000000010110000 <_start>:
    10110000:	00000297          	auipc	t0,0x0
    10110004:	04828293          	add	t0,t0,72 # 10110048 <result+0x4>
    10110008:	0002b283          	ld	t0,0(t0)
    1011000c:	8116                	mv	sp,t0
    1011000e:	01a000ef          	jal	10110028 <main>
    10110012:	8082                	ret
    10110014:	8082                	ret

0000000010110016 <sum>:
    10110016:	4781                	li	a5,0
    10110018:	4501                	li	a0,0
    1011001a:	a019                	j	10110020 <sum+0xa>
    1011001c:	9d3d                	addw	a0,a0,a5
    1011001e:	2785                	addw	a5,a5,1
    10110020:	4725                	li	a4,9
    10110022:	fef75de3          	bge	a4,a5,1011001c <sum+0x6>
    10110026:	8082                	ret

0000000010110028 <main>:
    10110028:	1141                	add	sp,sp,-16
    1011002a:	e406                	sd	ra,8(sp)
    1011002c:	febff0ef          	jal	10110016 <sum>
    10110030:	2529                	addw	a0,a0,10
    10110032:	101107b7          	lui	a5,0x10110
    10110036:	04a7a223          	sw	a0,68(a5) # 10110044 <result>
    1011003a:	2501                	sext.w	a0,a0
    1011003c:	60a2                	ld	ra,8(sp)
    1011003e:	0141                	add	sp,sp,16
    10110040:	8082                	ret
