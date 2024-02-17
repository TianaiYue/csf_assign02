/*
 * Assembly-language implementations of the drawing functions
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
 * Returns:
 *   a int32_t, 1 if the coordinates are within bounds, 
 *   0 otherwise
 */
	.globl in_bounds
in_bounds:
	/*subq $8, %rsp*/

	cmp $0, %esi		/* compare 0 with x coordinate */
	jl .LOutofBounds  	/* if x < 0, jump to the false branch */

	movl 0(%rdi), %ebx	/* retrieve the width of the image */
	cmp %ebx, %esi 		/* compare width with x coordinate */
	jge .LOutofBounds	/* if x >= width, jump to the false branch */

	cmp $0, %edx		/* compare 0 with y coordinate */
	jl .LOutofBounds  	/* if y < 0, jump to the false branch */

	movl 4(%rdi), %ecx		/* retrieve the hight of the image */
	cmp %ecx, %edx 			/* compare height with y coordinate */
	jge .LOutofBounds		/* if y < height, jump to the false branch */

	movl $1, %eax		/*addq $8, %rsp*/
	ret

.LOutofBounds: 
	movl $0, %eax 		/*addq $8, %rsp*/
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

	movl 0(%rdi), %ebx		/* retrieve the width of the image */
	imull %edx, %ebx		/* multiply the width by the y coordinate */
	add %ebx, %esi		/* add the product to the x coordinate */
	movl %esi, %eax		/* move the index into the return register */

	ret

/* 
 * Constrains a value so that it is greater than or equal 
 * to min and less than or equal to max.
 * 
 * Parameters:
 *   %edi 	  - The value to be clamped
 *   %esi     - x coordinate (pixel column)
 *   %edx     - y coordinate (pixel row)
 *
 * Returns (in %eax):
 *   the clamped value as a int32_t
 *
 */
	.globl clamp
clamp:
	ret


/*
 * Returns the red, green, blue, and alpha components of a 
 * pixel color value.
 * 
 * Parameters:
 *   %edi - uint32_t color value
 *
 * Returns (in %al):
 *   the color components as uint8_t values
 */
	.globl get_r
get_r:
	movl %edi, %eax		# move color value to return value
	shrl $24, %eax		# Shift the color value right by 24 bits to get the red component
	ret

	.globl get_g
get_g:
	movl %edi, %eax		# move color value to return value
	shrl $16, %eax			# Shift the color value right by 16 bits to get the green component
	ret

	.globl get_b
get_b:
	movl %edi, %eax		# move color value to return value
	shrl $8, %eax 		# Shift the color value right by 8 bits to get the green component
	ret

	.globl get_a
get_a:
	movl %edi, %eax   	    # move color value to return value
	#shrl $8, %eax 		# Shift the color value right by 8 bits to get the green component
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

    movl %edi, %eax          # move foreground to %eax for multiplication
    imull %edx, %eax         # multiply foreground by alpha (result in %eax)

    movl $255, %ebx          # load 255 into %ebx
    subl %edx, %ebx          # subtract alpha from 255 (result in %ebx)
    imull %esi, %ebx         # multiply background by (255 - alpha) (result in %ebx)

    addl %ebx, %eax          # add the results of the two multiplications

    xorl %edx, %edx          # zero %edx before division to avoid overflow
    movl $255, %ebx          # load 255 into %ebx for division
    divl %ebx                # divide by 255 (quotient in %eax)

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
	/* TODO: implement */
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
	/* TODO: implement */
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
	/* TODO: implement */
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
	/* TODO: implement */
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
