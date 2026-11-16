/* LOADGAME.C - FINAL: load and save game menus (cv0-cv3.sve), save file
 * listing, drive selection and the floppy-ready check. */
#include "final.h"

struct diskinfo {                   /* _bios_disk request (bios.h) */
    unsigned drive, head, track, sector, nsectors;
    char far *buffer;
};

char save_name[] = "a:cv0.sve";

load_game_menu()
{
    unsigned i;
    int drv, n;

    save_loading = 1;
    drv = select_drive();
    if (drv != -1) {
        strcpy(text_buf, "Select Load File...\n");
        save_mask = 0;
        for (i = 0; i < 4; i++) {
            save_name[4] = i + '0';
            if (list_save_files(save_name, 1L))
                save_mask |= 1 << i;
        }
        if ((save_slot = show_menu(text_buf, 4, 16)) >= 0)
            save_slot /= 3;
        if (!(save_mask & (1 << save_slot)))
            save_slot = -1;
        if (save_slot != -1) {
            save_name[4] = save_slot + '0';
            if (!list_save_files(save_name, 0L))
                save_slot = -1;
        }
        require_disk(1, 1L);
        return save_slot;
    }
    return -1;
}

list_save_files(name, list)
char *name;
int list;
{
    strcpy(name + 6, "sve");
    if (list) {
        save_fd = open(name, 0x8000);
        if (save_fd != -1) {
            lseek(save_fd, 1008L, 0);
            read(save_fd, save_header, 0x28E);
            lseek(save_fd, 42L, 0);
            read(save_fd, &save_level, 2);
            strcat(text_buf, " Max '");
            strcat(text_buf, save_codename);
            strcat(text_buf, "' Remington: 00");
            strcat(text_buf, itoa(save_rank, save_num_buf, 10));
            strcat(text_buf, " rank\n ... ");
            strcat(text_buf, save_where);
            strcat(text_buf, ": ");
            strcat(text_buf, month_names[save_month % 12]);
            strcat(text_buf, " ");
            strcat(text_buf, itoa(save_time / 1440 + 1, save_num_buf, 10));
            strcat(text_buf, ", ");
            strcat(text_buf, itoa(save_month / 12 + 1990, save_num_buf, 10));
            switch (save_level) {
            case 0:
                strcat(text_buf, " (Local)");
                break;
            case 1:
                strcat(text_buf, " (National)");
                break;
            case 2:
                strcat(text_buf, " (Regional)");
                break;
            case 3:
                strcat(text_buf, " (Global)");
                break;
            }
            strcat(text_buf, ".\n \n");
        } else
            strcat(text_buf, " (EMPTY)\n \n \n");
        close(save_fd);
        if (save_fd != -1)
            return 1;
        return 0;
    }
    load_env(name);
    options &= ~0x80;
    return 1;
}

save_game_menu()
{
    int i, drv, item;

    save_loading = save_error = 0;
    drv = select_drive();
    if (drv != -1) {
        strcpy(text_buf, "Select Save File...\n");
        for (i = 0; i < 4; i++) {
            save_name[4] = i + '0';
            list_save_files(save_name, 1L);
        }
        default_sel = save_slot;
        if ((item = show_menu(text_buf, 4, 16)) >= 0)
            item /= 3;
        if (item != -1) {
            install_int24_handler();
            save_slot = item;
            save_name[4] = item + '0';
            if (write_save_file(save_name)) {
                strcpy(text_buf, save_error == 0L ? "Game has been saved.\n" : "Game NOT saved.\n");
                if (save_error == 13)
                    strcat(text_buf, "Write access denied.\n");
                if (save_error == 28)
                    strcat(text_buf, "Disk Full.\n");
                strcat(text_buf, "Press key to continue.\n");
                show_menu(text_buf, 4, 128);
            }
            restore_int24_handler();
        }
    }
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
    require_disk(cur_disk, 1L);
}

write_save_file(name)
char *name;
{
    int pad[4];

    strcpy(name + 6, "sve");
    save_fd = open(name, 0x8301, 0x80);
    if (save_fd == -1) {
        strcpy(text_buf, "File Error: ");
        strcat(text_buf, name);
        strcat(text_buf, "\n");
        show_menu(text_buf, 100, 80);
        return 0;
    }
    close(save_fd);
    dossier_state = 1;
    strcpy(text_buf, name);
    strcat(text_buf, "\n ... save in progress.\n");
    show_menu(text_buf, 4, 100);
    save_env(name);
    return 1;
}

write_checked(fd, buf, n)
int fd;
char *buf;
unsigned n;
{
    if (write(fd, buf, n) == -1)
        save_error = errno;
}

select_drive()
{
    int key;
    int drive;
    int m, n;

    _dos_getdrive(&drive);
    drive--;
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
    do {
        strcpy(text_buf, save_loading
               ? "Which drive contains your\nsaved game files?\n\n           \217 "
               : "Which drive contains your\nSave Game disk?\n\n           \217 ");
        text_buf[strlen(text_buf) - 1] = drive + 'A';
        strcat(text_buf, ":\n\n    Press drive letter and\nReturn when disk is inserted.\n");
        strcat(text_buf, "    Press Escape to cancel.\n");
        dossier_state = 1;
        show_menu(text_buf, 80, 80);
        key = get_key();
        if (key == 'A' || key == 'a')
            drive = 0;
        if (key == 'B' || key == 'b')
            drive = 1;
        if (key == 'C' || key == 'c')
            drive = 2;
        if (key == 'D' || key == 'd')
            drive = 3;
        if (key == 27)
            drive = -1;
    } while (key != 13 && key != 27);
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
    if (drive != -1 && !check_drive_ready(drive)) {
        strcpy(text_buf, "No Disk in Drive A.\n");
        text_buf[strlen(text_buf) - 3] = drive + 'A';
        show_menu(text_buf, 100, 80);
        return -1;
    }
    save_name[0] = drive + 'a';
    return drive;
}

check_drive_ready(drive)
int drive;
{
    struct diskinfo di;
    int ret;
    int tries;

    if (drive > 1)
        return 1;
    di.drive = drive;
    di.head = 0;
    di.track = 0;
    di.sector = 2;
    di.nsectors = 1;
    for (tries = 0; tries < 3; tries++) {
        ret = _bios_disk(4, &di);
        if (!(ret & 0xFF00))
            return 1;
        _bios_disk(0, 0);
    }
    return 0;
}
