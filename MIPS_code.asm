#############################################################################
#####################	Floating Point Calculator
#############################################################################
.data
ask0: .asciiz "Enter first floating point number: "
ask1: .asciiz "Enter second floating point number: "
resultfadd: .asciiz "Result of fadd = "
resultadd: .asciiz "Result of add.s = "
resultfsub: .asciiz "Result of fsub = "
resultsub: .asciiz "Result of sub.s = "
resultfmul: .asciiz "Result of fmul = "
resultmul: .asciiz "Result of mul.s = "

.text
main:
li $v0, 4
la $a0, ask0
syscall
li $v0, 6
syscall

mov.s $f1, $f0 #first input in f1

li $v0, 4
la $a0, ask1
syscall
li $v0, 6
syscall #second input in f0

mfc1 $t0, $f1
mfc1 $s7, $f0

add.s $f6, $f1, $f0
sub.s $f7, $f1, $f0
mul.s $f8, $f1, $f0 


li $s0, 0x80000000 #to check the sign
li $s1, 0x7f800000 #to take the exponent
li $s2, 0x007fffff #to tack the float value

and $t1, $t0, $s0 # the sign for first input
and $t4, $s7, $s0 # the sign for second input

li $s4, 127 # bias
c.eq.s $f1, $f31
bc1t zeroFirstInput
# first input
	and $t2, $t0, $s1 # E value
	srl $t2, $t2, 23
	subu $t2, $t2, $s4 #exp_value
	and $t3, $t0, $s2 # fraction part
	sll $t3, $t3, 8
	or $t3, $t3, $s0 # the significand
	j checkSecond
zeroFirstInput:
	li $t2, 0
	li $t3, 0

checkSecond:
c.eq.s $f0, $f31
bc1t zeroSecondInput
	# second input
	and $t5, $s7, $s1 # E value
	srl $t5, $t5, 23
	subu $t5, $t5, $s4 #exp_value
	and $t6, $s7, $s2 # fraction part
	sll $t6, $t6, 8
	or $t6, $t6, $s0 # the significand
	j inputDone
zeroSecondInput:
	li $t5, 0
	li $t6, 0
	
inputDone:
addiu $sp, $sp, -24
sw $t1, 0($sp)
sw $t2, 4($sp)
sw $t3, 8($sp)
sw $t4, 12($sp)
sw $t5, 16($sp)
sw $t6, 20($sp)

### a notes for all the next function:
# 1:
# significand of the first input is in t3
# significand of the first input is in t6
# the exp_value for the result is in s2
# the result in s3
# the sticky and the round bit in s4
# the result sign in s5
# shifted bits in t9
# sign of the first input in t1
# sign of the second input in t4
###
# 2:
#### for the fisrt input
# the sign in $t1
# the exp_value in $t2
# the significand in $t3
####
# 3:
### for the second input
# the sign in $t4
# the exp_value in $t5
# the significand in $t6
###

jal fadd
mov.s $f3, $f0

li $v0, 4
la $a0, resultfadd
syscall

li $v0, 2
mov.s $f12, $f3
syscall

li $v0, 11
li $a0, '\n'
syscall

li $v0, 4
la $a0, resultadd
syscall

li $v0, 2
mov.s $f12, $f6
syscall

li $v0, 11
li $a0, '\n'
syscall

lw $t1, 0($sp)
lw $t2, 4($sp)
lw $t3, 8($sp)
lw $t4, 12($sp)
lw $t5, 16($sp)
lw $t6, 20($sp)

jal fsub
mov.s $f4, $f0

li $v0, 4
la $a0, resultfsub
syscall

li $v0, 2
mov.s $f12, $f4
syscall

li $v0, 11
li $a0, '\n'
syscall

li $v0, 4
la $a0, resultsub
syscall

li $v0, 2
mov.s $f12, $f7
syscall

li $v0, 11
li $a0, '\n'
syscall

lw $t1, 0($sp)
lw $t2, 4($sp)
lw $t3, 8($sp)
lw $t4, 12($sp)
lw $t5, 16($sp)
lw $t6, 20($sp)

jal fmul
mov.s $f5, $f0

li $v0, 4
la $a0, resultfmul
syscall

li $v0, 2
mov.s $f12, $f5
syscall

li $v0, 11
li $a0, '\n'
syscall

li $v0, 4
la $a0, resultmul
syscall

