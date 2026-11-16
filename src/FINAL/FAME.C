/* FAME.C - FINAL.EXE: the Hall of Fame (fame.dta).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "final.h"

clear_hall_of_fame()
{
    int i, spare;

    for (i = 0; i < 6; i++)
        hall_of_fame[i].score = -1;
}

load_hall_of_fame()
{
    int fd;

    clear_hall_of_fame();
    if (access("fame.dta", 4) != -1) {
        fd = open("fame.dta", 0x8102, 0x80);
        read(fd, hall_of_fame, 6 * sizeof(struct Fame));
        close(fd);
    }
}

save_hall_of_fame()
{
    int fd;

    if (access("fame.dta", 2) != -1) {
        fd = open("fame.dta", 0x8302, 0x80);
        write(fd, hall_of_fame, 6 * sizeof(struct Fame));
        close(fd);
    }
}

/* Show the Hall of Fame with entry `sel` highlighted (-1: none, and keys 1-5
 * show that agent's vacation snapshot).  Returns 1 if the player cleared it. */
show_hall_of_fame(sel)
int sel;
{
    int crime, x, key, i, y, score, m;
    unsigned scores[6];

    for (;;) {
        draw_page_frame("Hall of Fame", 1);
        g_gfx->fillcolor = 15;
        draw_text_centered("COVERT ACTION", 160, 16, 0);
        draw_text_centered("HALL OF FAME", 160, 24, 0);
        draw_line(80, 32, 240, 32, 14);
        y = 40;
        for (i = 0; i < 6; i++) {
            if (i != sel && i == 5)
                break;
            if (sel == 5 && i == 4)
                continue;
            x = random(8) + 12;
            draw_card_panel(x - 8, y - 4);
            scores[i] = hall_of_fame[i].score;
            if (hall_of_fame[i].difficulty & 0x80)
                scores[i] |= 0x8000;
            if (hall_of_fame[i].score == -1) {
                strcpy(text_buf, " ---");
                draw_text(text_buf, x, y, 0);
                y += 26;
                continue;
            }
            text_buf[0] = 0;
            strcat(text_buf, itoa(i + 1, num_str, 10));
            strcat(text_buf, ". ");
            strcat(text_buf, "Max '");
            strcat(text_buf, hall_of_fame[i].name);
            strcat(text_buf, "' Remington,  Case #");
            m = hall_of_fame[i].month;
            strcat(text_buf, itoa(m + 1, num_str, 10));
            strcat(text_buf, " ");
            strcat(text_buf, month_names[m % 12]);
            strcat(text_buf, " ");
            strcat(text_buf, itoa(m / 12 + 1990, num_str, 10));
            draw_text(text_buf, x, y, 0);
            y += 8;
            crime = plot_defs[hall_of_fame[i].plot].crime[hall_of_fame[i].episode];
            strcpy(text_buf, crime_names[crime]);
            strcat(text_buf, "/");
            strcat(text_buf, plot_defs[hall_of_fame[i].plot].roles[hall_of_fame[i].episode][0]);
            draw_text(text_buf, x, y, 9);
            y += 8;
            strcpy(text_buf, "EP: ");
            strcat(text_buf, itoa(hall_of_fame[i].points, num_str, 10));
            strcat(text_buf, "    \x80--- SCORE: ");
            strcat(text_buf, itoa(hall_of_fame[i].score, num_str, 10));
            strcat(text_buf, " ---");
            draw_text(text_buf, x, y, 7);
            y += 14;
            if (i == sel)
                drv_recolor_rect(g_gfx, x - 4, y - 32, 296, 26, 15, 14);
        }
        if (sel != -1) {
            draw_text("C\x83lear", 252, 189, 0);
            draw_rect_outline(236, 187, 60, 10, 11);
        }
        key = wait_key_or_button();
        if (sel != -1 && (key == 'c' || key == 'C'))
            return 1;
        if (sel == -1 && key >= '1' && key <= '5') {
            score = scores[key - '1'];
            options &= ~2;
            if (score & 0x8000)
                options |= 2;
            vacation_snapshot(clamp((score & 0x7fff) / 150, 0, 20), 0, 0);
            wait_key_or_button();
            play_sound(1);
            require_disk(1, 1L);
        } else
            break;
    }
    return 0;
}

hall_of_fame_insert(points)
int points;
{
    int unused, i, k, score2;

    unused = 0;
    score2 = points * (difficulty + 1);
again:
    for (i = 0; i < 6; i++) {
        if (hall_of_fame[i].score < score2 || i == 5) {
            for (k = 5; k > i; k--)
                memcpy(&hall_of_fame[k], &hall_of_fame[k - 1], sizeof(struct Fame));
            hall_of_fame[i].score = score2;
            strcpy(hall_of_fame[i].name, codename);
            hall_of_fame[i].difficulty = difficulty;
            if (options & 2)
                hall_of_fame[i].difficulty |= 0x80;
            hall_of_fame[i].plot = plot_num;
            hall_of_fame[i].episode = last_episode;
            hall_of_fame[i].points = points;
            hall_of_fame[i].month = cur_month;
            if (show_hall_of_fame(i)) {
                clear_hall_of_fame();
                goto again;
            }
            return i;
        }
    }
    return -1;
}
