/*
 * Assembly-language implementations of the drawing functions
 */

/*
 * Implementation of drawing and helper functions in Assembly
 * for basic graphic operations.
 * CSF Assignment 2
 * Tianai Yue, Cassie Zhang
 * tyue4@jhu.edu, xzhan304@jhu.edu
 */


/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/* Offsets of struct Rect fields */
#define RECT_X_OFFSET        0
#define RECT_Y_OFFSET        4
#define RECT_WIDTH_OFFSET    8
#define RECT_HEIGHT_OFFSET   12

	.section .text

/***********************************************************************
   Helper functions
   You should declare these as .globl so that
   they can be called from the unit test code.
 ***********************************************************************/

/* TODO: implement your helper functions here */

/*
 * Checks x and y coordinates to determine whether they 
 * are in bounds in the specified image.

 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 * 
 * Returns (in %eax):
 *   a int32_t, 1 if the coordinates are within bounds, 
 *   0 otherwise
 */
	.globl in_bounds
in_bounds:
	cmpl $0, %esi		# compare 0 with x coordinate
	jl .LoutofBounds  	# if x < 0, jump to the false branch 

	movl IMAGE_WIDTH_OFFSET(%rdi), %r10d	# retrieve the width of the image
	cmpl %r10d, %esi 		# compare width with x coordinate
	jge .LoutofBounds	# if x >= width, jump to the false branch

	cmpl $0, %edx		# compare 0 with y coordinate
	jl .LoutofBounds  	# if y < 0, jump to the false branch

	movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d		# retrieve the hight of the image
	cmpl %r11d, %edx       # compare y coordinate with height
	jge .LoutofBounds     # if y >= height, jump to the false branch

	movl $1, %eax		# set return value as one
	ret

.LoutofBounds: 
	movl $0, %eax		# set return value as zero
	ret


/*
 * Computes the index of a pixel in an image’s data array 
 * given its x and y coordinates.
 *
 * Parameters:
 *   %rdi  - pointer to struct Image
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 *
 * Returns (in %eax):
 *   the index of the pixel in the image's data array as 
 *   uint32_t. Returns 0 if coordinates are out of bounds.
 */
	.globl compute_index
compute_index:
	pushq %rbx				# preserve value of %rbx

	movl IMAGE_WIDTH_OFFSET(%rdi), %ebx		# retrieve the width of the image
	imull %edx, %ebx		# multiply the width by the y coordinate
	addl %ebx, %esi			# add the product to the x coordinate
	movl %esi, %eax			# move the index into the return register

	popq %rbx				# restore value of %rbx
	ret

/* 
 * Constrains a value so that it is greater than or equal 
 * to min and less than or equal to max.
 * 
 * Parameters:
 *   %edi 	  - The value to be clamped
 *   %esi     - min coordinate
 *   %edx     - max coordinate
 *
 * Returns (in %eax):
 *   the clamped value as a int32_t
 *
 */
	.globl clamp
clamp:
    movl %edi, %eax        # move the val into eax as a default

    cmpl %esi, %edi        # compare val with min
    cmovl %esi, %eax       # if val is less than min, move min into eax

    cmpl %edx, %eax        # compare current return value with max
    cmovg %edx, %eax       # if current return value is greater than max, move max into eax

    ret                    # return with eax holding the clamped value
                

/*
 * Returns the red, green, blue, and alpha components of a 
 * pixel color value.
 * 
 * Parameters:
 *   %edi - uint32_t color value
 *
 * Returns (in %eax):
 *   the color components as uint8_t values
 */
	.globl get_r
get_r:
	movl %edi, %eax		# move color value to return value
	shrl $24, %eax		# shift the color value right by 24 bits to get the red component
	ret

	.globl get_g
get_g:
	movl %edi, %eax		# move color value to return value
	shrl $16, %eax		# shift the color value right by 16 bits to get the green component
	andl $0xFF, %eax	# get the least significant 8 bits
	ret

	.globl get_b
get_b:
	movl %edi, %eax		# move color value to return value
	shrl $8, %eax 		# shift the color value right by 8 bits to get the blue component
	andl $0xFF, %eax	# get the least significant 8 bits
	ret

	.globl get_a
get_a:
	movl %edi, %eax   	# move color value to return value
	andl $0xFF, %eax     # get the least significant 8 bits
	ret


