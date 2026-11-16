/* CASE.C - FINAL.EXE: building a new case (participants, sites, red herrings),
 * the case briefing, crime/world data files and the Hall of Fame.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "final.h"

generate_case()
{
    int attempts, dist, nmsg, cnt, dist2, world, first, org, i, city, j, ok,
        dummy, second, rch, al, closest;

    here_city = 1;
    here_org = 1;
    env_var_52 = 0;
    msg_day = episode_crime;
    world = world_num;
    load_crime_file(msg_day);
    load_world_file(world);
    for (i = 0; i < 80; i++)
        clues[i].suspect = -1;
    for (i = 0; i < 16; i++)
        city_clue_count[i] = org_clue_count[i] = 2;
    double_agents = 0;
    for (i = 0; i < difficulty; i++)
        double_agents |= 1 << random(16);
    double_agents &= ~2;
    for (;;) {
        for (i = 0; i < 64; i++) {
            persons[i].org = -1;
            persons[i].id = 0;
            persons[i].known = 0;
            persons[i].fate = 0;
        }
        num_persons = 64;
        game_time = 99;
        env_var_38 = -1;
        attempts = 0;
        nmsg = -1;
        while (plots[++nmsg].suspect != -1)
            ;
        do {
            org1 = random(15) + 1;
            dist = city_distance(orgs[1].home, orgs[org1].home);
        } while ((dist > 10 || org1 == 1) && ++attempts < 999);
        do {
            org2 = random(15) + 1;
            dist = city_distance(orgs[1].home, orgs[org2].home);
            dist2 = city_distance(orgs[mm_org].home, orgs[org2].home);
        } while ((dist < 8 || dist2 > 8 || (orgs[org2].home & 0xf) <= 4) && ++attempts < 999);
        do {
            org3 = random(15) + 1;
            dist = city_distance(orgs[org2].home, orgs[org3].home);
        } while ((dist > 8 || (orgs[org3].home & 0xf) <= 4) && ++attempts < 999);
        do {
            city1 = random(16);
            dist = city_distance(orgs[1].home, cities[city1].code);
        } while ((dist < 8 || !org_alert_level(city1, org2) || mm_city == city1) && ++attempts < 999);
        do {
            city2 = random(16);
            dist = city_distance(cities[city1].code, cities[city2].code);
        } while ((dist > 12 || !org_alert_level(city2, org3) || mm_city == city2) && ++attempts < 999);
        do {
            city3 = random(16);
            dist = city_distance(orgs[1].home, cities[city3].code);
        } while ((dist > 10 || !org_alert_level(city3, org1)) && ++attempts < 999);
        if (attempts >= 999)
            continue;
        for (j = 0; j < 16; j++) {
            if ((orgs[j].home & 0xf) >= 8) {
                i = clamp(random(5) + (orgs[j].home & 0xf) - 2, 0, 15);
                cnt = clamp(random(5) + orgs[j].home / 16 - 2, 0, 15);
                orgs[j].home = (cnt << 4) + i;
            }
        }
        for (i = 0; i < num_suspects; i++)
            attempts += place_participant(i) ? 0 : 999;
        if (attempts < 999)
            break;
    }
    reset_people_marks();
    case_briefing(world);
    for (j = 0; j < 16; j++)
        orgs[j].flags = 0;
    for (j = 0; j < 16; j++) {
        closest = 999;
        first = second = -1;
        for (i = 0; i < 16; i++) {
            rch = org_can_reach(1, j, i);
            if ((al = org_alert_level(i, j)) != 0) {
                al = city_distance(cities[i].code, orgs[j].home);
                if (al < closest) {
                    closest = al;
                    second = first;
                    first = i;
                }
            }
            if (rch || !j) {
                set_location_known(j, i, 4);
                cities[i].orgs_known |= 1 << j;
                orgs[j].flags |= 1;
                closest = -1;
            }
        }
        if (first != -1) {
            set_location_known(j, first, 4);
            cities[first].orgs_known |= 1 << j;
        }
        if (second != -1) {
            set_location_known(j, second, 4);
            cities[second].orgs_known |= 1 << j;
        }
    }
    for (i = 0; i < 16; i++) {
        cnt = 0;
        closest = 999;
        first = second = -1;
        for (j = 4; j < 16; j++) {
            rch = org_can_reach(1, j, i);
            if ((al = org_alert_level(i, j)) != 0) {
                al = city_distance(cities[i].code, orgs[j].home);
                if (al < closest) {
                    closest = al;
                    second = first;
                    first = j;
                }
            }
            if (rch)
                cnt++;
        }
        if (cnt < 2 && first != -1) {
            set_location_known(first, i, 4);
            cities[i].orgs_known |= 1 << first;
        }
        if (cnt < 3 && second != -1) {
            set_location_known(second, i, 4);
            cities[i].orgs_known |= 1 << second;
        }
    }
    /* red herrings: one decoy per difficulty level and organization type */
    for (i = num_suspects; i < difficulty * 4 + num_suspects; i++) {
        do {
            do
                org = random(12) + 4;
            while (org == mm_org);
            do
                city = random(16);
            while (!org_alert_level(city, org));
        } while (add_location(org, city, 0) != -1);
        suspects[i].person = add_location(org, city, 0x8000);
        strcpy(suspects[i].name, "Red Herring");
        suspects[i].importance = random(4) + 3;
        do {
            suspect_id(i) = random(0x7fff);
            ok = 1;
            for (j = 0; j < i; j++)
                if ((suspect_id(i) & 0x7e) == (suspect_id(j) & 0x7e))
                    ok = 0;
        } while (!ok);
        suspects[i].flags = 0;
        suspects[i].found = 0;
        suspect_state[i].time = random(num_plots / 2) + 4;
        suspect_state[i].progress = 0;
        suspects[i].type = random(7);
        suspects[i].rank = random(7);
    }
    num_suspects += difficulty * 4;
}

