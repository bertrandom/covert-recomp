/* ANIMOBJ.C - MicroProse library: the animation player object.
 * Play an animation to completion and the script callbacks (formerly
 * ANIMPLAY.C), the player hooks (anim_start, anim_set_active, anim_stop,
 * anim_step; empty stubs in STUBS.C for the programs without animations),
 * then the player itself (formerly ANIM.C). The .PAN file loader that follows
 * it is a second object, ANIMPAN.C: the original's code records break inside
 * decode_sprite, 0x3B0 bytes after pan_open, so a new object starts there.
 * A script (bytecode in a far segment) drives up to 50 sprites, each running
 * its own little motion program; frames are composed on the back page.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "mps.h"

struct WORDREGS { unsigned ax, bx, cx, dx, si, di, cflag; };
struct BYTEREGS { unsigned char al, ah, bl, bh, cl, ch, dl, dh; };
union REGS { struct WORDREGS x; struct BYTEREGS h; };
struct SREGS { unsigned es, cs, ss, ds; };

#define FP_OFF(fp) (*((unsigned *)&(fp)))
#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))

/* An animated sprite (0x34 bytes). */
struct sprite {
    int active;             /* +00 */
    int moved;              /* +02 */
    int parent;             /* +04 sprite it moves relative to; -2: none */
    int x0, y0;             /* +06 start position */
    int x, y;               /* +0A */
    int speed;              /* +0E initial rate */
    int rate;               /* +10 added to accum every frame */
    int accum;              /* +12 a step runs when it passes 0xFF */
    int loops[10];          /* +14 loop counters */
    int depth;              /* +28 loop nesting */
    int start;              /* +2A program start (offset in the script segment) */
    int flags;              /* +2C */
    char far *ptr;          /* +2E program pointer */
    unsigned char image;    /* +32 index into anim_images, 0xFF: hidden */
    char pad;
};

/* Graphics driver / assembly segment (far) */
extern void far clear_dirty_rows();
extern void far present_dirty_rows();
extern int  far drv_has_back_buffer();
extern int  far drv_mem_avail();
extern int  far drv_blit_sprite_var();  /* sprite blit variant (GAME 1000:0134, FINAL 1000:01C0) */
extern void far anim_set_pal();         /* palette for the player (GAME: drv_set_palette, FINAL 1000:00CA) */
extern void far blit_sprite();
extern void far blit_sprite_restore();
extern void far drv_clear_page();
extern int  far drv_begin_image_grab();
extern void far drv_end_image_grab();
extern void far drv_put_row();
extern void far drv_begin_image();
extern int  far drv_image_add_row();
extern int  far drv_end_image();
extern void far pic_begin_decode();
extern void far lzw_decode_row();

/* MS C runtime */
extern int  _bios_timeofday();
extern int  int86();
extern int  int86x();
extern int  memcmp();
extern int  strcmp();
extern unsigned _dos_allocmem();
extern int  _dos_freemem();

/* Animation data (one far segment). Uninitialized, so MSC makes it a far communal:
 * LINK gives it a FAR_BSS segment of its own, between _TEXT and DGROUP. */
struct anim_mem {
    int stack[1000];                    /* +000 script evaluation stack */
    int sounds[30];                     /* +7D0 sounds queued this frame */
    struct sprite sprites[50];          /* +80C */
};
struct anim_mem far anim_mem;

/* Library globals */
extern int  anim_present_mode;          /* 2: first frame, 1: second, 0: dirty rows */
extern int  anim_done;
extern int  anim_waiting;               /* 1: script is in a wait */
extern int  anim_steps;                 /* script steps run since anim_reset */
extern char far *anim_pc;               /* script pointer */
extern unsigned anim_script_seg;
extern int  anim_nsounds;
extern int  anim_sp;                    /* script stack depth */
extern int  anim_op;
extern int  anim_arg;                   /* operand / wait counter */
extern int  anim_vars[];                 /* script variables 0..50 */
extern int  anim_images[];              /* 250 sprite image handles */
extern long anim_next_tick;
extern int  anim_frame_ticks;
extern int  pan_has_palette;
extern int  pan_palette_type;
extern char pan_palette[];
extern int  pan_fd;
extern char *pan_name;
extern char pan_magic[];                /* read from the file */
extern int  pan_version;
extern int  anim_version;
extern int  pan_compressed;
extern int  pan_error;
extern char *stream_end;
extern char *stream_ptr;
extern int  pic_width, pic_height;
extern char pan_line_buf[];