/*
 * Blends foreground and background color component values 
 * using a specified alpha (opacity) value.
 *
 * Parameters:
 *   %edi - foreground color component (0-255)
 *   %esi - background color component (0-255)
 *   %edx - The opacity value for the foreground, where 255 is fully opaque.
 *
 * Returns (in %eax):
 *   the blended color component as a uint32_t
 */
	.globl blend_components
blend_components:
	pushq %rbx			# preserve value of %rbx

    movl %edi, %eax		# move foreground to %eax for multiplication
    imull %edx, %eax	# multiply foreground by alpha (result in %eax)

    movl $255, %ebx		# load 255 into %ebx
    subl %edx, %ebx		# subtract alpha from 255 (result in %ebx)
    imull %esi, %ebx	# multiply background by (255 - alpha) (result in %ebx)

    addl %ebx, %eax		# add the results of the two multiplications

    xorl %edx, %edx		# zero %edx before division to avoid overflow
    movl $255, %ebx		# load 255 into %ebx for division
    divl %ebx			# divide by 255 (quotient in %eax)

	popq %rbx           # restore value of %rbx
    ret                  


/*
 * Blends foreground and background colors using the 
 * foreground color’s alpha value to produce an opaque color. 
 *
 * Parameters:
 *   %edi    - The foreground color component in RGBA format
 *   %esi    - The background color component in RGBA format
 *
 * Returns (in %eax):
 *   the blended color as a uint32_t in RGBA format
 *   with alpha component set to 255
 */
	.globl blend_colors
blend_colors:
	pushq %r12          # preserve value of %r12
	pushq %r13          # preserve value of %r13
	pushq %r14          # preserve value of %r14
	pushq %r15          # preserve value of %r15
	pushq %rbx		    # preserve value of %rbx
	subq $8, %rsp       # align stack pointer 

	movl %edi, %r12d 	# save fg color in r12d
	movl %esi, %r13d	# save bg color in r13d

	# get the alpha value of fg
	movl %r12d, %edi	# move fg color to the first parameter for get_a
	call get_a			# get alpha of fg
	movl %eax, %r14d	# save in callee saved value

	# blend the red color
	movl %r14d, %edx	# move to third parameter

	movl %r13d, %edi	# move bg color to first parameter
	call get_r			# get red of bg
	movl %eax, %esi		# save in second parameter

	movl %r12d, %edi    # fg color to first parameter for get_r
	call get_r			# get red of fg
	movl %eax, %edi		# save in first parameter

	call blend_components # blended_r
	shll $24, %eax		# shift right by 24 bits for the red component
	movl %eax, %r10d	# save in r10d

	# blend the green color 
	movl %r14d, %edx 	# move alpha of fg to third parameter

	movl %r13d, %edi 	# move bg color into first parameter
	call get_g			# get green of bg
	movl %eax, %esi		# save in second parameter

	movl %r12d, %edi	# move fg color into first parameter
	call get_g			# get green of fg
	movl %eax, %edi		# save in first parameter

	call blend_components	# blended_g
	shll $16, %eax		# shift right by 16 bits for the green component
	movl %eax, %r11d	# save in r11d
	
	# blend the blue color
	movl %r14d, %edx 	# move alpha of fg to third parameter

	movl %r13d, %edi 	# move bg color into first parameter
	call get_b			# get blue of bg
	movl %eax, %esi		# save in second parameter

	movl %r12d, %edi	# move fg color into first parameter
	call get_b			# get blue of fg
	movl %eax, %edi		# save in first parameter

	call blend_components	# blended_b
	shll $8, %eax		# shift right by 8 bits for the blue component
	movl %eax, %r15d    # save in r15d

	movl %r10d, %eax	# move blended_r to %eax
	orl %r11d, %eax     # OR blended_g with %eax, red and green
	orl %r15d, %eax     # OR blended_b with %eax, red, green, and blue are combined
	orl $0x000000FF, %eax  # OR, set the alpha component to 255

	addq $8, %rsp      # restore stack pointer
	popq %rbx          # restore value of %rbx
	popq %r15          # restore value of %r15
	popq %r14          # restore value of %r14
	popq %r13          # restore value of %r13
	popq %r12          # restore value of %r12
	ret


/*
 * Draws a single pixel to a destination image, blending the 
 * specified foreground color with the existing background 
 * color, at a specified pixel index.
 * 
 * Parameters:
 *   %rdi   - pointer to struct Image
 *   %esi - index where the pixel is set
 *   %edx - uint32_t color value
 */
	.globl set_pixel
