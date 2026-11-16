/* DISK.C - MicroProse library: make sure the right game disk is in the drive. */
#include "mps.h"

extern int cur_disk;                /* defined by each program: the disk it lives on */
extern char message[];
extern int menu_flag;

char *disk_files[] = { "final.exe", "game.exe", "tac.exe", "hq.pan" };  /* probed for disks 1-4 */
char disk_letter[] = "A";

require_disk(disk, prompt)
int disk, prompt;
{
    if (!prompt) {
        if (probe_drive(disk_files[disk - 1], 0) != -1) return 1;
        require_disk(cur_disk, 1L);
        return 0;
    } else
        while (probe_drive(disk_files[disk - 1], 0) == -1 || prompt == -1) {
            gfx_show_page(g_gfx->page);
            if (prompt == -1) prompt = 1;
            gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
            disk_letter[0] = disk + '@';
            strcpy(message, "Please insert Disk ");
            strcat(message, disk_letter);
            if (disk >= 3) {
                strcat(message, "\n(if 3.5\" insert Disk ");
                disk_letter[0] -= 2;
                strcat(message, disk_letter);
                strcat(message, ")");
            }
            strcat(message, ".\n \n     Press Return\n     to continue.\n");
            menu_flag = 1;
            text_window(message, 100, 80);
            gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
        }
    return prompt;
}