/* An animation request (anim_play_file fills anim_req). */
struct anim_req {
    char *name;         /* +0 .pan file */
    int pad;            /* +2 */
    int active;         /* +4 value for anim_running */
    unsigned frames;    /* +6 frames to play, -1: until the script ends */
    int x, y;           /* +8 position, -1: the file's */
    int ticks;          /* +C timer ticks per frame, -1: the file's */
};

extern struct anim_req anim_req;
extern struct anim_req *anim_cur;       /* the request being played */
extern unsigned anim_frames_left;
extern unsigned anim_shown;             /* frames shown so far */
extern int  mouse_clicked;
extern int  last_key;

/* Initialized data, in DGROUP order. MSC holds these until the end of the
 * next function (anim_play_file), so the unreferenced "PANI" literal in that
 * function comes first in the object's _DATA. */
RastPort anim_view_rp = { 0, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort anim_back_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *anim_view = &anim_view_rp;
RastPort *anim_back = &anim_back_rp;
RastPort anim_rp0 = { 0, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort anim_rp1 = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort anim_rp2 = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *anim_page_c = &anim_rp0;
RastPort *anim_page_b = &anim_rp1;
RastPort *anim_page_a = &anim_rp2;
int  anim_running = 0;
int  anim_tick_phase = 1;
char pan_signature[] = "PANI";

anim_play_file(name, frames, x, y)
char *name;
int frames, x, y;
{
    int unused;

    "PANI";                 /* unreferenced literal, first in _DATA */
    anim_req.name = name;
    anim_req.frames = frames;
    anim_req.x = x;
    anim_req.y = y;
    anim_req.ticks = -1;
    anim_play(&anim_req);
}

set_scene_var(i, v)
int i, v;
{
    anim_vars[i] = v;
}

anim_play_sound(n)
int n;
{
    play_sound(n);
}

anim_should_abort()
{
    if ((drv_kbhit() && !((options & 0x10) && joystick_button(0)))
            || anim_shown < 3)
        return 0;
    if (!drv_kbhit) get_key();
    if (mouse_clicked) {
        mouse_clicked = 0;
        last_key = -1;
        return 0;
    }
    return 1;
}

anim_play(anim)
struct anim_req *anim;
{
    anim_start(anim);
    while (!anim_step())
        ;
    anim_stop();
}

/* Open the .pan, apply the request's overrides and reset the player. */
anim_start(req)
struct anim_req *req;
{
    anim_cur = req;
    anim_shown = 0;
    if (!pan_open(req->name))
        return 0;
    anim_set_active(anim_cur->active);
    anim_running = anim_cur->active;
    if (anim_cur->ticks != -1)
        anim_frame_ticks = anim_cur->ticks;
    if (anim_cur->x != -1)
        anim_view->x0 = anim_back->x0 = anim_cur->x;
    if (anim_cur->y != -1)
        anim_view->y0 = anim_back->y0 = anim_cur->y;
    if (anim_cur->frames != -1)
        anim_frames_left = anim_cur->frames * (anim_frame_ticks + 19) / anim_frame_ticks;
    else
        anim_frames_left = 0xffff;
    anim_set_palette();
    anim_reset();
    return 1;
}

anim_set_active(v)
int v;
{
    anim_running = v;
}

/* Stop: show the last frame, free the script and the sprite images (one
 * block, freed through the first image's segment). */
anim_stop()
{
    int i;

    anim_running = 0;
    if (drv_has_back_buffer(0) && anim_view->page == 0) {
        drv_copy_rect(anim_page_b, 0, 0, 320, 200, anim_page_c, 0, 0);
        gfx_show_page(anim_view->page);
        anim_view->page ^= 1;
    }
    _dos_freemem(anim_script_seg);
    for (i = 0; i < 250; i++)
        if (anim_images[i]) {
            _dos_freemem(anim_images[i]);
            break;
        }
}

/* One frame: 0 = running, 1 = finished, -1 = aborted. */
anim_step()
{
    int r;

    if (anim_should_abort())
        return -1;
    anim_shown++;
    anim_frame_delay();
    r = anim_advance(1);
    anim_frame_delay();
    if (--anim_frames_left == 0)
        r = 1;
    return r;
}

anim_reset()
{
    anim_reset_script();
    anim_clear_sprites();
    clear_dirty_rows();
    anim_present_mode = 2;
    anim_done = 0;
    anim_steps = anim_waiting = 0;
    anim_view->page = 1;
}

anim_advance(n)
int n;
{
    while (n--) {
        anim_clear_moved();
        if (anim_run_script())
            return 1;
        anim_update_sprites();
        anim_erase_sprites();
        anim_steps++;
    }
    anim_present_frame();
    anim_draw_sprites();
    anim_flush_sounds();
    gfx_show_page(anim_view->page);
    wait_retrace(1);
    if (drv_has_back_buffer(0))
        anim_view->page ^= 1;
    return 0;
}

anim_frame_delay()
{
    long now;

    if (anim_tick_phase) {
        _bios_timeofday(0, &anim_next_tick);
        anim_next_tick += anim_frame_ticks;
    } else {
        do ; while (_bios_timeofday(0, &now) == 0 && now < anim_next_tick);
    }
    anim_tick_phase ^= 1;
}

anim_set_palette()
{
    if (pan_has_palette) {
        pan_palette[0] = 0;
        anim_set_pal(pan_palette);
    }
}

/* Empty function (a bare RET, not called from anywhere). */
anim_unused_hook()
{
}

anim_present_frame()
{
    switch (anim_present_mode) {
    case 2:
        anim_present_mode--;
        drv_copy_rect(anim_page_a, 0, 0, anim_view->x1 + 1, anim_view->y1 + 1, anim_view, 0, 0);
        drv_copy_rect(anim_view, 0, 0, anim_view->x1 + 1, anim_view->y1 + 1, anim_back, 0, 0);
        break;
    case 1:
        anim_present_mode--;
        if (!drv_has_back_buffer(0)) {
    case 0:
            present_dirty_rows(anim_back->page, anim_view->page);
        } else {
            drv_copy_rect(anim_page_b, 0, 0, 320, 200, anim_page_c, 0, 0);
            drv_copy_rect(anim_back, 0, 0, anim_view->x1 + 1, anim_view->y1 + 1, anim_view, 0, 0);
        }
        break;
    default:
        break;
    }
}

anim_flush_sounds()
{
    if (anim_nsounds)
        while (anim_nsounds)
            anim_play_sound(anim_mem.sounds[--anim_nsounds]);
}

anim_reset_script()
{
    int unused;

    FP_SEG(anim_pc) = anim_script_seg;
    FP_OFF(anim_pc) = 0;
    anim_sp = anim_nsounds = 0;
}

anim_run_script()
{
    while (!anim_done) {
        switch (anim_waiting) {
        case 0:
            anim_op = *anim_pc;
            if (anim_op == 0) {         /* create sprite */
                if (anim_mem.stack[anim_sp - 6] == -1)
                    anim_mem.stack[anim_sp - 6] = anim_alloc_sprite();
                if (anim_mem.stack[anim_sp - 6] > 0 && anim_mem.stack[anim_sp - 6] <= 50)
                    anim_create_sprite(anim_mem.stack[anim_sp - 6], anim_mem.stack[anim_sp - 7],
                                       anim_mem.stack[anim_sp - 5], anim_mem.stack[anim_sp - 4],
                                       anim_mem.stack[anim_sp - 3], anim_mem.stack[anim_sp - 2],
                                       anim_mem.stack[anim_sp - 1]);
                anim_sp -= 7;
                anim_pc++;
            }
            if (anim_op == 1) {         /* kill sprite */
                if (anim_mem.stack[anim_sp - 1] > 0 && anim_mem.stack[anim_sp - 1] <= 50)
                    anim_mem.sprites[anim_mem.stack[anim_sp - 1] - 1].active = 0;
                anim_sp--;
                anim_pc++;
            }
            if (anim_op == 2) {         /* wait */
                anim_sp--;
                anim_arg = anim_mem.stack[anim_sp];
                anim_waiting = 1;
                anim_pc++;
            }
            if (anim_op == 3) {         /* sound */
                anim_sp--;
                anim_mem.sounds[anim_nsounds++] = anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 4) {         /* freeze sprite */
                if (anim_mem.stack[anim_sp - 1] > 0 && anim_mem.stack[anim_sp - 1] <= 50)
                    anim_mem.sprites[anim_mem.stack[anim_sp - 1] - 1].moved = 1;
                anim_sp--;
                anim_pc++;
            }
            if (anim_op == 5) {         /* push constant / variable */
                anim_arg = *(int far *)(anim_pc + 2);
                if (anim_pc[1])
                    anim_arg = anim_vars[anim_arg];
                anim_mem.stack[anim_sp++] = anim_arg;
                anim_pc += 4;
            }
            if (anim_op == 6) {         /* store variable */
                anim_sp--;
                anim_arg = *(int far *)(anim_pc + 1);
                if (anim_arg >= 0 && anim_arg < 51)
                    anim_vars[anim_arg] = anim_mem.stack[anim_sp];
                anim_pc += 3;
            }
            if (anim_op == 7) {         /* dup */
                anim_sp++;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 2];
                anim_pc++;
            }
            if (anim_op == 8) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] == anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 9) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] != anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 10) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] > anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 11) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] < anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 12) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] >= anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 13) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] = anim_mem.stack[anim_sp - 1] <= anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 14) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] += anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 15) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] -= anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 16) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] *= anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 17) {
                anim_sp--;
                anim_mem.stack[anim_sp - 1] /= anim_mem.stack[anim_sp];
                anim_pc++;
            }
            if (anim_op == 18) {        /* jump if zero */
                anim_sp--;
                if (anim_mem.stack[anim_sp] == 0)
                    anim_pc += 3;
                else
                    FP_OFF(anim_pc) = *(int far *)(anim_pc + 1);
            }
            if (anim_op == 19)          /* jump */
                FP_OFF(anim_pc) = *(int far *)(anim_pc + 1);
            if (anim_op == 20)          /* end of frame */
                return 0;
            if (anim_op == 21)          /* end */
                anim_done = 1;
            if (anim_op == 23) {        /* call */
                anim_mem.stack[anim_sp++] = FP_OFF(anim_pc) + 3;
                FP_OFF(anim_pc) = *(int far *)(anim_pc + 1);
            }
            if (anim_op == 22) {        /* return */
                anim_sp--;
                FP_OFF(anim_pc) = anim_mem.stack[anim_sp];
            }
            break;
        case 1:
            if (anim_arg--)
                return 0;
            anim_waiting = 0;
            break;
        }
    }
    return 1;
}