set_pixel:
    pushq %r12              # preserve value of %r12
    pushq %r13              # preserve value of %r13
    pushq %r14              # preserve value of %r14
    pushq %r15              # preserve value of %r15
	pushq %rbx              # preserve value of %rbx
	subq $8, %rsp           # align stack pointer 

    movq %rdi, %r12         # save img pointer in %r12
    movl %esi, %r13d        # save index in %r13d
    movl %edx, %r14d        # save color in %r14d
  
	/* load image width and height, assuming %rdi points to the start of the Image structure */
    movl (%r12), %eax       # load image width
    movl 4(%r12), %ebx      # load image height

    /* calculate total pixels in the image */
    imul %ebx, %eax         # multiply width and height to get total pixels

    /* check if index is within bounds of the image data array */
    cmpl %eax, %r13d        # compare total pixels with the index
    jae .LindexOutofBounds  # if index is out of bounds

    /* assuming the pointer to the image data array is right after height */
    movq 8(%r12), %rcx      # load address of the image data array

    /* blend color if index is in bounds */
    movl (%rcx,%r13,4), %esi    # load existing color from data array at index
    movl %r14d, %edi            # set new color as foreground
    call blend_colors           # blend foreground and background colors
    movl %eax, (%rcx,%r13,4)    # store blended color back in data array

.LindexOutofBounds:	
	addq $8, %rsp      			 # restore stack pointer
	popq %rbx                    # restore value of %rbx
	popq %r15                    # restore value of %r15
	popq %r14                    # restore value of %r14
	popq %r13                    # restore value of %r13
	popq %r12                    # restore value of %r12
    ret

/*
 * Squares an int64_t value.
 *
 * Parameters:
 *   %rdi - int64_t value to be squared
 *
 * Returns (in %rax):
 *   the square of the input value as an int64_t
 */
	.globl square	
square:
	imulq %rdi, %rdi
	movq %rdi, %rax
	ret


/*
 * Finds the distance between two points.
 *
 * Parameters:
 *   %rdi, %rsi - coordinates of the first point
 *   %rdx, %rcx - coordinates of the second point
 *
 * Returns (in %rax):
 *   the distance between the two points as an int64_t
 */	
	.globl square_dist
square_dist:
	/* save values of callee-saved registers */
	pushq %r12          # preserve value of %r12
	pushq %r13          # preserve value of %r13
	subq $8, %rsp       # align stack pointer

	movq %rsi, %r12		# save value of y1
	movq %rcx, %r13		# save value of y2

	/* compute x2-x1 */
	subq %rdi, %rdx		# store x2-x1 in %rdi
	movq %rdx, %rdi		# pass x2-x1 as first arg to square
	call square			# compute (x1-x2)^2

	/* compute y2-y1 */
	subq %r12, %r13		# store y2-y1 in %r13
	movq %rax, %r12		# move (x2-x1)^2 to %r12
	movq %r13, %rdi		# pass y2-y1 as first arg to square
	call square			# compute (y1-y2)^2

	/* compute (x2-x1)^2 + (y2-y1)^2 */
	addq %r12, %rax		# put sum of squares in %rax

	/* restore values of callee-saved registers */
	addq $8, %rsp      # restore stack pointer
	popq %r13          # restore value of %r13
	popq %r12          # preserve value of %r12
	ret





/***********************************************************************
   Public API functions
 ***********************************************************************/

/*
 * Draw a pixel.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 *   %ecx     - uint32_t color value
 */
	.globl draw_pixel
draw_pixel:
    pushq %r12          # preserve value of %r12
    pushq %r13          # preserve value of %r13
    pushq %r14          # preserve value of %r14
    pushq %r15          # preserve value of %r15
	subq $8, %rsp       # align stack pointer 

    movq %rdi, %r12   	# move img pointer to %r12
    movl %esi, %r13d  	# move x coordinate to %r13d
    movl %edx, %r14d  	# move y coordinate to %r14d
    movl %ecx, %r15d  	# move color value to %r15d

    /* check if x, y are within image bounds */
    movq %r12, %rdi   	# set img as arg1
    movl %r13d, %esi  	# set x as arg2
    movl %r14d, %edx  	# set y as arg3
    call in_bounds   	# call in_bounds function
	cmpl $0, %eax        # compare the result with 0
    jz .LpixelOutofBounds   # If 0, jump to label indicating pixel is out of bounds

    /* calculate pixel index in image data array */
    movq %r12, %rdi   	# set img as arg1
    movl %r13d, %esi  	# set x as arg2
    movl %r14d, %edx  	# set y as arg3
    call compute_index  # call compute_index function
    movl %eax, %esi   	# move the index to %esi

    /* set the pixel color at the calculated index */
    movq %r12, %rdi   	# set img as arg1
    movl %r15d, %edx  	# set color as arg
    call set_pixel   	# call set_pixel function