reset_people_marks()
{
    int i, spare;

    for (i = 0; i < num_plots; i++)
        plots[i].state = 999;
}

place_participant(n)
int n;
{
    int site, tries, org, dd, city;

    tries = 0;
    do {
        suspect_id(n) = random(0x7fff);
        suspects[n].found = 0;
        suspect_state[n].time = -1;
        suspect_state[n].progress = 0;
        for (;;) {
            org = -1;
            if (suspects[n].flags & 1)
                org = org1;
            if (suspects[n].flags & 0x80)
                org = org2;
            if (suspects[n].flags & 0x40)
                org = org3;
            if (org == -1) {
                do {
                    org = random(15) + 1;
                    dd = city_distance(orgs[org].home, orgs[org2].home);
                } while ((dd > 12 || (orgs[org].home & 0xf) <= 4 || org == 1) && ++tries < 999);
            }
            city = -1;
            if (suspects[n].flags & 0x20)
                city = city1;
            if (suspects[n].flags & 0x10)
                city = city2;
            if (suspects[n].flags & 2)
                city = city3;
            if (city == -1) {
                do {
                    city = random(16);
                    dd = city_distance(cities[city].code, cities[city1].code);
                } while ((dd < 8 || !org_alert_level(city, org)) && ++tries < 999);
            }
            if (!org_alert_level(city, org) && ++tries < 999)
                continue;
            if (suspects[n].flags & 0x100) {
                org = mm_org;
                city = mm_city;
            } else if (org == mm_org && city == mm_city && ++tries < 999)
                continue;
            if (!difficulty && !n)
                city = 1;
            site = add_location(org, city, 0);
            if (site != -1 && persons[site].flags && ++tries < 999)
                continue;
            break;
        }
        if (tries < 999) {
            site = add_location(org, city, (unsigned)1 << n);
            if ((suspects[n].flags & 0x100) && persons[site].known)
                persons[site].roles |= (unsigned)1 << n;
            if (persons[site].fate < 0)
                persons[site].flags &= ~(1 << n);
        }
    } while (persons[site].fate < 0 && ++tries < 999);
    suspects[n].person = site;
    if (suspects[n].flags & 0x200)
        persons[site].id &= ~1;
    return tries < 999;
}

case_briefing(region)
int region;
{
    int org;

    strcpy(text_buf, "We have indications that ");
    strcat(text_buf, "an operation is in preparation somewhere in ");
    switch (region) {
    case 0:
        strcat(text_buf, "Europe.");
        break;
    case 1:
        strcat(text_buf, "Africa/Middle East.");
        break;
    case 2:
        strcat(text_buf, "Central America.");
        break;
    }
    if (difficulty < 2) {
        org = persons[suspects[random(num_suspects)].person].org;
        strcat(text_buf, " The ");
        strcat(text_buf, orgs[org].name);
        strcat(text_buf, " is known to be involved.");
        orgs[org].flags |= 1;
    }
    wrap_text_buffer(40);
    show_menu(text_buf, 8, 149);
    strcpy(text_buf, "Your mission is to prevent this operation from succeeding ");
    strcat(text_buf, "and to capture as many of the participants as possible.");
    if (difficulty)
        strcat(text_buf, " Caution, one or more Double Agents are believed to be active within the CIA.");
    clear_text_area();
    wrap_text_buffer(40);
    show_menu(text_buf, 8, 149);
    if ((cur_month == 0 || !(options & 0x80)) && !identify_leader_faces()) {
        set_scene_var(0, 4);
        strcpy(text_buf, "I'm afraid you're not quite up to speed yet Max. ");
        strcat(text_buf, "Perhaps you should practice your skills before you take this case.");
    } else {
        set_scene_var(0, 1);
        text_buf[0] = 0;
        if (cur_month == 0)
            strcat(text_buf, "OK, you're cleared. ");
        strcat(text_buf, "Here is some info we've picked up over the last few days. ");
        strcat(text_buf, "We think it's linked to this operation...\n");
        options |= 0x80;
    }
    drv_set_color_map(story_colors, story_colors);
    set_scene_background("briefing.pan", 0, 0);
    wrap_text_buffer(40);
    show_menu(text_buf, 8, 149);
}

char crime_file[] = "crime0.dta ";
char world_file[] = "world0.dta";

load_crime_file(n)
int n;
{
    int fd;

    crime_file[5] = n + '0';
    if (n > 9) {
        strcpy(crime_file + 5, "10.dta");
        crime_file[6] = n % 10 + '0';
    }
    fd = open(crime_file, 0x8000);
    read(fd, &num_suspects, 2);
    read(fd, &num_plots, 2);
    read(fd, suspects, num_suspects * sizeof(struct Suspect));
    read(fd, plots, num_plots * sizeof(struct Plot));
    read(fd, items, 72);
    close(fd);
}

load_world_file(n)
int n;
{
    int nc, f, norgs;

    world_file[5] = n + '0';
    nc = 16;
    norgs = 16;
    f = open(world_file, 0x8000);
    read(f, &nc, 2);
    read(f, &norgs, 2);
    read(f, cities, nc * sizeof(struct City));
    read(f, orgs, norgs * sizeof(struct Org));
    close(f);
}
