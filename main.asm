.data
	toWrite: .asciiz "Hello World was here"
	inputFile: .asciiz "/home/clysman/Dev/Unifor/ASM/cpf-validation/test.txt"
	outputFile: .asciiz "/home/clysman/Dev/Unifor/ASM/cpf-validation/out.txt"
	output: .asciiz "Resultado: \n"
	carriage: .asciiz "\n"
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
	
	la $a0, output
	li $v0, 4
	syscall
	
	move $t0, $zero
	
	while:
		beq $t1, -48, exit
		
		# indice
		lb $t1, fileWords($t0)
		sub $t1, $t1, 48
	
		la $a0, 0($t1)
		li $v0, 1
		syscall
		la $a0, carriage
		li $v0, 4
		syscall
		
		addi $t0, $t0, 1	
		
		j while
	
	exit:
		#Close the file
  		li $v0, 16         		# close_file syscall code
  		move $a0, $s0      		# file descriptor to close
  		syscall
	
	