.LpixelOutofBounds:
	addq $8, %rsp      # restore stack pointer
    popq %r15           # restore value of %r15
	popq %r14           # restore value of %r14
	popq %r13           # restore value of %r13
	popq %r12           # restore value of %r12
    ret


/*
 * Draw a rectangle.
 * The rectangle has rect->x,rect->y as its upper left corner,
 * is rect->width pixels wide, and rect->height pixels high.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %rsi     - pointer to struct Rect
 *   %edx     - uint32_t color value
 */
    .globl draw_rect
draw_rect:
    pushq %rbp                      # preserve value of %rbp
    movq %rsp, %rbp                 # set base pointer to stack pointer
    pushq %r12                      # preserve value of %r12
    pushq %r13                      # preserve value of %r13
    pushq %r14                      # preserve value of %r14
    pushq %r15                      # preserve value of %r15
    subq $48, %rsp                  # align stack pointer 

    movq %rdi, %r12                 # store image pointer in r12
    movq %rsi, %r13                 # store rect pointer in r13
    movl %edx, %r15d                # store color value in r15d

    # calculate and clamp x_start
    movl RECT_X_OFFSET(%r13), %edi          # load x-coordinate from Rect structure into edi
    movl $0, %esi                           # set 0 as the minimum clamp value in esi
    movl IMAGE_WIDTH_OFFSET(%r12), %edx     # load image width into edx for clamping
    call clamp                              # call the clamp function to clamp x-coordinate
    movl %eax, -4(%rbp)                     # store clamped x_start value on the stack

    # calculate and clamp y_start
    movl RECT_Y_OFFSET(%r13), %edi          # load y-coordinate from Rect structure into edi
    movl $0, %esi                           # set 0 as the minimum clamp value in esi
    movl IMAGE_HEIGHT_OFFSET(%r12), %edx    # load image height into edx for clamping
    call clamp                              # call the clamp function to clamp y-coordinate
    movl %eax, -8(%rbp)                     # store clamped y_start value on the stack

    # calculate and clamp x_end
    movl RECT_X_OFFSET(%r13), %edi          # load x-coordinate from Rect structure into edi
    addl RECT_WIDTH_OFFSET(%r13), %edi      # add rectangle width to x-coordinate
    movl $0, %esi                           # set 0 as the minimum clamp value in esi
    movl IMAGE_WIDTH_OFFSET(%r12), %edx     # load image width into edx for clamping
    call clamp                              # call the clamp function to clamp x_end
    movl %eax, -12(%rbp)                    # store clamped x_end value on the stack

    # calculate and clamp y_end
    movl RECT_Y_OFFSET(%r13), %edi          # load y-coordinate from Rect structure into edi
    addl RECT_HEIGHT_OFFSET(%r13), %edi     # add rectangle height to y-coordinate
    movl $0, %esi                           # set 0 as the minimum clamp value in esi
    movl IMAGE_HEIGHT_OFFSET(%r12), %edx    # load image height into edx for clamping
    call clamp                              # call the clamp function to clamp y_end
    movl %eax, -16(%rbp)                    # store clamped y_end value on the stack

    # y-coordinate loop start
.Ly_loop:
    movl -8(%rbp), %r10d           # load y_start into r10d for iteration
    cmpl -16(%rbp), %r10d          # compare y_start with y_end to determine loop exit
    jge .Lend_y_loop               # if y_start >= y_end, exit the loop

    # x-coordinate loop start
    movl -4(%rbp), %r10d           # load x_start into r10d for iteration
    movl %r10d, -20(%rbp)          # store current x-coordinate (x_start) on the stack
.Lx_loop:
    movl -12(%rbp), %r10d          # load x_end into r10d for comparison
    cmpl %r10d, -20(%rbp)          # compare current x-coordinate with x_end
    jge .Lend_x_loop               # if current x-coordinate >= x_end, exit the loop

    # drawing pixel at (x, y)
    movq %r12, %rdi                # set Image pointer for draw_pixel function
    movl -20(%rbp), %esi           # set x-coordinate as second parameter for draw_pixel
    movl -8(%rbp), %edx            # set y-coordinate as third parameter for draw_pixel
    movl %r15d, %ecx               # set color as fourth parameter for draw_pixel
    call draw_pixel                # call draw_pixel function to draw the pixel

    # increment x-coordinate and loop
    addl $1, -20(%rbp)             # increment the current x-coordinate
    jmp .Lx_loop                   # jump back to the start of the x-coordinate loop

