/* CHRONO.C - Covert Action strategic game (GAME.EXE): the crime chronology
 * (message traffic and events log) and its screen.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "game.h"

add_chronology_entry(kind, msg)
int kind, msg;
{
    int p, q;

    msgs[num_msgs].time = clock_base;
    msgs[num_msgs].type = kind;
    msgs[num_msgs].msg = msg;
    msgs[num_msgs].flags = 0;
    msgs[num_msgs].sender = -1;
    msgs[num_msgs].level = 0;
    if (kind == 0) {
        p = suspects[plots[msg].suspect].person;
        msgs[num_msgs].sender = p;
        msgs[num_msgs].sender_city = persons[p].city;
        msgs[num_msgs].level = persons[p].fate;
        if (plots[msg].flags & 0xfff) {
            q = suspects[plots[msg].flags & 0xff].person;
            msgs[num_msgs].receiver = q;
            msgs[num_msgs].receiver_city = persons[q].city;
        }
    }
    num_msgs++;
    if (num_msgs >= 128) {
        strcpy(text_buf, "NSYN Overflow\n");
        show_menu(text_buf, 0x32, 0x32);
    }
}

chronology_screen(mode)
int mode;
{
    int md, tmp, msg, x, i, y;

    draw_page_frame(mode ? "Chronology" : "News", 0xe);
    y = 0x10;
    for (i = 0; i < num_msgs; i++) {
        if (msgs[i].type == -1)
            continue;
again:
        md = msgs[i].msg;
        x = 0;
        switch (msgs[i].type) {
        case 0:
            if (plots[md].flags & 0x2000) {
                draw_text_transparent(format_date_time(msgs[i].time) + 9, 8, y, 7);
                y += 8;
                text_buf[0] = 0;
                load_message_text(md);
                y = draw_wrapped_text(0x24, 0xc, y, 0);
                break;
            }
            if (msgs[i].flags && mode) {
                msg = msgs[i].msg;
                if (msgs[i].flags & 0x8000
                    && ((plots[msg].flags & 0xf00) == 0x200 || (plots[msg].flags & 0xf00) == 0x800)) {
                    strcpy(text_buf, suspects[plots[msg].suspect].name);
                    if (plots[msg].flags & 0x200)
                        strcat(text_buf, " sent msg to ");
                    else
                        strcat(text_buf, " met with ");
                    strcat(text_buf, suspects[plots[msg].flags & 0xf].name);
                    draw_text_transparent(text_buf, 8, y, 7);
                    y += 8;
                    strcpy(text_buf, "'");
                    load_message_text(msg);
                    strcat(text_buf, "'");
                    y = draw_wrapped_text(0x24, 0xc, y, 0xc);
                } else if ((plots[msg].flags & 0xf00) == 0x800) {
                    draw_text_transparent("Meeting Noted", 8, y, 7);
                    y += 8;
                    text_buf[0] = 0;
                    load_message_text(msg);
                    garble_message(msgs[i].flags, 5);
                    y = draw_wrapped_text(0x24, 0xc, y, 0xc);
                }
            }
            break;
        }
        if (y >= 0xc0) {
            draw_text("...more", 0x100, 0xc0, 0xc);
            wait_key_or_button();
            draw_page_frame(mode ? "Chronology" : "News", 0xe);
            y = 0x10;
            goto again;
        }
    }
    if (y == 0x10)
        draw_text("none", 0xc, y, 7);
    wait_key_or_button();
}