li $v0, 2
mov.s $f12, $f8
syscall

addiu $sp, $sp, 24
li $v0, 10
syscall


fadd:
# check if they have the same exponent, if not shift and save the shifted bits for each
li $s0, 0
li $s1, 0
li $s2, 0
li $s4, 0

bne $t2, $zero, notZero
	bne $t3, $zero, notZero
		bne $t5, $zero, notZero
			bne $t6, $zero, notZero
				li $s3, 0
				li $s2, 0
				j zeroAdd

notZero:
move $s2, $t2
beq $t2, $t5, equalE_add
	# shifted bits in t9
	subu $t0, $t2, $t5
	abs $t0, $t0 # the abs(the shift amount)
	li $s7, 24
	subu $t7, $s7, $t0 # 24 - shifted amount 
	bgt $t2, $t5, theSecondOneIsSmaller
		sllv $t9, $t3, $t7 # in t9 the bits that will be shifted are in the msb
		srlv $t3, $t3, $t0
		move $s2, $t5 # take the exponent value of the bigger one
		j equalE_add 
	theSecondOneIsSmaller:
		sllv $t9, $t6, $t7 # in t9, the bits that will be shifted are in the msb
		srlv $t6, $t6, $t0
		move $s2, $t2 # take the exponent value of the bigger one

equalE_add: # no need to do any shift
	# since the significand must be 24 bits:
	# eleminate the bits on the right of the 24 bits
	move $s4, $t9
	li $t0, 0xFFFFFF00
	and $t3, $t3, $t0 # first number
	and $t6, $t6, $t0 # second number

# next: add or sub ? depending on the sign
## if the same sign add
## if different signs subtract and take the sign of the bigger value
	
	# to check if there is a carry or not:
	srl $t3, $t3, 1
	srl $t6, $t6, 1
	
	bne $t1, $t4, notTheSameSign
		# the same sign
		# add the significands
		addu $s3, $t3, $t6 # add the two significands
		move $s5, $t1 # both have the same sign
		j NormalizeAndRounding
	notTheSameSign:
		# subtract and take the sign of the bigger
		# the subtraction should be as bigger value - smaller value
		# the exponents have been already equalized
		
		# if equal numbers
		bne $t2, $t5, notEqual
			bne $t3, $t6, notEqual
				li $s3, 0
				li $s2, 0
				j zeroAdd
		notEqual:
		subu $s3, $t3, $t6 # assume t3 has bigger value
		move $s5, $t1 # the result sign
		bgt $t3, $t6, firstBigger
			subu $s3, $t6, $t3
			move $s5, $t4 # the result sign
		firstBigger:
			
NormalizeAndRounding:
		# normalize:
		# check if there is a carry
		li $t0, 0x80000000
		and $t7, $s3, $t0
		beq $t7, $zero, NoCarryAdd
			#there is a carry
			li $t0, 0x000000ff
			and $s7, $t0, $s3
			sll $s7, $s7, 24
			srl $t9, $t9, 1
			or $s4, $t9, $s7
			addiu $s2, $s2, 1 # add 1 to the exponent
			li $t0, 0xffffff00
			and $s3, $s3, $t0
			j NoCarryAddEnd
		NoCarryAdd:
			# check if the leading bit is 1, if not normalize.
			sll $s3, $s3, 1
			clz $s6, $s3 # the amount of shifting to make the msb 1
			sllv $s3, $s3, $s6
			subu $s2, $s2, $s6 # shift left ? subtract from the exponent
		NoCarryAddEnd:
		sll $t3, $t3, 1
		sll $t6, $t6, 1
		
		# Rounding:
		beq $s4, $zero, doneAdd
			# round bit -> t1
			li $t0, 0x80000000
			and $t1, $s4, $t0
			# the sticky bit -> t2
			li $t2, 0
			li $t0, 0x7fffffff
			and $t3, $s4, $t0
			
			beq $t3, $zero, ZeroStickyBit
				li $t2, 1
			ZeroStickyBit:
			
			# the system that this program uses:
			# RS = 11 -> add
			# RS = 01 or 00 -> discard RS
			# RS = 10 -> nearest even
			
			bne $t1, 0x80000000, doneAdd
				bne $t2, 1, NearestEven	
					# RS = 11
					addiu $s3, $s3, 1
					beq $s5, $zero, doneAdd
						addiu $s3, $s3, -2
						j doneAdd
				NearestEven:
					# RS = 10
					li $t0, 0x00000001
					and $t4, $s3, $t0
					
					bne $t4, 1, doneAdd
						addiu $s3, $s3, 1
						beq $s5, $zero, doneAdd
							addiu $s3, $s3, -2
							
