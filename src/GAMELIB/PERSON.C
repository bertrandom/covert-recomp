/* PERSON.C - shared game library: text wrapping, organizations, people and
 * the paper-style page frames (linked by BUG, GAME, TAC and FINAL).
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "mps.h"
#include "gamelib.h"

wrap_text_buffer(width)
int width;
{
    int pos;
    int i;

    pos = 0;
    for (i = 0; i < strlen(text_buf); i++) {
        if (text_buf[i] == '^') {
            text_buf[i] = ' ';
            text_buf[i + 1] = '\n';
            pos = -1;
        }
        if (text_buf[i] == '\n')
            pos = -1;
        pos++;
        if (pos > width && text_buf[i] == ' ' && text_buf[i + 1] != ' ') {
            text_buf[i] = '\n';
            pos = 0;
        }
    }
    if (pos > 0)
        strcat(text_buf, "\n");
}

draw_wrapped_text(width, x, y, color)
int width, x, y, color;
{
    int c;
    int lastsp;
    int w;
    int i;
    int start;

    for (i = w = start = lastsp = 0; i < strlen(text_buf); i++) {
        w += drv_char_width(g_gfx->font, text_buf[i]);
        if (text_buf[i] == ' ' || text_buf[i] == '\n')
            lastsp = i;
        if (text_buf[i] == '\n' || w > width * 8) {
            c = text_buf[lastsp];
            text_buf[lastsp] = 0;
            draw_text_transparent(text_buf + start, x, y, color);
            text_buf[lastsp] = c;
            y += 8;
            w = 0;
            start = lastsp + 1;
            i = lastsp;
            if (y >= 0xC0)
                break;
        }
    }
    if (w > 0 && y < 0xC0) {
        draw_text_transparent(text_buf + start, x, y, color);
        y += 8;
    }
    return y;
}

garble_message(mask, n)
unsigned mask;
int n;
{
    char tmp[512];
    int from;
    int i;
    int on;
    int words;

    from = words = on = 0;
    tmp[0] = 0;
    for (i = 0; i < strlen(text_buf); i++) {
        if (text_buf[i] == ' ' || text_buf[i] == '\n') {
            if (mask & (1 << (words % n))) {
                if (!on)
                    from = i + 1;
                on = 1;
            } else {
                if (on) {
                    text_buf[i] = 0;
                    strcat(tmp, text_buf + from);
                    text_buf[i] = ' ';
                    strcat(tmp, " ... ");
                }
                on = 0;
            }
            words++;
        }
    }
    if (on)
        strcat(tmp, text_buf + from);
    strcpy(text_buf, tmp);
}

org_can_reach(org, org2, city)
int org, org2, city;
{
    int d;

    d = city_distance(orgs[org].home, cities[city].code)
        + city_distance(orgs[org].home, orgs[org2].home) * 3 / 2;
    return org_alert_level(city, org2) * 4 + 16 > d;
}

city_distance(a, b)
unsigned a, b;                      /* city codes: low nibble x, high nibble y */
{
    int dx;
    int dy;

    dx = abs((a & 15) - (b & 15));
    dy = abs((((unsigned char)a & 0xF0) >> 4) - (((unsigned char)b & 0xF0) >> 4));
    if (dx > dy)
        return dx * 2 + dy;
    return dy * 2 + dx;
}

city_map_distance(c1, c2)
int c1, c2;
{
    int dx;
    int dy;

    dx = abs(cities[c1].map_x - cities[c2].map_x);
    dy = abs(cities[c1].map_y - cities[c2].map_y);
    if (dx > dy)
        return dx * 2 + dy;
    return dy * 2 + dx;
}

append_building_type(city, org)
int city, org;
{
    int level;

    level = org_alert_level(city, org);
    if (level == 1)
        strcat(text_buf, " hideout");
    if (level == 2)
        strcat(text_buf, " agent");
    if (level == 3)
        strcat(text_buf, " safehouse");
    if (level == 4)
        strcat(text_buf, " active cel");
    if (level == 5)
        strcat(text_buf, " office");
    return level;
}

org_alert_level(city, org)
int city, org;
{
    int d;
    int t;
    int level;

    d = city_distance(cities[city].code, orgs[org].home);
    level = (cities[city].size + 4) * orgs[org].strength / (d + 1);
    if (level > 0) {
        t = level * 60 / orgs[org].range + 10;
        level = level * 6 / orgs[org].range + 1;
        if (level > 5)
            level = 5;
    }
    if (city == mm_city && org == mm_org)
        level = 1;
    if (level <= 0 && difficulty == 0 && city == 1 && persons[suspects[0].person].org == org)
        level = 1;
    return level;
}