anim_alloc_sprite()
{
    int i;

    for (i = 1; i <= 50; i++)
        if (anim_mem.sprites[i - 1].active == 0)
            return i;
    return i - 1;
}

anim_clear_sprites()
{
    int i;

    for (i = 0; i < 50; i++)
        anim_mem.sprites[i].active = 0;
}

anim_create_sprite(n, start, parent, x0, y0, speed, flags)
int n, start, parent, x0, y0, speed, flags;
{
    struct sprite far *s;
    char far *ptr;

    s = &anim_mem.sprites[n] - 1;
    s->active = 1;
    s->moved = 0;
    s->parent = parent - 1;
    s->x0 = x0;
    s->y0 = y0;
    if (s->parent + 1 == -1) {
        s->x = s->x0;
        s->y = s->y0;
    } else {
        s->x = 0;
        s->y = 0;
    }
    s->rate = s->speed = speed;
    s->accum = 0xff;
    s->depth = 0;
    s->start = start;
    s->flags = flags;
    FP_OFF(ptr) = s->start;
    FP_SEG(ptr) = anim_script_seg;
    s->ptr = ptr;
}

anim_update_sprites()
{
    int i;

    for (i = 0; i < 50; i++)
        anim_update_sprite(i);
}

anim_erase_sprites()
{
    struct sprite far *s;
    int i;
    int x, y;

    for (i = 0; i < 50; i++) {
        if (anim_mem.sprites[i].active && anim_mem.sprites[i].moved) {
            s = &anim_mem.sprites[i];
            anim_sprite_pos(i, &x, &y);
            blit_sprite_restore(anim_back, x, y, anim_images[s->image]);
        }
    }
}

