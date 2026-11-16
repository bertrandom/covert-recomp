/* MPS.H - MicroProse C library used by every Covert Action module.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */

typedef struct RastPort {
    int page;           /* +00 graphics page */
    int x0, y0;         /* +02 origin */
    int x1, y1;         /* +06 clip limits */
    int textbg;         /* +0A draw text with background */
    int textcolor;      /* +0C */
    int fillcolor;      /* +0E */
    int font;           /* +10 */
} RastPort;

/* Assembly library / graphics driver entry points (far) */
extern void far gfx_line();
extern void far gfx_fill_rect();
extern void far drv_draw_text();
extern void far drv_copy_rect();

/* MS C runtime */
extern long time();

/* Library globals */
extern RastPort *g_gfx;
extern unsigned rnd_seed;
extern union { struct { unsigned char al, ah; } h; } bios_regs;

extern int far drv_kbhit();
extern int far drv_read_joystick_raw();
extern int far drv_getkey();
extern int far probe_drive();
extern void far gfx_show_page();
extern int far drv_char_width();
extern void far drv_recolor_rect();
extern void far drv_set_palette();
extern void far drv_set_color_map();
extern void far drv_joy_calibrate();
extern unsigned options;            /* 4 sound, 8 animations, 10h joystick, 20h practice */
extern RastPort *back_page;         /* defined by each program */
extern int screen_width;