append_person_name(p)
int p;
{
    if (persons[p].known & 2)
        person_name(p);
    else {
        strcat(text_buf, "Agent A");
        text_buf[strlen(text_buf) - 1] = p % 26 + 'A';
    }
}

char *first_names[2][64] = {          /* 296A (strings 245F) [female, male] */
  {
      "Georgina", "Arkada", "Yuria", "Anatola",
      "Andra", "Nikola", "Viktora", "Ivana",
      "Natasha", "Svetlana", "Anna", "Ludmilla",
      "Lexandra", "Katerina", "Olga", "Nadia",
      "Leona", "Pat", "Carla", "Bobbie",
      "Jenny", "Frieda", "Alice", "Rose",
      "Deirdre", "Martha", "Lisa", "Erica",
      "Liz", "Emma", "Isadora", "Jane",
      "Omara", "Alicia", "Hasana", "Leila",
      "Yasria", "Ailha", "Yousfa", "Aziza",
      "Fatima", "Benazir", "Ouida", "Selima",
      "Ismaila", "Persis", "Haurouna", "Zara",
      "Carlotta", "Josita", "Miguela", "Ramona",
      "Luisa", "Julia", "Juanita", "Raquel",
      "Isabel", "Maria", "Elena", "Linda",
      "Carmen", "Agnes", "Celeste", "Phyllis",
  },
  {
      "Georgi", "Arkady", "Yuri", "Anatol",
      "Andrei", "Nikita", "Viktor", "Ivan",
      "Boris", "Nikolai", "Grigori", "Pavel",
      "Mischa", "Petrov", "Vladimir", "Mikhail",
      "Leon", "Ian", "Carl", "Bob",
      "Jim", "Fred", "Alan", "Ralph",
      "Antoine", "Heinrich", "Eric", "Gordon",
      "David", "Pierre", "Claude", "Gerard",
      "Omar", "Ali", "Hasan", "Abdul",
      "Yasr", "Abu", "Yousf", "Saadi",
      "Achmet", "Ibrahim", "Selim", "Ismail",
      "Mahmoud", "Haround", "Suleiman", "Yezid",
      "Carlos", "Jose", "Miguel", "Ramon",
      "Luis", "Julio", "Juan", "Pedro",
      "Enrique", "Eduardo", "Arturo", "Jorge",
      "Manuel", "Hector", "Franco", "Jaime",
  }
};
char *last_names[] = {                  /* 2A6A */
    "Katkov", "Gorny", "Gromyko", "Kormarov",
    "Molotov", "Charyk", "Markov", "Filatov",
    "Badenov", "Chekhov", "Gogol", "Zhukov",
    "Nevsky", "Kemidov", "Dubrovnik", "Kerensky",
    "Lorenz", "Koch", "Baader", "Brown",
    "Jones", "Bloom", "Cahill", "Grivas",
    "Cook", "Muller", "Hansen", "Olsen",
    "Merrick", "Ballard", "Verne", "Konrad",
    "Abbas", "Said", "Daoud", "Moussa",
    "Nidal", "Khaled", "Hammid", "Afafat",
    "Agha", "Murad", "Akbar", "Hosayn",
    "Raisuli", "Musafir", "Nasr", "Rashid",
    "Munoz", "Diaz", "Munoz", "Perez",
    "Ramirez", "Alvarez", "Garcia", "Lopez",
    "Santos", "Diego", "Cordoba", "Valdez",
    "Santiago", "Enriquez", "Sanchez", "Delarosa",
};

person_name(p)
int p;
{
    int unused;

    strcat(text_buf, first_names[persons[p].id & 1]
        [orgs[persons[p].org].nationality * 2 + ((persons[p].id >> 1) & 15)]);
    strcat(text_buf, " ");
    strcat(text_buf, last_names[orgs[persons[p].org].nationality * 2 + ((persons[p].id >> 5) & 15)]);
}

