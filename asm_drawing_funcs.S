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
    pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp       # Allocate space and save registers

    movq %rdi, %r12      # img
    movq %rsi, %r13      # rect
    movl %edx, %r15d     # color

    # Calculate and clamp x_start
    movl RECT_X_OFFSET(%r13), %edi  # rect->x
    movl $0, %esi
    movl IMAGE_WIDTH_OFFSET(%r12), %edx  # img->width
    call clamp
    movl %eax, %r8d      # x_start

    # Calculate and clamp y_start
    movl RECT_Y_OFFSET(%r13), %edi  # rect->y
    movl $0, %esi
    movl IMAGE_HEIGHT_OFFSET(%r12), %edx  # img->height
    call clamp
    movl %eax, %r9d      # y_start

    # Calculate and clamp x_end
    movl RECT_X_OFFSET(%r13), %edi
    addl RECT_WIDTH_OFFSET(%r13), %edi  # rect->x + rect->width
    movl $0, %esi
    movl IMAGE_WIDTH_OFFSET(%r12), %edx
    call clamp
    movl %eax, %r10d     # x_end

    # Calculate and clamp y_end
    movl RECT_Y_OFFSET(%r13), %edi
    addl RECT_HEIGHT_OFFSET(%r13), %edi  # rect->y + rect->height
    movl $0, %esi
    movl IMAGE_HEIGHT_OFFSET(%r12), %edx
    call clamp
    movl %eax, %r11d     # y_end

    # Iterate over y coordinates
    movl %r9d, %eax      # Start from y_start
.Ly_loop:
    cmpl %r11d, %eax     # Compare with y_end
    jge .Lend_y_loop     # If y >= y_end, exit loop

    # Iterate over x coordinates
    movl %r8d, %ecx      # Start from x_start
.Lx_loop:
    cmpl %r10d, %ecx     # Compare with x_end
    jge .Lend_x_loop     # If x >= x_end, exit loop

    # Draw the pixel
    movq %r12, %rdi      # img
    movl %ecx, %esi      # x
    movl %eax, %edx      # y
    movl %r15d, %r8d     # color
    call draw_pixel

    incl %ecx            # Increment x
    jmp .Lx_loop

.Lend_x_loop:
    incl %eax            # Increment y
    jmp .Ly_loop

.Lend_y_loop:
    addq $8, %rsp       # Restore the stack
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
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
	pushq %r12          # preserve value of %r12
    pushq %r13          # preserve value of %r13
    pushq %r14          # preserve value of %r14
    pushq %r15          # preserve value of %r15
	pushq %rbx			# preserve value of %rbx
	pushq %rbp			# preserve value of %rbp
	subq $8, %rsp       # align stack pointer 


    movq %rdi, %r15    # move pointer to struct Image to r15
	movl %esi, %r12d    # move x to r12d
    movl %edx, %r13d    # move y to r13d
    movl %ecx, %r14d    # move radius to r14d

	# outer loop
	movl %r14d, %r10d	# move radius to r10d
	negl %r10d          # i = -r
	movl %r10d, %ebp    # save initial i value in ebp
	
.LouterLoopStart:
	cmpl %r14d, %ebp    # compare i with r
	jg .LouterLoopEnd   # if i > r, exit outer loop

	movl %r14d, %r10d	# move radius to r10d
	negl %r10d          # j = -r
	movl %r10d, %ebx		# save initial j value in ebx

.LinnerLoopStart:
	cmpl %r14d, %ebx	# compare j with r
	jg .LinnerLoopEnd   # if j > r, exit inner loop

	# check if points within the bonds
	movq %r12, %rdi  # x
    movq %r13, %rsi  # y
    leaq (%r12d, %ebx), %rdx  # x+j
    leaq (%r13d, %ebp), %rcx  # y+i

	call square_dist
	movq %rax, %r10	# move squared distance into r10

	movq %r14, %rdi  # move r into first parameter
	call square      # square r

    cmpq %rax, %r10  # Compare r^2 with squared distance
    jg .LnextJ       # If squared distance > r^2, jump to next j

	movq %r15, %rdi     # move pointer to Image to first parameter
	leal (%r12d, %ebx), %esi    # actual x = x center + j
	leal (%r13d, %ebp), %edx    # actual y = y center + i

	call in_bounds
	testl %eax, %eax    # Test the return value in %eax
    jz .LnextJ          # If zero (false), jump to next_j to skip setting the pixel

	# set pixel if in bounds
	movq %r15, %rdi     # move pointer to Image to first parameter
	leal (%r12d, %ebx), %esi    # actual x = x center + j
	leal (%r13d, %ebp), %edx    # actual y = y center + i
	call compute_index          # result is in %rax

	movq %r15, %rdi             # img pointer
    movl %eax, %esi             # Move result of compute_index (index) to %rsi
    movl %r8d, %edx             # Move color to %edx; assuming color is in %r15d

    call set_pixel              # Call set_pixel with these arguments


