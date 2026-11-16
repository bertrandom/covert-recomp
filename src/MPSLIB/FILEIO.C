/* FILEIO.C - MicroProse library: files, the resource catalog and picture loading.
 * Reconstructed for Microsoft C 5.1, K&R style.
 * Unlike the rest of the library this module was compiled with CL /AS /Gs /Ox
 * (/Oalt gives the same code): word-aligned functions, duplicated epilogues and
 * loop variables cached in SI/DI. With /Oas only 8 of its 22 functions match. */
#include "mps.h"

struct WORDREGS { unsigned ax, bx, cx, dx, si, di, cflag; };
struct BYTEREGS { unsigned char al, ah, bl, bh, cl, ch, dl, dh; };
union REGS { struct WORDREGS x; struct BYTEREGS h; };

#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))
#define FP_OFF(fp) (*((unsigned *)&(fp)))

/* A catalog entry: files packed into one big resource file. */
struct cat_entry {
    char name[12];
    char reserved[8];
    long offset;
};

/* Picture decoder (assembly segment, far) */
extern void far pic_begin_decode();
extern void far lzw_begin();
extern void far lzw_decode_row();
extern void far lzw_decode_row_b();
extern void far drv_put_row();
extern void far drv_begin_image();
extern void far drv_image_add_row();
extern int  far drv_end_image();

/* MS C runtime */
extern unsigned _dos_open();
extern unsigned _dos_creat();
extern unsigned _dos_close();
extern unsigned _dos_read();
extern unsigned _dos_write();
extern int  intdos();

extern int  far refill_from_far();
extern int  far refill_from_file();

/* Library globals */
extern char file_buf[];             /* 512-byte decoder buffer */
char *stream_end = file_buf + 512;  /* empty decoder buffer: forces a refill */
int  catalog_fd = -1;               /* -1: no catalog open */
extern char *stream_ptr;            /* decoder read pointer */
extern int  (far *refill_fn)();     /* decoder buffer refill callback */
extern int  stream_fd;
extern char far *stream_src;        /* decoding from memory */
extern int  pic_width, pic_height;
extern int  block_size;
extern char line_buf[];
extern int  errno;

open_resource(name, mode)
char *name;
int mode;
{
    int fd;
    struct cat_entry info;

    if (catalog_find(name, &info)) {
        if (dos_lseek(catalog_fd, info.offset))
            fatal_file_error(name);
        return catalog_fd;
    }
    if (_dos_open(name, mode, &fd))
        fatal_file_error(name);
    return fd;
}

create_file(name)
char *name;
{
    int fd;

    if (_dos_creat(name, 0, &fd))
        fatal_file_error(name);
    return fd;
}

close_resource(fd)
int fd;
{
    if (fd != catalog_fd)
        if (_dos_close(fd))
            fatal_file_error(0);
}

read_file(name, buf)
char *name;
char *buf;
{
    unsigned nbytes;
    int fd;

    fd = open_resource(name, 0);
    if (_dos_read(fd, (char far *)buf, 0xFFFF, &nbytes))
        fatal_file_error(0);
    close_resource(fd);
    return nbytes;
}

read_file_far(name, buf)
char *name;
char far *buf;
{
    unsigned nbytes;
    int fd;

    fd = open_resource(name, 0);
    if (_dos_read(fd, buf, 0xFFFF, &nbytes))
        fatal_file_error(0);
    close_resource(fd);
    return nbytes;
}

write_file(name, buf, len)
char *name;
char far *buf;
unsigned len;
{
    int fd;

    fd = create_file(name);
    if (_dos_write(fd, buf, len, &len))
        fatal_file_error(0);
    close_resource(fd);
    return len;
}

load_picture(page, name)
int page;
char *name;
{
    int y;
    int fd;

    fd = open_resource(name, 0);
    set_decoder_input(fd);
    pic_begin_decode();
    for (y = 0; y < pic_height; y++) {
        lzw_decode_row(line_buf);
        drv_put_row(line_buf, page, y, 0, pic_width);
    }
    close_resource(fd);
}