show_master_plan(org, reveal)
int org, reveal;
{
    int none;
    int person;
    int x;
    int j;                          /* unused */
    int i;
    int y;

    switch (org) {
    case 0:
        seen_orgs |= 1;
        draw_page_frame("Master Plan", 9);
        y = 0x20;
        text_buf[0] = 0;
        for (i = 0; i < 5; i++)
            strcat(text_buf, "--SECRET--");
        draw_text_transparent(text_buf, 12, 0x10, 14);
        draw_text_transparent(text_buf, 12, 0xBC, 14);
        for (i = 0; i < num_suspects - difficulty * 4; i++) {
            if (suspects[i].flags & 0x100)
                continue;
            x = (i & 3) * 0x48 + 0x1C;
            if (i == 4)
                y += 0x50;
            person = suspects[i].person;
            if ((persons[person].known & 0x81) != 0x80)
                draw_portrait(persons[person].id, x, y);
            text_buf[0] = 0;
            if (persons[person].fate == -1)
                strcpy(text_buf, "ARRESTED");
            if (persons[person].fate == -2)
                strcpy(text_buf, "IN HIDING");
            if (persons[person].fate == -3)
                strcpy(text_buf, " TURNED");
            draw_text_transparent(text_buf, x - 1, y + 0x10, 5);
            draw_text_transparent(text_buf, x - 2, y + 0x10, 12);
            strcpy(text_buf, suspects[i].name);
            draw_text_centered(text_buf, x + 0x19, y + 0x38, 12);
            y ^= 8;
        }
        break;
    default:
        seen_orgs |= 1 << org;
        draw_page_frame("Personnel File", 9);
        strcpy(text_buf, orgs[org].name);
        strcat(text_buf, " Action Team");
        draw_text_transparent(text_buf, 0x50, 0x10, 5);
        y = 0x20;
        none = 1;
        for (i = 1; i < num_persons; i++) {
            if (persons[i].org == org && (persons[i].flags & 0x7FFF)) {
                if (reveal)
                    persons[i].known |= 0x0E;
                text_buf[0] = 0;
                append_person_name(i);
                if (persons[i].known & 8) {
                    strcat(text_buf, ", ");
                    strcat(text_buf, cities[persons[i].city].name);
                }
                draw_text_transparent(text_buf, 0x50, y, 12);
                y += 8;
                none = 0;
            }
        }
        if (none)
            draw_text_transparent("(No activity)", 0x50, y, 12);
    }
    wait_key_or_button();
}

draw_page_frame(title, color)
char *title;
int color;
{
    int w;

    screen_width = 320;
    if (is_cga)
        color = 2;
    gfx_fill_rect(g_gfx, 0, 0, 320, 10, 6);
    gfx_fill_rect(g_gfx, 0, 10, 320, 190, color);
    g_gfx->fillcolor = color;
    draw_title_tab(0xA0, 2, color);
    draw_line(0, 0, 0, 199, 6);
    draw_line(319, 0, 319, 199, 6);
    gfx_fill_rect(g_gfx, 8, 14, 304, 186, 15);
    draw_line(10, 13, 312, 13, 7);
    draw_line(312, 13, 312, 199, 8);
    w = text_width(title);
    gfx_fill_rect(g_gfx, 0xEF - w / 2, 3, w + 2, 9, 7);
    draw_text_transparent(title, 0xF0 - w / 2, 4, 0);
    g_gfx->fillcolor = 15;
}

draw_title_tab(x, y, color)
int x, y, color;
{
    gfx_fill_rect(g_gfx, x + 10, y, 0x8C, 8, color);
    if (y)
        draw_line(x + 10, y - 1, x + 0x93, y - 1, 5);
    draw_line(0, y + 8, x, y + 8, 8);
    draw_line(x + 0x9E, y + 8, 319, y + 8, 8);
    draw_sprite_a(0x6D, x, y);
    draw_sprite_a(0x6E, x + 0x93, y);
    drv_recolor_rect(g_gfx, x, y, 0xA0, 8, 13, color);
}

char clock_str[] = "00:00:00";            /* 2B4A */

char *format_clock_hms(secs)
int secs;
{
    int sec;
    int time;
    int minute;
    int hour;

    time = (secs / 60 + clock_base) % 1440;
    hour = time / 60;
    minute = time % 60;
    sec = secs % 60;
    clock_str[0] = hour / 10 + '0';
    clock_str[1] = hour % 10 + '0';
    clock_str[3] = minute / 10 + '0';
    clock_str[4] = minute % 10 + '0';
    clock_str[6] = sec / 10 + '0';
    clock_str[7] = sec % 10 + '0';
    return clock_str;
}

text_width(s)
char *s;
{
    unsigned char *cur;
    int fn;
    int tw;

    cur = (unsigned char *)s;
    fn = g_gfx->font;
    tw = 0;
    while (*cur)
        tw += drv_char_width(fn, *cur++);
    return tw;
}

draw_card_panel(x, y)
int x, y;
{
    gfx_fill_rect(g_gfx, x, y, 0x130, 200 - y, 15);
    draw_line(x + 1, y, x + 0x130, y, 7);
    draw_line(x + 0x130, y, x + 0x130, 199, 8);
    draw_line(x, y + 1, x, 199, 7);
}

draw_text_centered(s, x, y, color)
char *s;
int x, y, color;
{
    x -= text_width(s) / 2;
    g_gfx->textbg = 0;
    draw_text(s, x, y, color);
    g_gfx->textbg = 1;
}