.Lend_x_loop:
    addl $1, -8(%rbp)              # increment y-coordinate after finishing x-coordinate loop
    jmp .Ly_loop                   # jump back to the start of the y-coordinate loop

.Lend_y_loop:
    addq $48, %rsp              # restore stack pointer
    popq %r15                   # restore value of %r15
    popq %r14                   # restore value of %r14
    popq %r13                   # restore value of %r13
    popq %r12                   # restore value of %r12
    popq %rbp                   # restore value of %rbp
    ret


/*
 * Draw a circle.
 * The circle has x,y as its center and has r as its radius.
 *
 * Parameters:
 *   %rdi     - pointer to struct Image
 *   %esi     - x coordinate of circle's center
 *   %edx     - y coordinate of circle's center
 *   %ecx     - radius of circle
 *   %r8d     - uint32_t color value
 */
	.globl draw_circle
draw_circle:
	pushq %r12                  # preserve value of %r12
    pushq %r13                  # preserve value of %r13
    pushq %r14                  # preserve value of %r14
    pushq %r15                  # preserve value of %r15
	pushq %rbx			        # preserve value of %rbx
	pushq %rbp			        # preserve value of %rbp
	subq $8, %rsp               # align stack pointer 

    movq %rdi, %r15             # move pointer to struct Image to r15
	movl %esi, %r12d            # move x to r12d
    movl %edx, %r13d            # move y to r13d
    movl %ecx, %r14d            # move radius to r14d

	# outer loop
	movl %r14d, %r10d           # copy radius to r10d
    negl %r10d                  # negate r10d for start value
    movl %r10d, %ebp            # store start value in ebp
	
.LouterLoopStart:
    cmpl %r14d, %ebp            # compare i with radius
    jg .LouterLoopEnd           # if i > radius, exit loop

    # inner loop for x
    movl %r14d, %r10d           # copy radius to r10d
    negl %r10d                  # negate r10d for start value
    movl %r10d, %ebx            # store start value in ebx

.LinnerLoopStart:
    cmpl %r14d, %ebx            # compare j with radius
    jg .LinnerLoopEnd           # if j > radius, exit loop

    # check if point within circle
    movq %r12, %rdi             # move x for square_dist
    movq %r13, %rsi             # move y for square_dist
    leaq (%r12d, %ebx), %rdx    # calculate x+j for square_dist
    leaq (%r13d, %ebp), %rcx    # calculate y+i for square_dist
    call square_dist            # call square_dist
    movq %rax, %r10             # store square_dist result in r10

    movq %r14, %rdi             # move radius for square
    call square                 # call square
    cmpl %eax, %r10d            # compare squared radius with squared distance
    jg .LnextJ                  # if squared distance > squared radius, skip pixel

    # check if point is in bounds
    movq %r15, %rdi             # move image pointer for in_bounds
    leal (%r12d, %ebx), %esi    # calculate actual x
    leal (%r13d, %ebp), %edx    # calculate actual y
    call in_bounds              # call in_bounds
    testl %eax, %eax            # test result of in_bounds
    jz .LnextJ                  # if not in bounds, skip pixel

    # draw pixel
    movq %r15, %rdi             # move image pointer for draw_pixel
    leal (%r12d, %ebx), %esi    # calculate actual x
    leal (%r13d, %ebp), %edx    # calculate actual y
    movl %r8d, %ecx             # move color for draw_pixel
    call draw_pixel             # call draw_pixel

.LnextJ:
    incl %ebx                   # increment j
    jmp .LinnerLoopStart        # jump to the start of inner loop

.LinnerLoopEnd:
    incl %ebp                   # increment i
    jmp .LouterLoopStart        # jump to the start of outer loop

.LouterLoopEnd:
	addq $8, %rsp               # restore stack pointer
	popq %rbp			        # restore value of %rbp
	popq %rbx			        # restore value of %rbx
	popq %r15                   # restore value of %r15
	popq %r14                   # restore value of %r14
	popq %r13                   # restore value of %r13
	popq %r12                   # restore value of %r12
	
	ret