load_compressed_block(dst, name)
char far *dst;
char *name;
{
    int fd;

    fd = open_resource(name, 0);
    set_decoder_input(fd);
    lzw_begin();
    lzw_decode_row_b(dst, block_size);
    close_resource(fd);
    return block_size;
}

load_image_offscreen(name)
char *name;
{
    int y;
    int fd;

    fd = open_resource(name, 0);
    set_decoder_input(fd);
    pic_begin_decode();
    drv_begin_image(pic_width, pic_height);
    for (y = 0; y < pic_height; y++) {
        lzw_decode_row(line_buf);
        drv_image_add_row(line_buf);
    }
    close_resource(fd);
    return drv_end_image();
}

load_picture_swapped(name, page)
char *name;
int page;
{
    load_picture(page, name);
}

load_picture_to_buffer(name, page)
char *name;
int page;
{
    int y;
    int fd;

    fd = open_resource(name, 0);
    set_decoder_input(fd);
    pic_begin_decode();
    for (y = 0; y < pic_height; y++) {
        lzw_decode_row(line_buf);
        drv_put_row(line_buf, page, y, 0, pic_width);
    }
}

decode_picture_from_memory(seg, page)
unsigned seg;
int page;
{
    int y;

    FP_OFF(stream_src) = 0;
    FP_SEG(stream_src) = seg;
    stream_ptr = stream_end;
    refill_fn = refill_from_far;
    pic_begin_decode();
    for (y = 0; y < pic_height; y++) {
        lzw_decode_row(line_buf);
        drv_put_row(line_buf, page, y, 0, pic_width);
    }
}

set_decoder_input(fd)
int fd;
{
    stream_fd = fd;
    stream_ptr = stream_end;
    refill_fn = refill_from_file;
}

int far refill_from_far()
{
    char far *p;

    p = (char far *)file_buf;
    movedata(FP_SEG(stream_src), FP_OFF(stream_src), FP_SEG(p), FP_OFF(p), 0x200);
    stream_ptr = file_buf;
    FP_OFF(stream_src) += 0x200;
    return 0x200;
}

stream_set_file(fd)
int fd;
{
    stream_fd = fd;
    refill_from_file();
}

int far refill_from_file()
{
    unsigned n;

    _dos_read(stream_fd, (char far *)file_buf, 0x200, &n);
    stream_ptr = file_buf;
    return n;
}

fatal_file_error(name)
char *name;
{
    set_video_mode(3);
    perror(name);
    exit(99);
}

set_video_mode(mode)
int mode;
{
    union REGS r;
    int saved;

    saved = errno;
    r.h.ah = 0;
    r.h.al = mode;
    int86(0x10, &r, &r);
    errno = saved;
}

open_catalog(name)
char *name;
{
    int fd;

    if (_dos_open(name, 0x8000, &fd))
        return 0;
    catalog_fd = fd;
    return 1;
}

close_catalog()
{
    if (catalog_fd != -1) {
        if (_dos_close(catalog_fd))
            fatal_file_error(0);
        catalog_fd = -1;
    }
}

catalog_find(name, entry)
char *name;
struct cat_entry *entry;
{
    unsigned nbytes;
    int count;

    if (catalog_fd == -1)
        return 0;
    if (dos_lseek(catalog_fd, 0L))
        fatal_file_error(0);
    if (_dos_read(catalog_fd, (char far *)&count, 2, &nbytes))
        fatal_file_error(0);
    while (count--) {
        if (_dos_read(catalog_fd, (char far *)entry, 0x18, &nbytes))
            fatal_file_error(0);
        if (!strnicmp(entry, name, 12))
            return 1;
    }
    return 0;
}

dos_lseek(fd, pos)
int fd;
long pos;
{
    union REGS r;

    r.x.ax = 0x4200;
    r.x.bx = fd;
    r.x.cx = pos >> 16;
    r.x.dx = pos;
    intdos(&r, &r);
    if (r.x.cflag == 0)
        return 0;
    return r.x.ax;
}
