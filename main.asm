.data
	inputFile: .asciiz "/home/clysman/Dev/Unifor/ASM/cpf-validation/test.txt"
	validMessage: .asciiz " - Valido \n"
	invalidMessage: .asciiz " - Invalido \n"
	newLine: .asciiz "\n"
	fileWords: .space 1024

.text
  	li $v0, 13           	# open_file syscall code = 13
  	la $a0, inputFile     	# get the file name
  	li $a1, 0           	# file flag = read (0)
  	syscall
  	move $s0, $v0        	# save the file descriptor. $s0 = file
	
	#read the file
	li $v0, 14				# read_file syscall code = 14
	move $a0, $s0			# file descriptor
	la $a1, fileWords  		# The buffer that holds the string of the WHOLE file
	la $a2, 1024			# hardcoded buffer length
	syscall
	
	# The calculate fucntion use the $t0, $t1, $t2, $t3, $t4, $s1, $s2 registers,
	# each has a specific function:
	# $t0: file content index
	# $t1: read number
	# $t2: weight for calculation([0,11])
	# $t3: result of read number and weight multiplication
	# $t4: result accumulator($t4 = $t3 + $t4)
	# $s1: lenght of cpf number
	# $s2: limit of multiplied numbers to calculate validator digit
	move $t0, $zero			# set 0 to $t0
	li $t2, 10				# load 10 to initial weight
	li $s1, 11				# lenght of cpf
	li $s2, 9				# set 9 to $s2
	calculate:
		lb $t1, fileWords($t0)			# load content of file position
		addu $t1, $t1, -48				# char to int conversion
		
		beq $t1, -48, exit				# exit when reaching the EOF(-48)
		beq $t1, -38, jumpToNextCpf 	# call jumpToNextCpf when '\n'(-38)
		beq $t0, $s2, calculateValidatorDigit	# call calculateValidatorDigit when $t0(index) equal $s2
		
		mul $t3, $t1, $t2				# $t3 = $t1 * $t2
		add $t4, $t3, $t4				# $t4 = $t3 + $t4
		sub $t2, $t2, 1					# $t2 = $t2 - 1
		addi $t0, $t0, 1				# $t0 = $t0 + 1
		
		j calculate						# return to calculate
	
	jumpToNextCpf:
		add $t0, $t0, 1					# when calculate is finish $t0 assume the last index of past cpf number, sum 1 to next
		li $t2, 10						# set $t2 to initial weight
		li $s3, 0						# set count of validated digits to zero
		jal resetRegisters				# reset temporary registers
 		
		addi $s2, $t0, 9				# plus 9 to limit of next cpf				
		
		j calculate						# jump to calculate next cpf
	
	# To calculate the validator digit, the $t5 register
	# is used to store the valid digit to the current cpf
	calculateValidatorDigit:
		div $t4, $s1					# $t4/$s1(11)
		mfhi $t5						# move rest of division to $t5
		blt $t5, 2, setToZeroValidatorDigit 	# if rest of division is less than two set to 0
		 
		sub $t5, $s1, $t5				# $t5 = $s1(11) - $t5
		
		j checkValidatorDigit
		
	setToZeroValidatorDigit:
		li $t5, 0						# $t5 = 0
		
		j checkValidatorDigit

	checkValidatorDigit:
		lb $t6, fileWords($t0)			# load in $t6 the cpf validator digit present in the file
		addi $t6, $t6, -48				# char to int conversion
		
		beq $t5, $t6, validCpf			# $t5 == $t6
		j invalidCpf
		
	invalidCpf:
		jal printCurrentCpf
		la $a0, invalidMessage
		jal printMessage
		
		j jumpToNextCpf
	
	validCpf:
		addi $t0, $t0, -9		# set $t0 to initial value($t0 = $t0 - 9)
		addiu $t2, $t2, 10		# set 11 to initial weight($t2 = $t2(1) + 10)
		addiu $s2, $s2, 1		# set 10 to limit of validator digits($s2 = $s2(9) + 1)
		addiu $s3, $s3, 1		# number of calculated digits
	
		beq $s3, 2, printValidMessage	# print valid message if number of calculated digits is equals 2
		jal resetRegisters
		j calculate
	
	printValidMessage:
		jal printCurrentCpf
		la $a0, validMessage
		jal printMessage
		
		j jumpToNextCpf
		
	printCurrentCpf:
		jr $ra

	printMessage:
		li $v0, 4
		syscall
		jr $ra
	
	resetRegisters:
		li $t1, 0
		li $t3, 0
		li $t4, 0
		jr $ra
		
	exit:
		#Close the file
  		li $v0, 16         			# close_file syscall code
  		move $a0, $s0      			# file descriptor to close
  		syscall
  		
  		li $v0, 10
  		syscall