/*
 * Draw a tile by copying all pixels in the region
 * enclosed by the tile parameter in the tilemap image
 * to the specified x/y coordinates of the destination image.
 * No blending of the tile pixel colors with the background
 * colors should be done.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where tile should be copied
 *   %edx - y coordinate of location where tile should be copied
 *   %rcx - pointer to Image (the tilemap)
 *   %r8  - pointer to Rect (the tile)
 */
    .globl draw_tile
draw_tile:
    pushq %rbp                  # preserve value of %rbp
    movq %rsp, %rbp             # set base pointer to stack pointer
    pushq %r12                  # preserve value of %r12
    pushq %r13                  # preserve value of %r13
    pushq %r14                  # preserve value of %r14
    pushq %r15                  # preserve value of %r15
    pushq %rbx                  # preserve value of %rbx
    subq $56, %rsp              # align stack pointer 

    # store function arguments in callee-saved registers
    movq %rdi, %r12             # store image pointer in r12
    movl %esi, %r13d            # store x pointer in r13
    movl %edx, %r14d            # store y pointer in r14
    movq %rcx, %r15             # store tilemap pointer in r12
    movq %r8, %rbx              # store tile pointer in rbx

    # bounds checking
    # check tile->x < 0
    movl RECT_X_OFFSET(%rbx), %eax		# load tile->x into eax
    cmpl $0, %eax						# compare eax with 0
    jl .Lexit_tile						# if tile->x < 0, exit function

    # check tile->y < 0
    movl RECT_Y_OFFSET(%rbx), %eax		# load tile->y into eax
    cmpl $0, %eax						# compare eax with 0
    jl .Lexit_tile						# if tile->y < 0, exit function

    # check tile->x + tile->width > tilemap->width
    movl RECT_X_OFFSET(%rbx), %eax          # load tile's x offset
    addl RECT_WIDTH_OFFSET(%rbx), %eax      # add tile's width to x
    cmpl IMAGE_WIDTH_OFFSET(%r15), %eax     # compare with tilemap's width
    jg .Lexit_tile                          # jump if out of bounds

    # check tile->y + tile->height > tilemap->height
    movl RECT_Y_OFFSET(%rbx), %eax          # load tile's y offset again
    addl RECT_HEIGHT_OFFSET(%rbx), %eax     # add tile's height to y
    cmpl IMAGE_HEIGHT_OFFSET(%r15), %eax    # compare with tilemap's height
    jg .Lexit_tile                          # jump if out of bounds

    # initialize offsetX and offsetY to 0 and store them on the stack
    movl $0, -20(%rbp)                  # set offsetX to 0
    movl $0, -16(%rbp)                  # set offsetY to 0

.Ltile_row_loop:
    # check if current row is within tile height
    movl RECT_HEIGHT_OFFSET(%rbx), %eax # get tile height
    cmpl %eax, -16(%rbp)                # compare with offsetY
    jge .Lexit_tile                     # exit if offsetY >= tile height
    
    # calculate source and destination Y
    movl RECT_Y_OFFSET(%rbx), %r10d     # load tile's y offset
    addl -16(%rbp), %r10d               # add offsetY to tile's y
    movl %r10d, -24(%rbp)               # store calculated sourceY

    movl -16(%rbp), %r11d               # copy offsetY to r11d
    addl %r14d, %r11d                   # add y coordinate to offsetY
    movl %r11d, -28(%rbp)               # store calculated destY

    # loop through each column of the tile
    movl $0, -20(%rbp)                  # reset offsetX to 0

