/* CODE.H - declarations for CODE.EXE (cryptography workstation).
 * Reconstructed for Microsoft C 5.1: CL /AS /Gs /Oas. K&R style, no prototypes
 * for library routines (the original didn't include <string.h>). */

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)

typedef struct RastPort {
    int page;           /* +00 graphics page */
    int x0, y0;         /* +02 origin */
    int x1, y1;         /* +06 clip limits */
    int textbg;         /* +0A draw text with background */
    int textcolor;      /* +0C */
    int fillcolor;      /* +0E */
    int font;           /* +10 */
} RastPort;

/* MicroProse library (assembly segment): far entry points */
extern void far link_driver_stubs();
extern void far drv_play_sound();
extern void far drv_slot36();
extern void far drv_set_color_map();
extern void far drv_copy_rect();
extern void far gfx_fill_rect();

/* MicroProse C library */
extern int  text_window();
extern void require_disk();
extern void randomize();
extern int  random();
extern int  clamp();
extern int  get_key();
extern void draw_line();
extern void draw_text();
extern void draw_text_transparent();
extern void wait_retrace();
extern void fill_rect_xy();

/* MS C runtime (no headers in the original) */
extern char *itoa();

/* Globals */
extern RastPort *g_gfx;            /* screen RastPort */
extern int  difficulty;
extern unsigned options;
extern int  env44;
extern int  done;
extern int  result;
extern int  elapsed;               /* seconds, written back to env */
extern int  ticks;
extern int  paused;
extern int  nletters;
extern int  revealed[];            /* letters revealed by the computer */
extern int  count[];               /* frequency of each cipher letter (0 = 'A') */
extern char message[];
extern char numbuf[];
extern char hyphenate;
extern union { struct { unsigned char al, ah; } h; } bios_regs;
