/* MSGTEXT.C - game library: message text lookup in text.dta and friends. */
#include <stdio.h>
#include "mps.h"
#include "gamelib.h"

extern char *strstr();

/* text_substitute's placeholders and the buffers their replacements are copied to,
 * each its own (word-aligned) array. MSC holds them until the end of
 * lookup_text_simple, which has no literals, so they open the object's _DATA. */
char subst_key_text[7][8] = {
    "$VICTIM", "$SNDORG", "$RCVORG", "$SNDLOC", "$RCVLOC", "$HLPORG", "$OBJECT",
};
char subst_victim[52] = "                                                   ";
char subst_sndorg[26] = "                         ";
char subst_rcvorg[26] = "                         ";
char subst_sndloc[26] = "                         ";
char subst_rcvloc[26] = "                         ";
char subst_hlporg[26] = "                         ";
char subst_object[52] = "                                                   ";
char *subst_keys[] = {
    subst_key_text[0], subst_key_text[1], subst_key_text[2], subst_key_text[3],
    subst_key_text[4], subst_key_text[5], subst_key_text[6],
};
char *subst_vals[] = {
    subst_victim, subst_sndorg, subst_rcvorg, subst_sndloc, subst_rcvloc, subst_hlporg,
    subst_object,
};

lookup_text_simple(file, key)
char *file, *key;
{
    lookup_text(file, key, subst_keys, subst_vals, 7);
}

lookup_text(file, key, keys, vals, nsubst)
char *file, *key;
char **keys, **vals;
int nsubst;
{
    char s[256];
    int rc, eof;
    FILE *stream;

    stream = fopen(file, "rt");
    do
        eof = fscanf(stream, "%[^\n]\n", s);
    while (strcmp(s, key) && eof != -1);
    if (eof != -1) {
        do
            fscanf(stream, "%[^\n]\n", s);
        while (s[0] == '*');
        do {
            text_substitute(s, keys, vals, nsubst);
            strcat(text_buf, s);
            strcat(text_buf, " ");
            fscanf(stream, "%[^\n]\n", s);
        } while (s[0] != '*');
        rc = 1;
    } else {
        strcat(text_buf, "This information requires security clearance: ");
        strcat(text_buf, key);
        rc = 0;
    }
    fclose(stream);
    return rc;
}

text_substitute(s, keys, vals, n)
char *s;
char **keys, **vals;
int n;
{
    char *p;
    int i;

    for (i = 0; i < n; i++)
        if (p = strstr(s, keys[i])) {
            strcpy(subst_tail, p);
            *p = 0;
            strcat(s, vals[i]);
            strcat(s, subst_tail + strlen(keys[i]));
        }
}

compose_intercept_text(n)
int n;
{
    int p, reversed;
    int tmp, sender, used;
    int r, to, city;

    p = msgs[n].msg;
    strcpy(text_buf, "");
    sender = msgs[n].sender;
    to = msgs[n].receiver;
    if (p >= 0) {
        reversed = 0;
        if ((plots[p].flags & 0xf00) == 0x300) {
            tmp = sender;
            sender = to;
            to = tmp;
            reversed = 1;
        }
    }
    strcpy(subst_vals[0], player_name);
    strcpy(subst_vals[6], player_org_name);
    strcpy(subst_vals[1], orgs[persons[sender].org].name);
    strcpy(subst_vals[2], orgs[persons[to].org].name);
    if (!reversed) {
        strcpy(subst_vals[3], cities[msgs[n].sender_city].name);
        strcpy(subst_vals[4], cities[msgs[n].receiver_city].name);
    } else {
        strcpy(subst_vals[4], cities[msgs[n].sender_city].name);
        strcpy(subst_vals[3], cities[msgs[n].receiver_city].name);
    }
    used = 0;
    do {
        r = random(7);
        if (!(used & 1 << r)) {
        used |= 1 << r;
        switch (r) {
        case 0:
            if (persons[sender].known & 8)
                lookup_random_text("text.dta", "*SLOC00", 8);
            break;
        case 1:
            if (persons[to].known & 8)
                lookup_random_text("text.dta", "*RLOC00", 8);
            break;
        case 2:
            if (persons[sender].known & 4)
                lookup_random_text("text.dta", "*SORG00", 8);
            break;
        case 3:
            if (persons[to].known & 4)
                lookup_random_text("text.dta", "*RORG00", 8);
            break;
        case 4:
            make_msg_key(msg_day, p >= 0 ? plots[p].msg : p);
            strcat(text_buf, "\200");
            lookup_text_simple("text.dta", msg_key);
            strcat(text_buf, "\217");
            break;
        case 5:
            lookup_random_text("text.dta", "*FLUF00", 12);
            break;
        case 6:
            strcpy(msg_key, "*ALRT00");
            msg_key[6] += clamp(msgs[n].level / 20, 0, 4);
            if (msgs[n].level > 15)
                lookup_text_simple("text.dta", msg_key);
            else {
                city = persons[suspects[random(num_suspects - difficulty * 4)].person].org;
                if (persons[sender].org != city && persons[to].org != city) {
                    strcpy(subst_vals[5], orgs[city].name);
                    lookup_random_text("text.dta", "*AIDD00", 2);
                }
            }
            break;
        }
        }
    } while (used != 0x7f);
}

lookup_random_text(file, key, n)
char *file, *key;
int n;
{
    n = random(n);
    key[6] = n % 10 + '0';
    key[5] = n / 10 + '0';
    lookup_text_simple(file, key);
}

load_message_text(p)
int p;
{
    strcpy(subst_vals[0], player_name);
    strcpy(subst_vals[6], player_org_name);
    strcpy(subst_vals[1], orgs[persons[suspects[plots[p].suspect].person].org].name);
    strcpy(subst_vals[3], cities[persons[suspects[plots[p].suspect].person].city].name);
    make_msg_key(msg_day, p >= 0 ? plots[p].msg : p);
    lookup_text_simple("text.dta", msg_key);
#ifdef GAME_MSGTEXT
    orgs[persons[suspects[plots[p].suspect].person].org].flags |= 1;
#endif
}

make_msg_key(day, msg)
int day, msg;
{
    strcpy(msg_key, "*MSG0000");
    if (msg < 0) {
        day = 99;
        msg = -msg / 2;
    }
    msg_key[4] += day / 10;
    msg_key[5] += day % 10;
    msg_key[6] += msg / 10;
    msg_key[7] += msg % 10;
}
