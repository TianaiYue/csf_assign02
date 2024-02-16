// C implementations of drawing functions (and helper functions)

/*
 * Implementation of drawing and helper functions in C 
 * for basic graphic operations.
 * CSF Assignment 2
 * Tianai Yue, Cassie Zhang
 * tyue4@jhu.edu, xzhan304@jhu.edu
 */

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "drawing_funcs.h"

////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////

// implement helper functions


// Checks x and y coordinates to determine whether they 
// are in bounds in the specified image.

// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)

// Returns:
//   a int32_t, 1 if the coordinates are within bounds, 
//   0 otherwise

int32_t in_bounds(struct Image *img, int32_t x, int32_t y) {
  if (x >= 0 && x < img->width && y >= 0 && y < img->height) {
    return 1;
  } else {
    return 0;
  }
}

//
// Computes the index of a pixel in an image’s data array 
// given its x and y coordinates.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//
// Returns:
//   the index of the pixel in the image's data array an 
//   uint32_t. Returns 0 if coordinates are out of bounds
//
uint32_t compute_index(struct Image *img, int32_t x, int32_t y) {
  return (uint32_t)(y * img->width + x);
}

//
// Constrains a value so that it is greater than or equal 
// to min and less than or equal to max.
//
// Parameters:
//   val - The value to be clamped.
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//
// Returns:
//   the clamped value as a int32_t
//
int32_t clamp(int32_t val, int32_t min, int32_t max) {
  if (val < min) {
    return min;
  } else if (val > max) {
    return max;
  } else {
    return val;
  }
}

//
// Returns the red, green, blue, and alpha components of a 
// pixel color value.
// 
// Parameters:
//   color - uint32_t color value
//
// Returns:
//   the color component as an uint8_t
//
uint8_t get_r(uint32_t color) {
  // bits 24-31
  return (uint8_t)(color >> 24);
}
uint8_t get_g(uint32_t color) {
  // bits 16-23
  return (uint8_t)(color >> 16);
}
uint8_t get_b(uint32_t color) {
  // bits 8-15
  return (uint8_t)(color >> 8);
}
uint8_t get_a(uint32_t color) {
  // bits 0-7 
  return (uint8_t)color;
}

//
// Blends foreground and background color component values 
// using a specified alpha (opacity) value.
// 
// Parameters:
//   fg    - The foreground color component (0-255)
//   bg    - The background color component (0-255)
//   alpha - The opacity value for the foreground, 
//           where 255 is fully opaque.
//
// Returns:
//   the blended color component as an uint8_t
//
uint8_t blend_components(uint32_t fg, uint32_t bg, uint32_t alpha) {
  uint32_t result = (alpha * fg + (255 - alpha) * bg) / 255;
  return (uint8_t)result;
}

//
// Blends foreground and background colors using the 
// foreground color’s alpha value to produce an opaque color. 
//
// Parameters:
//   fg    - The foreground color component in RGBA format
//   bg    - The background color component in RGBA format
//
// Returns:
//   the blended color as a uint32_t in RGBA format
//   with alpha component set to 255
//
uint32_t blend_colors(uint32_t fg, uint32_t bg) {
  uint8_t fg_a = get_a(fg);
  uint8_t blended_r = blend_components(get_r(fg), get_r(bg), fg_a);
  uint8_t blended_g = blend_components(get_g(fg), get_g(bg), fg_a);
  uint8_t blended_b = blend_components(get_b(fg), get_b(bg), fg_a);

  uint32_t blended_color = ((uint32_t)blended_r << 24) | ((uint32_t)blended_g << 16) | ((uint32_t)blended_b << 8) | ((uint32_t)255);
    
  return blended_color;
}

//
// Draws a single pixel to a destination image, blending the 
// specified foregroudn color with the existing background 
// color, at a specified pixel index.
// 
// Parameters:
//   img   - pointer to struct Image
//   index - index where the pixel is set
//   color - uint32_t color value
//
void set_pixel(struct Image *img, uint32_t index, uint32_t color) {
  if (index < img->width * img->height) {
    uint32_t bg_color = img->data[index];
    uint32_t blended_color = blend_colors(color, bg_color);
    img->data[index] = blended_color;
  }
}

//
// Squares a int64_t value.
//
// Parameters:
//   x - int64_t value to be squared
//
// Returns:
//   the square of the input value as an int64_t
//
int64_t square(int64_t x) {
  return x * x;
}

//
// Finds the distances between two points.
//
// Parameters:
//   x1, y1 - coordinates of the first point
//   x2, y2 - coordinates of the second point
//
// Returns:
//   the distances between the two points as an int64_t
//
int64_t square_dist(int64_t x1, int64_t y1, int64_t x2, int64_t y2) {
  int64_t distance_x = x2 - x1;
  int64_t distance_y = y2 - y1;

  // Return the sum of the squares of the differences
  return square(distance_x) + square(distance_y);
}


////////////////////////////////////////////////////////////////////////
// API functions
////////////////////////////////////////////////////////////////////////

//
// Draw a pixel.
//
// Parameters:
//   img   - pointer to struct Image
//   x     - x coordinate (pixel column)
//   y     - y coordinate (pixel row)
//   color - uint32_t color value
//
void draw_pixel(struct Image *img, int32_t x, int32_t y, uint32_t color) {
  if (in_bounds(img, x, y)) {
    uint32_t index = compute_index(img, x, y);
    set_pixel(img, index, color);
  }
}

