/* CODE.C - Covert Action cryptography workstation (CODE.EXE).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "code.h"

extern char colormap[];
extern char letter[];

int cur_disk = 2;                   /* disk this program lives on (library's require_disk) */
RastPort back_rp = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *back_page = &back_rp;
char nullstr[] = "";

main()
{
    ENV[0] = 0xFF;
    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    drv_slot36(0);
    drv_set_color_map(colormap, colormap);
    difficulty = clamp(*(int far *)(ENV + 0x3A) - ((*(int far *)(ENV + 0x4E) >> 4) & 3) + 1, -3, 5);
    options = *(unsigned far *)(ENV + 0x24);
    env44 = *(int far *)(ENV + 0x44);
    g_gfx->font = 1; g_gfx->fillcolor = 15;
    randomize();
    make_cipher();
    draw_workstation();
    do {
        workstation_input();
    } while (!done);
    ENV[9] = result;
    ENV[15] = elapsed;
    ENV[0] = (options & 0x20) ? 0x11 : 0;
    set_exit_state(0, 0);
    g_gfx->font = 1;
    require_disk((options & 0x20) ? 1 : 2, 1L);
}

set_exit_state(flag)
int flag;
{
    if (flag) ENV[0] = 0xFF;
}

play_sound(n)
int n;
{
    if (options & 4) drv_play_sound(n);
}

bios_set_page(page)
int page;
{
    bios_regs.h.ah = 5; bios_regs.h.al = page;
    int86(0x10, &bios_regs, &bios_regs);
}

stub0()
{
}

draw_status_bar()
{
}

draw_face_parts()
{
}

char key[30] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\";
char plain[30] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\";
char guess[32] = "                             ";

make_cipher()
{
    int c, i, j;
    char buf[1024];

    nletters = 26;
    for (i = 0; i < nletters; i++) {
        j = random(nletters);
        c = key[i]; key[i] = key[j]; key[j] = c;
        revealed[i] = 0;
    }
    strcpy(message, nullstr);
    for (i = 0; i < 512; i++) message[i] = ENV[i + 0x200];
    for (i = 0; i < strlen(message); i++) {
        if (message[i] == ' ' && difficulty > 2) {
            strcpy(buf, message + i + 1); strcpy(message + i, buf);
        }
        if (message[i] == '.' && (difficulty == 1 || difficulty == 2)) {
            strcpy(buf, message + i + 1); strcpy(message + i, buf);
        }
    }
    message[strlen(message) - 1] = 0;
    strupr(message);
}