anim_draw_sprites()
{
    int i;

    for (i = 0; i < 50; i++)
        if (anim_mem.sprites[i].active)
            anim_draw_sprite(i);
}

anim_draw_sprite(n)
int n;
{
    struct sprite far *s;
    int x, y;

    s = &anim_mem.sprites[n];
    if (s->image != 0xff && !s->moved) {
        anim_sprite_pos(n, &x, &y);
        if (s->flags)
            drv_blit_sprite_var(anim_view, x, y, anim_images[s->image]);
        else
            blit_sprite(anim_view, x, y, anim_images[s->image]);
    }
}

anim_clear_moved()
{
    struct sprite far *s;
    int i;

    for (i = 0; i < 50; i++) {
        s = &anim_mem.sprites[i];
        if (s->active && s->moved)
            s->moved = 0;
    }
}

anim_sprite_pos(n, px, py)
int n, *px, *py;
{
    struct sprite far *s;

    s = &anim_mem.sprites[n];
    if (s->parent + 1 == -1) {
        *px = s->x;
        *py = s->y;
    } else {
        if (s->parent + 1 <= 0 && s->parent + 1 <= 50)
            return;
        if (!anim_mem.sprites[s->parent].active)
            return;
        *px = anim_mem.sprites[s->parent].x + s->x0 + s->x;
        *py = anim_mem.sprites[s->parent].y + s->y0 + s->y;
    }
}