//
// Draw a rectangle.
// The rectangle has rect->x,rect->y as its upper left corner,
// is rect->width pixels wide, and rect->height pixels high.
//
// Parameters:
//   img     - pointer to struct Image
//   rect    - pointer to struct Rect
//   color   - uint32_t color value
//
void draw_rect(struct Image *img,
               const struct Rect *rect,
               uint32_t color) {
  // clamp coordinates to be within image bounds.
  int32_t x_start = clamp(rect->x, 0, img->width);
  int32_t y_start = clamp(rect->y, 0, img->height);
  int32_t x_end = clamp(rect->x + rect->width, 0, img->width);
  int32_t y_end = clamp(rect->y + rect->height, 0, img->height);

  //draw each pixel in the rect area
  for (int32_t y = y_start; y < y_end; y++) {
    for (int32_t x = x_start; x < x_end; x++) {
      draw_pixel(img, x, y, color);
    }
  }
}


//
// Draw a circle.
// The circle has x,y as its center and has r as its radius.
//
// Parameters:
//   img     - pointer to struct Image
//   x       - x coordinate of circle's center
//   y       - y coordinate of circle's center
//   r       - radius of circle
//   color   - uint32_t color value
//
void draw_circle(struct Image *img,
                 int32_t x, int32_t y, int32_t r,
                 uint32_t color) {
  // loop over a square bounding box that contains the circle
  for (int32_t i = -r; i <= r; i++) {
    for (int32_t j = -r; j <= r; j++) {
      // check if points within the bonds
      if (i*i + j*j <= r*r) {
        if (in_bounds(img, x+j, y+i)) {
          set_pixel(img, compute_index(img, x+j, y+i), color);
        }
      }
    }
  }
}

//
// Draw a tile by copying all pixels in the region
// enclosed by the tile parameter in the tilemap image
// to the specified x/y coordinates of the destination image.
// No blending of the tile pixel colors with the background
// colors should be done.
//
// Parameters:
//   img     - pointer to Image (dest image)
//   x       - x coordinate of location where tile should be copied
//   y       - y coordinate of location where tile should be copied
//   tilemap - pointer to Image (the tilemap)
//   tile    - pointer to Rect (the tile)
//
void draw_tile(struct Image *img,
               int32_t x, int32_t y,
               struct Image *tilemap,
               const struct Rect *tile) {
 // check if tile rectangle is not entirely within the bounds of tilemap
  if (tile->x < 0 || tile->y < 0 || tile->x + tile->width > tilemap->width || tile->y + tile->height > tilemap->height) {
    return;
  }
  int32_t source_y = tile->y, dest_y = y;
    // loop through each row of the tile
    for (int32_t i = 0; i < tile->height; ++i, ++source_y, ++dest_y) {
        int32_t source_x = tile->x, dest_x = x;
        // loop through each column of the tile
        for (int32_t j = 0; j < tile->width; ++j, ++source_x, ++dest_x) {
            // copy pixel to destination if it's in bounds
            if (in_bounds(img, dest_x, dest_y)) {
                img->data[compute_index(img, dest_x, dest_y)] = tilemap->data[compute_index(tilemap, source_x, source_y)];
            }
        }
    }
}

//
// Draw a sprite by copying all pixels in the region
// enclosed by the sprite parameter in the spritemap image
// to the specified x/y coordinates of the destination image.
// The alpha values of the sprite pixels should be used to
// blend the sprite pixel colors with the background
// pixel colors.
//
// Parameters:
//   img       - pointer to Image (dest image)
//   x         - x coordinate of location where sprite should be copied
//   y         - y coordinate of location where sprite should be copied
//   spritemap - pointer to Image (the spritemap)
//   sprite    - pointer to Rect (the sprite)
//
void draw_sprite(struct Image *img,
                 int32_t x, int32_t y,
                 struct Image *spritemap,
                 const struct Rect *sprite) {
  // check if sprite is not entirely within the bounds of the spritemap
  int32_t bottom_right_x = sprite->x + sprite->width - 1;
  int32_t bottom_right_y = sprite->y + sprite->height - 1;

  if (!in_bounds(spritemap, sprite->x, sprite->y) || 
      !in_bounds(spritemap, bottom_right_x, bottom_right_y)) {
    return;
  }
  // loop through sprite pixels, starting at top-left corner
  int32_t source_y = sprite->y;
  int32_t dest_y = y;
  // loop through each row of the sprite
  for (int32_t i = 0; i < sprite->height; ++i, ++source_y, ++dest_y) {
    int32_t source_x = sprite->x;
    int32_t dest_x = x;
    // loop through each column of the sprite
    for (int32_t j = 0; j < sprite->width; ++j, ++source_x, ++dest_x) {
      // draw pixel if it is in bounds and not transparent
      if (in_bounds(spritemap, source_x, source_y) && get_a(spritemap->data[compute_index(spritemap, source_x, source_y)]) > 0) {
        draw_pixel(img, dest_x, dest_y, spritemap->data[compute_index(spritemap, source_x, source_y)]);
      }
    }
  }
}