.LnextJ:
    incl %ebx                   # Increment j
    jmp .LinnerLoopStart        # Jump back to start of inner loop

.LinnerLoopEnd:
	incl %ebp             # increment i
	jmp .LouterLoopStart  # jump to start of outer loop

.LouterLoopEnd:
	addq $8, %rsp       # restore stack pointer
	popq %rbp			# restore value of %rbp
	popq %rbx			# restore value of %rbx
	popq %r15           # restore value of %r15
	popq %r14           # restore value of %r14
	popq %r13           # restore value of %r13
	popq %r12           # restore value of %r12
	
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
	pushq %rbp
    movq %rsp, %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $32, %rsp       # Allocate space and save registers

    movq %rdi, %r12      # img (destination image)
    movl %esi, %r13d     # x (destination x-coordinate)
    movl %edx, %r14d     # y (destination y-coordinate)
    movq %rcx, %r15      # tilemap (source tilemap image)
    movq %r8, %rbp       # tile (source tile rectangle)

    # Calculate source and destination bounds
    movl RECT_X_OFFSET(%rbp), %eax
    movl RECT_Y_OFFSET(%rbp), %ebx
    addl RECT_WIDTH_OFFSET(%rbp), %eax   # sourceXEnd = tile->x + tile->width
    addl RECT_HEIGHT_OFFSET(%rbp), %ebx  # sourceYEnd = tile->y + tile->height

    # Bounds check: if tile is outside the tilemap, return
    cmpl IMAGE_WIDTH_OFFSET(%r15), %eax
    jge .Lend_draw_tile
    cmpl IMAGE_HEIGHT_OFFSET(%r15), %ebx
    jge .Lend_draw_tile

    xorl %esi, %esi       # offsetY = 0

.Ltile_y_loop:
    cmpl RECT_HEIGHT_OFFSET(%rbp), %esi  # Compare offsetY with tile->height
    jge .Lend_draw_tile                  # End loop if offsetY >= tile->height

    # Calculate sourceY and destY
    leal (%r14d, %esi), %edi             # destY = y + offsetY
    addl RECT_Y_OFFSET(%rbp), %esi       # sourceY = tile->y + offsetY

    xorl %ecx, %ecx                      # offsetX = 0

.Ltile_x_loop:
    cmpl RECT_WIDTH_OFFSET(%rbp), %ecx   # Compare offsetX with tile->width
    jge .Lnext_tile_row                  # End loop if offsetX >= tile->width

    # Calculate sourceX and destX
    leal (%r13d, %ecx), %edx             # destX = x + offsetX
    addl RECT_X_OFFSET(%rbp), %ecx       # sourceX = tile->x + offsetX

    # Compute sourceIndex and destIndex
    pushq %rcx
    movq %r15, %rdi                      # tilemap
    movl %ecx, %esi                      # sourceX
    movl %esi, %edx                      # sourceY
    call compute_index                   # Compute sourceIndex
    movl %eax, %r8d                      # Store sourceIndex

    movq %r12, %rdi                      # img
    movl %edx, %esi                      # destX
    movl %edi, %edx                      # destY
    call compute_index                   # Compute destIndex
    popq %rcx

    # Copy pixel from tilemap to img
    movl (%r15, %r8d, 4), %eax            # Load pixel from tilemap.data[sourceIndex]
    movl %eax, (%r12, %rax, 4)           # Store pixel into img.data[destIndex]

    incl %ecx                            # Increment offsetX
    jmp .Ltile_x_loop                    # Continue looping through columns

.Lnext_tile_row:
    incl %esi                            # Increment offsetY
    jmp .Ltile_y_loop                    # Continue looping through rows

.Lend_draw_tile:
    addq $32, %rsp                       # Restore the stack
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
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
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/