doneAdd:
# rearrange the result and save it in f0
# the significand in s3
# the exp_value in s2
# the sign in s5
li $t0, 0x7fffffff
and $s3, $s3, $t0
srl $s3, $s3, 8		
addiu $s2, $s2, 127
sll $s2, $s2, 23
zeroAdd:
or $s7, $s5, $s2
or $s7, $s7, $s3
			
mtc1 $s7, $f0
			
jr $ra


fsub:
# check if they have the same exponent, if not shift and save the shifted bits for each
li $s0, 0
li $s1, 0
li $s2, 0
li $s4, 0
move $s2, $t2
beq $t2, $t5, equalESub
	# shifted bits in t9
	subu $t0, $t2, $t5
	abs $t0, $t0 # the abs(the shift amount)
	li $s7, 24
	subu $t7, $s7, $t0 # 24 - shifted amount 
	bgt $t2, $t5, theSecondOneIsSmallerSub
		sllv $t9, $t3, $t7 # in t9 the bits that will be shifted are in the msb
		srlv $t3, $t3, $t0
		move $s2, $t5 # take the exponent value of the bigger one
		j equalESub
	theSecondOneIsSmallerSub:
		sllv $t9, $t6, $t7 # in t9, the bits that will be shifted are in the msb
		srlv $t6, $t6, $t0
		move $s2, $t2 # take the exponent value of the bigger one

equalESub: # no need to do any shift
	# since the significand must be 24 bits:
	# eleminate the bits on the right of the 24 bits
	move $s4, $t9
	li $t0, 0xFFFFFF00
	and $t3, $t3, $t0 # first number
	and $t6, $t6, $t0 # second number

# to check if there is a carry or not:
	srl $t3, $t3, 1
	srl $t6, $t6, 1

# next: add or sub ? 4 cases:
## +ve - +ve -> subtract and take bigger's sign
## +ve - -ve -> add with positive result
## -ve - +ve -> add with negative result
## -ve - -ve -> the same as the first case
	
	bne $t1, $t4, notTheSameSignSub
		# case I and IV: subtract and take bigger's sign
		# if equal numbers the result is zero
		bne $t2, $t5, notEqualSub
			bne $t3, $t6, notEqualSub
				li $s3, 0
				li $s2, 0
				j zeroSub
		notEqualSub:
		move $s5, $t1 # the result sign
		subu $s3, $t3, $t6 # assume t3 has bigger value
		bgt $t3, $t6, NormalizeAndRoundingSub
			subu $s3, $t6, $t3
			li $s5, 0x80000000
			j NormalizeAndRoundingSub
	notTheSameSignSub:
		bne $t1, $zero, caseIII
			# Case II
			li $s5, 0 #positive result
			addu $s3, $t3, $t6
			j NormalizeAndRoundingSub
		caseIII:
			li $s5, 0x80000000 #negative result
			addu $s3, $t3, $t6
			
	NormalizeAndRoundingSub:
		# normalize:
		# check if there is a carry
		li $t0, 0x80000000
		and $t7, $s3, $t0
		beq $t7, $zero, NoCarrySub
			#there is a carry
			li $t0, 0x000000ff
			and $s7, $t0, $s3
			sll $s7, $s7, 24
			srl $t9, $t9, 1
			or $s4, $t9, $s7
			addiu $s2, $s2, 1 # add 1 to the exponent
			li $t0, 0xffffff00
			and $s3, $s3, $t0
			j NoCarrySubEnd
		NoCarrySub:
			# check if the leading bit is 1, if not normalize.
			sll $s3, $s3, 1
			clz $s6, $s3 # the amount of shifting to make the msb 1
			sllv $s3, $s3, $s6
			subu $s2, $s2, $s6 # shift left ? subtract from the exponent
		NoCarrySubEnd:
		sll $t3, $t3, 1
		sll $t6, $t6, 1
		
		# Rounding:
		beq $s4, $zero, doneSub
			# round bit -> t1
			li $t0, 0x80000000
			and $t1, $s4, $t0
			# the sticky bit -> t2
			li $t2, 0
			li $t0, 0x7fffffff
			and $t3, $s4, $t0
			
			beq $t3, $zero, ZeroStickyBitSub
				li $t2, 1
			ZeroStickyBitSub:
			
			# the system that this program uses:
			# RS = 11 -> add
			# RS = 01 or 00 -> discard RS
			# RS = 10 -> nearest even
			
			bne $t1, 0x80000000, doneSub
				bne $t2, 1, NearestEvenSub
					# RS = 11
					addiu $s3, $s3, 1
					beq $s5, $zero, doneSub
						addiu $s3, $s3, -2
						j doneSub
				NearestEvenSub:
					# RS = 10
					li $t0, 0x00000001
					and $t4, $s3, $t0
					
					bne $t4, 1, doneSub
						addiu $s3, $s3, 1
						beq $s5, $zero, doneSub
							addiu $s3, $s3, -2
