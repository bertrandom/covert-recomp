/* BUG.H - declarations for BUG.EXE (wiretaps and car tracers on a circuit board).
 * Reconstructed for Microsoft C 5.1: CL /AS /Gs /Oas. K&R style, no prototypes
 * for library routines (the original didn't include <string.h>). */
#include "mps.h"

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)

/* Assembly segment (far) */
extern void far link_driver_stubs();
extern void far drv_play_sound();
extern void far drv_begin_image_grab();
extern void far drv_end_image_grab();
extern int  far drv_get_image();

/* MicroProse library modules */
extern int  text_window();
extern void load_env();
extern void save_env();
extern void load_picture_swapped();
extern int  clamp();
extern void randomize();
extern void flush_input();
extern int  require_disk();

/* MS C runtime */
extern int  int86();

/* Program globals */
extern int  difficulty;             /* 0-3 */
extern int  orig_difficulty;        /* as passed in by the game */
extern int  bug_running;
extern int  time_limit;             /* seconds */
extern int  car_tracer;             /* 1: installing a car tracer instead of phone taps */
extern int  progress;               /* tracer progress (env byte 8 = progress * 5) */
extern int  alarms;                 /* env byte 9 */
extern int  camera_img, camera_img2;
extern int  quit_flag;
extern char colormap[];
