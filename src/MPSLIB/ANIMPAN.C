/* ANIMPAN.C - MicroProse library: the .PAN animation file loader.
 * The second object of the animation player (ANIMOBJ.C is the first): the
 * original's code records break inside decode_sprite, which only happens if
 * a new object starts at pan_open (0x3B0 bytes before the break).
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "mps.h"

#define FP_OFF(fp) (*((unsigned *)&(fp)))
#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))

/* Graphics driver / assembly segment (far) */
extern int  far drv_mem_avail();
extern void far drv_clear_page();
extern int  far drv_begin_image_grab();
extern void far drv_end_image_grab();
extern void far drv_put_row();
extern void far drv_begin_image();
extern int  far drv_image_add_row();
extern int  far drv_end_image();
extern void far pic_begin_decode();
extern void far lzw_decode_row();

/* C runtime */
extern int  strcmp();
extern unsigned _dos_allocmem();

/* Library globals */
extern RastPort *anim_view;
extern RastPort *anim_back;
extern char pan_signature[];            /* "PANI" (ANIMOBJ.C) */
extern unsigned anim_script_seg;
extern int  anim_images[];              /* 250 sprite image handles */
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

pan_open(name)
char *name;
{
    int a, b;

    pan_fd = open_resource(name, 0x8000);
    set_decoder_input(pan_fd);
    if (!pan_check_header(name)) {
        close_resource(pan_fd);
        return 0;
    }
    pan_read_palette();
    pan_read_header();
    pan_read_background();
    if (!pan_load_sprites()) {
        close_resource(pan_fd);
        return 0;
    }
    if (!pan_load_script()) {
        close_resource(pan_fd);
        return 0;
    }
    close_resource(pan_fd);
    return 1;
}

pan_check_header(name)
char *name;
{
    pan_name = name;
    pan_magic[0] = stream_getc();
    pan_magic[1] = stream_getc();
    pan_magic[2] = stream_getc();
    pan_magic[3] = stream_getc();
    pan_magic[4] = 0;
    pan_version = stream_getc();
    pan_compressed = stream_getc();
    if (strcmp(pan_signature, pan_magic)) {
        pan_error = 1;
        return 0;
    }
    if (pan_version != anim_version) {
        pan_error = 2;
        return 0;
    }
    return 1;
}

pan_read_palette()
{
    stream_read(&pan_has_palette, 1, 1);
    if (pan_has_palette) {
        stream_read(&pan_palette_type, 1, 1);
        switch (pan_palette_type) {
        case 0:
            stream_read(pan_palette, 0x11, 1);
            break;
        case 1:
            break;
        case 2:
            stream_read(pan_palette, 0x306, 1);
            break;
        }
    }
}

pan_read_header()
{
    anim_view->page = 1;
    stream_read(&anim_view->x0, 2, 1);
    stream_read(&anim_view->y0, 2, 1);
    stream_read(&anim_view->x1, 2, 1);
    stream_read(&anim_view->y1, 2, 1);
    stream_read(&anim_frame_ticks, 2, 1);
    *anim_back = *anim_view;
    anim_back->page = 2;
}

pan_read_background()
{
    int type;
    int color;

    switch (type = stream_getc()) {
    case 0:
        break;
    case 1:
        decode_picture(anim_back->page);
        break;
    case 2:
        stream_read(&color, 2, 1);
        drv_clear_page(anim_back->page, color);
        break;
    }
}

pan_load_sprites()
{
    int ok;
    int img;
    int n;

    ok = 1;
    stream_read(anim_images, 2, 250);
    if (!drv_begin_image_grab())
        return 0;
    for (n = 0; n < 250; n++) {
        if (anim_images[n] && !(anim_images[n] = decode_sprite())) {
            pan_error = 0;
            ok = 0;
            break;
        }
    }
    drv_end_image_grab();
    return ok;
}

pan_load_script()
{
    char far *p;
    unsigned nbytes;
    unsigned paras;
    unsigned i;
    unsigned avail;

    stream_read(&paras, 2, 1);
    avail = drv_mem_avail();
    if (avail < paras) {
        pan_error = 0;
        return 0;
    }
    _dos_allocmem(paras, &anim_script_seg);
    FP_SEG(p) = anim_script_seg;
    FP_OFF(p) = 0;
    nbytes = paras << 4;
    for (i = 0; i < nbytes; i++)
        *p++ = stream_getc();
}

decode_picture(page)
int page;
{
    int y;

    if ((stream_end - stream_ptr) & 1)
        stream_getc();
    if (pan_compressed)
        pic_begin_decode();
    else
        read_picture_header();
    for (y = 0; y < pic_height; y++) {
        if (pan_compressed)
            lzw_decode_row(pan_line_buf);
        else
            stream_read(pan_line_buf, 1, pic_width);
        drv_put_row(pan_line_buf, page, y, 0, pic_width);
    }
}

decode_sprite()
{
    int y;

    if ((stream_end - stream_ptr) & 1)
        stream_getc();
    if (pan_compressed)
        pic_begin_decode();
    else
        read_picture_header();
    drv_begin_image(pic_width, pic_height);
    for (y = 0; y < pic_height; y++) {
        if (pan_compressed)
            lzw_decode_row(pan_line_buf);
        else
            stream_read(pan_line_buf, 1, pic_width);
        if (!drv_image_add_row(pan_line_buf))
            return 0;
    }
    return drv_end_image();
}

read_picture_header()
{
    int skip;

    stream_read(&skip, 1, 2);
    stream_read(&pic_width, 1, 2);
    stream_read(&pic_height, 1, 2);
}

stream_read(buf, size, count)
char *buf;
int size, count;
{
    size = count * size;
    while (size--)
        *buf++ = stream_getc();
}

stream_getc()
{
    if (stream_ptr >= stream_end)
        stream_set_file(pan_fd);
    return *stream_ptr++;
}