draw_workstation()
{
    int ch, k, cur, i, row, hold, nx, max, cnt;
    char tmp[40];

    fill_rect_xy(0, 0, 320, 200, 0);
    fill_rect_xy(34, 0, 320, 8, 10);
    draw_line(1, 0, 31, 0, 2);
    draw_line(1, 199, 31, 199, 2);
    draw_line(0, 1, 0, 198, 2);
    draw_line(32, 1, 32, 198, 2);
    gfx_fill_rect(g_gfx, 2, 2, 29, 4, 2);
    gfx_fill_rect(g_gfx, 2, 194, 29, 4, 2);
    g_gfx->font = 2;
    strcpy(tmp, "CRYPTO WORKSTATION, Msg:#M173");
    tmp[26] = (message[13] & 7) + '0'; tmp[27] = (message[21] & 7) + '1'; tmp[28] = (message[7] & 7) + '2';
    draw_text_transparent(tmp, 64, 1, 0);
    nx = row = 0;
    g_gfx->font = 3;
    for (i = 0; i < strlen(message); i++) {
        ch = message[i];
        if (ch >= 'A' && ch <= 'Z') {
            ch = key[ch - 'A']; count[ch - 'A']++;
        }
    }
    cnt = 0;
    if (difficulty == 2 || difficulty > 3) {
        cnt = 1;
        for (i = 0; i < nletters; i++) {
            if (count[i] == 0) {
                max = 0;
                for (k = 0; k < nletters; k++) {
                    if (count[k] > max) {
                        hold = k; max = count[k];
                    }
                }
                for (k = 0; k < nletters; k++) {
                    if (key[k] == hold + 'A') {
                        ch = plain[k]; break;
                    }
                }
                for (k = 0; k < nletters; k++) {
                    if (key[k] == i + 'A') {
                        cur = k; break;
                    }
                }
                for (k = 0; k < strlen(message); k++) {
                    if (message[k] == ch && (k & 1)) {
                        message[k] = cur + 'A';
                        count[i]++; count[hold]--;
                        plain[cur] = ch;
                        cnt = 0;
                    }
                }
            }
        }
    }
    for (i = 0; i < 10; i++) tmp[i] = message[i];
    max = 0;
    for (i = 0; i < nletters; i++) {
        g_gfx->font = 3; letter[0] = i + 'A';
        draw_text_transparent(letter, 12, i * 7 + 9, 10);
        g_gfx->font = 2;
        draw_text_transparent("0", 20, i * 7 + 9, 10);
        if (count[i] > max) {
            max = count[i]; hold = i;
        }
        count[i] = 0;
    }
    if (strlen(message) > 462) hyphenate = 0;
    for (i = 0; i < strlen(message); i++) {
        ch = message[i];
        if (ch >= 'A' && ch <= '\\') {
            ch = key[ch - 'A'];
            g_gfx->font = 2;
            gfx_fill_rect(g_gfx, 20, ch * 7 - 446, 12, 7, 0);
            strcpy(message, "");
            strcat(message, itoa(++count[ch - 'A'], numbuf, 10));
            draw_text_transparent(message, 20, ch * 7 - 446, 10);
            for (k = 0; k < 10; k++) message[k] = tmp[k];
        }
        letter[0] = ch; g_gfx->font = 3;
        draw_text_transparent(letter, nx * 6 + 44, row * 16 + 16, 10);
        if (++nx >= 42) {
            if (message[i] >= 'A' && message[i] <= 'Z' && message[i + 1] >= 'A' && message[i + 1] <= 'Z') draw_text_transparent("-", nx * 6 + 44, row * 16 + 16, 10);
            nx = 0; row++;
        }
        wait_retrace(2);
    }
    for (i = 0; i < 10; i++) message[i] = tmp[i];
    if (difficulty <= 0) {
        for (i = 0; i < nletters; i++) {
            if (key[i] == hold + 'A') {
                guess[hold] = i + 'A'; revealed[hold] = 1;
            }
        }
        for (k = difficulty; k < 0; k++) computer_assist();
        draw_message();
    }
}

char letter[2] = "x";

computer_assist()
{
    int i, tries, n;

    tries = 0;
    do {
        do n = random(nletters); while (count[n] == 0);
    } while (guess[n] != ' ' && ++tries < 999);
    for (i = 0; i < nletters; i++) {
        if (key[i] == n + 'A') { guess[n] = plain[i]; revealed[n] = 1; }
    }
}

refresh_guesses()
{
    int i, j;

    for (i = 0; i < nletters; i++) {
        if (revealed[i])
            for (j = 0; j < nletters; j++) { if (key[j] == i + 'A') guess[i] = plain[j]; }
        else guess[i] = ' ';
    }
}

scramble_effect()
{
    int ix, pos, iy, c, i;

    play_sound(46); g_gfx->font = 3; i = 0;
    do {
        pos = random(strlen(message)); c = message[pos];
        if (c >= 'A' && c <= 'Z') c = key[c - 'A'];
        letter[0] = c;
        ix = pos % 42; iy = pos / 42;
        gfx_fill_rect(g_gfx, ix * 6 + 44, iy * 16 + 16, 6, 6, 0);
        wait_retrace(2);
        draw_text_transparent(letter, ix * 6 + 44, iy * 16 + 16, 10);
    } while (++i < 200);
    g_gfx->font = 2;
}