doneSub:
# rearrange the result and save it in f0
# the significand in s3
# the exp_value in s2
# the sign in s5
li $t0, 0x7fffffff
and $s3, $s3, $t0
srl $s3, $s3, 8			
addiu $s2, $s2, 127
sll $s2, $s2, 23
zeroSub:
or $s7, $s5, $s2
or $s7, $s7, $s3
			
mtc1 $s7, $f0
			
jr $ra


fmul:
li $s0, 0
li $s1, 0
li $s2, 0
li $s4, 0
li $s5, 0

bne $t2, $zero, notZeroMulFirst
	bne $t3, $zero, notZeroMulFirst
		li $s3, 0
		li $s2, 0
		j zeroResultMul
notZeroMulFirst:
bne $t5, $zero, notZeroMulSecond
	bne $t6, $zero, notZeroMulSecond
		li $s3, 0
		li $s2, 0
		j zeroResultMul
notZeroMulSecond:

# add the exponents
addu $s2, $t2, $t5

#second, the sign
xor $s5, $t1, $t4

# third, multiply
srl $t3, $t3, 8
srl $t6, $t6, 8
mult $t3, $t6

# the result is in hi and lo registers consisting of 48 bit
mfhi $s0
mflo $s1
## check if there is a carry
# the leading 16 bits will be in hi, so if the 16th bit is 1, there is a carry
andi $t8, $s0, 0x00008000

bne $t8, 0x00008000, noCarryMul
	addiu $s2, $s2, 1 # add to the exponent
	sll $t9, $s1, 31
	srl $s1, $s1, 1
	sll $t0, $s0, 31
	or $s1, $s1, $t0
	srl $s0, $s0, 1
noCarryMul:

sll $s3, $s0, 9
srl $t7, $s1, 23
or $s3, $s3, $t7

andi $s4, $s1, 0x7fffff
sll $s4, $s4, 9


# Rounding:	
# round bit -> t1
li $t0, 0x80000000
and $t1, $s4, $t0
# the sticky bit -> t2
li $t2, 0
li $t0, 0x7fffffff
and $t3, $s4, $t0
or $t3, $t3, $t9
beq $t3, $zero, ZeroStickyBitMul
	li $t2, 1
ZeroStickyBitMul:
		
# the system that this program uses:
# RS = 11 -> add
# RS = 01 or 00 -> discard RS
# RS = 10 -> nearest even
			
bne $t1, 0x80000000, doneMul
	bne $t2, 1, NearestEvenMul
		# RS = 11
		addiu $s3, $s3, 1
		beq $s5, $zero, doneMul
			addiu $s3, $s3, -2
			j doneMul
	NearestEvenMul:
		# RS = 10
		li $t0, 0x00000001
		and $t4, $s3, $t0
				
		bne $t4, 1, doneMul
			addiu $s3, $s3, 1
			beq $s5, $zero, doneMul
				addiu $s3, $s3, -2			
doneMul:
# check if there is a need to renormalize
andi $t0, $s3, 0x01000000
beq $t0, $zero, dontRenormalize
	addiu $s2, $s2, 1
	srl $s3, $s3, 1
dontRenormalize:
# rearrange the result and save it in f0
# the significand in s3
# the exp_value in s2
# the sign in s5
li $t0, 0x7fffff
and $s3, $s3, $t0
addiu $s2, $s2, 127
sll $s2, $s2, 23
zeroResultMul:
or $s7, $s5, $s2
or $s7, $s7, $s3
			
mtc1 $s7, $f0
			
jr $ra