.Ltile_col_loop:
    movl RECT_WIDTH_OFFSET(%rbx), %eax  # get tile width
    cmpl %eax, -20(%rbp)                # compare with offsetX
    jge .Lnext_tile_row                 # proceed to next row if offsetX >= tile width

    # calculate sourceX, destX
    movl RECT_X_OFFSET(%rbx), %r10d     # load tile's x offset
    addl -20(%rbp), %r10d               # add offsetX to tile's x
    movl %r10d, -32(%rbp)               # store calculated sourceX

    movl -20(%rbp), %r11d               # copy offsetX to r11d
    addl %r13d, %r11d                   # add x coordinate to offsetX
    movl %r11d, -36(%rbp)               # store calculated destX

    movq %r12, %rdi                     # prepare destination image for in_bounds
    movl -36(%rbp), %esi                # pass destX as second argument
    movl -28(%rbp), %edx                # pass destY as third argument
    call in_bounds                      # call in_bounds function
    test %al, %al                       # test return value
    jz .Lnext_tile_col                  # skip pixel copy if not in bounds

    # calculate source index using sourceX and sourceY
    movq %r15, %rdi                     # move tilemap as first argument
    movl -32(%rbp), %esi                # pass sourceX as second argument
    movl -24(%rbp), %edx                # pass sourceY as third argument
    call compute_index                  # call compute_index function
    movl %eax, %r10d                    # store source index in r10d

    # calculate destination index using destX and destY
    movq %r12, %rdi                     # prepare destination image for in_bounds
    movl -36(%rbp), %esi                # pass destX as second argument
    movl -28(%rbp), %edx                # pass destY as third argument
    call compute_index                  # call compute_index function
	movl %eax, %r11d                    # store destination index in r11d

    # copy pixel value from tilemap to img
    movq IMAGE_DATA_OFFSET(%r15), %rcx  # load address of tilemap->data
    movq IMAGE_DATA_OFFSET(%r12), %rdx  # load address of img->data
    movl (%rcx, %r10, 4), %eax          # load pixel from tilemap into %eax using %r10
    movl %eax, (%rdx, %r11, 4)          # store pixel in img from %eax using %r11

.Lnext_tile_col:
    # increment offsetX and store it back on the stack
    addl $1, -20(%rbp)                  # increment offsetX
    jmp .Ltile_col_loop                 # jump back to start of column loop for next pixel

.Lnext_tile_row:
    # increment offsetY and store it back on the stack
    addl $1, -16(%rbp)                  # increment offsetY
    jmp .Ltile_row_loop                 # jump back to start of row loop for next row

.Lexit_tile:
    addq $56, %rsp      # restore stack pointer
    popq %rbx           # restore value of %rbx
    popq %r15           # restore value of %r15
    popq %r14           # restore value of %r14
    popq %r13           # restore value of %r13
    popq %r12           # restore value of %r12
    popq %rbp           # restore value of %rbp
    ret

/*
 * Draw a sprite by copying all pixels in the region
 * enclosed by the sprite parameter in the spritemap image
 * to the specified x/y coordinates of the destination image.
 * The alpha values of the sprite pixels should be used to
 * blend the sprite pixel colors with the background
 * pixel colors.
 *
 * Parameters:
 *   %rdi - pointer to Image (dest image)
 *   %esi - x coordinate of location where sprite should be copied
 *   %edx - y coordinate of location where sprite should be copied
 *   %rcx - pointer to Image (the spritemap)
 *   %r8  - pointer to Rect (the sprite)
 */
    .globl draw_sprite
draw_sprite:
    pushq %rbp                  # preserve value of %rbp
    movq %rsp, %rbp             # set base pointer to stack pointer
    pushq %r12                  # preserve value of %r12
    pushq %r13                  # preserve value of %r13
    pushq %r14                  # preserve value of %r14
    pushq %r15                  # preserve value of %r15
    pushq %rbx                  # preserve value of %rbx
    subq $56, %rsp              # align stack pointer 

    # load function arguments into registers
    movq %rdi, %r12             # store image pointer in r12
    movl %esi, %r13d            # store x pointer in r13
    movl %edx, %r14d            # store y pointer in r14
    movq %rcx, %r15             # store spritemap pointer in r15
    movq %r8, %rbx              # store sprite pointer in rbx

    # calculate bottom_right_x and bottom_right_y, storing them on the stack
    movl RECT_X_OFFSET(%rbx), %eax         # load sprite's top-left x  
    addl RECT_WIDTH_OFFSET(%rbx), %eax         # add sprite width
    subl $1, %eax               # adjust for bottom-right x
    movl %eax, -4(%rbp)         # store bottom-right x on stack

    movl RECT_Y_OFFSET(%rbx), %eax          # load sprite's top-left y
    addl RECT_HEIGHT_OFFSET(%rbx), %eax         # add sprite height
    subl $1, %eax               # adjust for bottom-right y
    movl %eax, -8(%rbp)         # store bottom-right y on stack

    # check if sprite is within bounds
    movq %r15, %rdi             # spritemap for in_bounds
    movl (%rbx), %esi          # sprite's top-left x for in_bounds
    movl 4(%rbx), %edx          # sprite's top-left y for in_bounds
    call in_bounds              # check if top-left in bounds
    test %al, %al               # test in_bounds result
    jz .Lexit                   # exit if not in bounds

    movq %r15, %rdi             # spritemap for in_bounds
    movl -4(%rbp), %esi         # bottom-right x for in_bounds
    movl -8(%rbp), %edx         # bottom-right y for in_bounds
    call in_bounds              # check if bottom-right in bounds
    test %al, %al               # test in_bounds result
    jz .Lexit                   # exit if not in bounds

    # initialize offsetX and offsetY to 0 and store them on the stack
    movl $0, -20(%rbp)                  # set offsetX to 0
    movl $0, -16(%rbp)                  # set offsetY to 0