blink_selected_letter(n)
int n;
{
    letter[0] = n + 'A';
    do {
        ticks++;
        draw_clock(ticks);
        g_gfx->font = 3;
        g_gfx->fillcolor = 14;
        gfx_fill_rect(g_gfx, 12, n * 7 + 9, 6, 6, 0);
        wait_retrace(5);
        draw_text_transparent(letter, 12, n * 7 + 9, 10);
        g_gfx->font = 2;
        wait_retrace(5);
    } while (!kbhit());
}

workstation_input()
{
    int ltr, i, j, k;

    for (;;) {
        do {
            wait_retrace(10);
            ticks++;
            draw_clock(ticks);
        } while (!kbhit());
        k = get_key();
        ltr = k - 'a';
        switch (k) {
        case 0x1B:                                  /* Esc */
            done = 1;
            return;
        case 0x3B00:                                /* F1: computer assistance */
            scramble_effect();
            computer_assist();
            draw_message();
            ticks += 3600;
            break;
        case 0x4400:                                /* F10: erase all guesses */
            refresh_guesses();
            draw_message();
            return;
        case 0x1000:                                /* Alt-Q */
            drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
            if (text_window("Are you sure\nyou want to Quit?\n No\n Yes\n", 80, 80) == 1) {
                set_exit_state(1L);
                exit();
            }
            drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
            break;
        case 0x1F00:                                /* Alt-S: sound on/off */
            options ^= 4;
            break;
        case 0x1900:                                /* Alt-P: pause */
            drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
            gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
            paused = 1;
            text_window("PAUSED\n", 128, 81);
            get_key();
            drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
            break;
        default:
            if (ltr < 0 || ltr >= nletters)
                continue;
            blink_selected_letter(ltr);
            j = get_key();
            if ((j -= 'a') < 0 || j >= nletters)
                guess[ltr] = ' ';
            else
                guess[ltr] = j + 'A';
            play_sound(45);
            draw_message();
            break;
        }
        if (check_decoded()) {
            done = 1;
            result = 1;
            for (i = 0; i < nletters; i++) {
                k = key[i] - 'A';
                guess[k] = plain[i];
            }
            play_sound(46);
            draw_message();
            text_window("MESSAGE DECODED\n", 100, 2);
        }
        return;
    }
}

draw_message()
{
    int ix, iy, y, i, ch;

    g_gfx->fillcolor = 0;
    for (i = 0; i < nletters; i++) {
        letter[0] = guess[i];
        draw_text(letter, 4, i * 7 + 9, 11);
    }
    ix = iy = 0;
    g_gfx->fillcolor = 0;
    for (i = 0; i < strlen(message); i++) {
        ch = message[i];
        if (ch >= 'A' && ch <= '\\')
            ch = key[ch - 'A'];
        letter[0] = ch;
        g_gfx->font = 3;
        gfx_fill_rect(g_gfx, ix * 6 + 44, iy * 16 + 16, 6, 7, 0);
        wait_retrace(0);
        draw_text_transparent(letter, ix * 6 + 44, iy * 16 + 16, 10);
        g_gfx->font = 2;
        if (message[i] >= 'A' && message[i] <= '\\') {
            ch = guess[ch - 'A'];
            letter[0] = ch;
        }
        draw_text(letter, ix * 6 + 44, iy * 16 + 23, 11);
        if (++ix >= 42) {
            ix = 0;
            iy++;
        }
    }
}

check_decoded()
{
    int unused, i, good, k, wrong, n;

    good = wrong = unused = 0;
    for (i = 0; i < nletters; i++) {
        k = key[i] - 'A';
        if (guess[k] != ' ' && count[k] > 0) {
            if (guess[k] == plain[i])
                good++;
            else
                wrong++;
        }
        if (count[k] == 0)
            unused++;
    }
    if (unused / 2 + good > 19 && !wrong)
        return 1;
    return 0;
}