anim_update_sprite(n)
int n;
{
    struct sprite far *s;
    char far *ptr;
    int x, y;
    int op;

    s = &anim_mem.sprites[n];
    if (!s->active)
        return;
    s->accum += s->rate;
    if (s->accum <= 0xff)
        return;
    s->accum -= 0xff;
    ptr = s->ptr;
    do {
        op = *s->ptr;
        if (op == 0) {              /* show image, end of step */
            s->image = s->ptr[1];
            s->ptr += 2;
            return;
        }
        if (op == 1) {              /* move to */
            s->x = *(int far *)(s->ptr + 1);
            s->y = *(int far *)(s->ptr + 3);
            s->ptr += 5;
        }
        if (op == 2) {              /* move by */
            s->x += *(int far *)(s->ptr + 1);
            s->y += *(int far *)(s->ptr + 3);
            s->ptr += 5;
        }
        if (op == 3) {              /* set rate */
            s->rate = *(int far *)(s->ptr + 1);
            s->ptr += 3;
        }
        if (op == 4) {              /* change rate */
            s->rate += *(int far *)(s->ptr + 1);
            s->ptr += 3;
        }
        if (op == 5) {              /* loop start */
            s->loops[s->depth++] = *(int far *)(s->ptr + 1);
            s->ptr += 3;
        }
        if (op == 6) {              /* loop end */
            if (--s->loops[s->depth - 1]) {
                FP_OFF(ptr) = *(int far *)(s->ptr + 1);
                s->ptr = ptr;
            } else {
                s->depth--;
                s->ptr += 3;
            }
        }
        if (op == 7) {              /* reset */
            if (s->parent + 1 == -1) {
                s->x = s->x0;
                s->y = s->y0;
            } else {
                s->x = 0;
                s->y = 0;
            }
            s->rate = s->speed;
            s->accum = 0xff;
        }
        if (op == 8 || op == 7) {   /* restart */
            s->depth = 0;
            FP_OFF(ptr) = s->start;
            s->ptr = ptr;
        }
        if (op == 9)                /* stop */
            return;
    } while (op != 10);
    s->active = 0;                  /* 10: remove */
}

set_border_from_palette(pal)
char *pal;
{
    int i;

    for (i = 0; i < 257; i++)
        if (memcmp(pal + 0x303, pal + i * 3, 3) == 0)
            break;
    set_border_color(i);
}

int86x_wrapper(pal)
char *pal;
{
    union REGS r;
    struct SREGS s;
    char far *fp;

    fp = (char far *)pal;
    r.h.ah = 0x10;
    r.h.al = 0x12;
    r.x.bx = 0;
    r.x.cx = 0x100;
    r.x.dx = FP_OFF(fp);
    s.es = FP_SEG(fp);
    int86x(0x10, &r, &r, &s);
}

set_border_color(color)
int color;
{
    union REGS r;

    r.h.ah = 0x10;
    r.h.al = 1;
    r.h.bh = color;
    int86(0x10, &r, &r);
}

bios_set_mode(mode)
int mode;
{
    union REGS r;

    r.h.ah = 0;
    r.h.al = mode;
    int86(0x10, &r, &r);
}