.Lrow_loop_start:
    # check if current row is within sprite height
    movl RECT_HEIGHT_OFFSET(%rbx), %eax # store sprite height in temp %eax
    cmpl %eax, -16(%rbp)                # compare offset y to sprite height
    jge .Lexit                          # if greater or equal, exit
    # calculate source and destination Y
    movl RECT_Y_OFFSET(%rbx), %r10d     # temporarily use %r10d for sprite->y
    addl -16(%rbp), %r10d               # add offsetY to %r10d, now %r11d = sourceY
    movl %r10d, -24(%rbp)               # store sourceY in -24(%rbp)    

    movl -16(%rbp), %r11d               # temporarily use %r11d for offsetY
    addl %r14d, %r11d                   # add y to %r11d, now %r11d = destY
    movl %r11d, -28(%rbp)               # store destY in -28(%rbp)  

    # loop through each column of the sprite
    movl $0, -20(%rbp)                  # offsetX = 0

.Lcol_loop_start:
    movl RECT_WIDTH_OFFSET(%rbx), %eax # store sprite width in temp %eax
    cmpl %eax, -20(%rbp)               # compare offset x to sprite width
    jge .Lrow_loop_next                # if greater or equal, exit

    # calculate sourceX, destX
    movl RECT_X_OFFSET(%rbx), %r10d    # temporarily use %r10d for sprite->x
    addl -20(%rbp), %r10d              # Add offsetX to %r10d, now %r10d = sourceX
    movl %r10d, -32(%rbp)              # store sourceX in -32(%rbp) 

    movl -20(%rbp), %r11d              # temporarily use %r11d for offsetX
    addl %r13d, %r11d                  # Add x to offsetX
    movl %r11d, -36(%rbp)              # store destX in -36(%rbp) 

    # fetch pixel color from sprite and check for transparency
    movq %r15, %rdi                    # move spritemap to first arg
    movl -32(%rbp), %esi               # move sourceX to second arg
    movl -24(%rbp), %edx               # move sourceY to third arg
    call compute_index                 # call compute_index function
    movq 8(%r15), %rdi                 # assuming %r15 points to spritemap, and the data array is at offset 8
    movl (%rdi, %rax, 4), %eax         # Fetch the color
    movl %eax, -40(%rbp)               # Store the color

    # check if pixel is in bounds and not transparent, then draw
    movq %r12, %rdi                     # destination image for in_bounds
    movl -36(%rbp), %esi                # destination x for in_bounds
    movl -28(%rbp), %edx                # destination y for in_bounds
    call in_bounds                      # check destination pixel bounds
    test %al, %al                       # test in_bounds result
    jz .Lcol_loop_next                  # skip if out of bounds

    movl -40(%rbp), %edi               # move color to first arg
    call get_a                         # call get_a function
    test %al, %al                      # Test if alpha is not 0 (non-transparent)
    jz .Lcol_loop_next

    # fetch color from spritemap->data[computed_index] and draw pixel
    movq %r12, %rdi                    # move img to first arg
    movl -36(%rbp), %esi               # move destX to second arg
    movl -28(%rbp), %edx               # move destY to third arg
    movl -40(%rbp), %ecx               # move color to forth arg
    call draw_pixel                    # call draw_pixel function

.Lcol_loop_next:
    # increment offsetX and store it back on the stack
    addl $1, -20(%rbp)                  # increment offsetX
    jmp .Lcol_loop_start                 # jump back to start of column loop for next pixel

.Lrow_loop_next:
    # increment offsetY and store it back on the stack
    addl $1, -16(%rbp)                  # increment offsetY
    jmp .Lrow_loop_start                 # jump back to start of row loop for next row

.Lexit:
    addq $56, %rsp      # restore stack pointer
    popq %rbx           # restore value of %rbx
    popq %r15           # restore value of %r15
    popq %r14           # restore value of %r14
    popq %r13           # restore value of %r13
    popq %r12           # restore value of %r12
    popq %rbp           # restore value of %rbp
    ret

/*
vim:ft=gas:
*/

