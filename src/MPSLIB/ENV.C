/* ENV.C - MicroProse library: save/load the game state to env.sve, or keep it
 * in the shared far block at 0:4F0 when the file name is "env.sve". */
#include "mps.h"
#include "gamelib.h"

#define ENV (*(unsigned char far * far *)0x4F0L)
#define FP_OFF(fp) (*((unsigned *)&(fp)))
#define FP_SEG(fp) (*((unsigned *)&(fp) + 1))

/* game variables mirrored in the env block (the shared ones are in gamelib.h):
 * env words 28h/2Ah the organizations and 2Ch/2Eh the cities of the plot's main
 * roles, 3Ch the random seed, 4Ah the CIA moles, 4Eh the skill levels; the other
 * env_var_NN are named after their env word offset */
extern int org2, org3, city1, city2, env_var_38, rand_seed;
extern int jailbreak_person, double_agents, skill_levels, env_var_52;
extern int env_var_30_copy;         /* copy of clock_base */
extern char cur_person_name[];

/* blocks saved after the 1K header (the others are gamelib.h's tables) */
extern char player_block[];         /* 0x28E bytes */
extern char items[];                /* 0x48 bytes: the 4 plot items */

extern int env_fd;
extern int env_mem_offset;          /* 0: file; else offset into the env block */
extern char far *env_ptr;

save_env(fname)
char *fname;
{
    int i;
    char far *bufp;
    char buf[1024];

    env_var_30_copy = clock_base;
    *(int far *)(ENV + 0x20) = here_city;
    *(int far *)(ENV + 0x22) = here_org;
    *(int far *)(ENV + 0x24) = options;
    *(int far *)(ENV + 0x26) = msg_day;
    *(int far *)(ENV + 0x28) = org2;
    *(int far *)(ENV + 0x2a) = org3;
    *(int far *)(ENV + 0x2c) = city1;
    *(int far *)(ENV + 0x2e) = city2;
    *(int far *)(ENV + 0x30) = clock_base;
    *(int far *)(ENV + 0x32) = num_persons;
    *(int far *)(ENV + 0x34) = num_sites;
    *(int far *)(ENV + 0x36) = game_time;
    *(int far *)(ENV + 0x38) = env_var_38;
    *(int far *)(ENV + 0x3a) = difficulty;
    *(int far *)(ENV + 0x3c) = rand_seed;
    *(int far *)(ENV + 0x3e) = num_suspects;
    *(int far *)(ENV + 0x40) = num_plots;
    *(int far *)(ENV + 0x42) = jailbreak_person;
    *(int far *)(ENV + 0x44) = video_mode;
    *(int far *)(ENV + 0x46) = num_msgs;
    *(int far *)(ENV + 0x4a) = double_agents;
    *(int far *)(ENV + 0x4c) = seen_orgs;
    *(int far *)(ENV + 0x4e) = skill_levels;
    *(int far *)(ENV + 0x52) = env_var_52;
    if (strcmp(fname, "env.sve")) {
        bufp = (char far *)buf;
        env_fd = open(fname, 0x8301, 0x80);
        env_ptr = ENV + 0x10;
        movedata(FP_SEG(env_ptr), FP_OFF(env_ptr), FP_SEG(bufp), FP_OFF(bufp), 0x3f0);
        write(env_fd, buf, 0x3f0);
        strcpy(cur_person_name, cities[here_city].name);
        env_mem_offset = 0;
    } else
        env_mem_offset = 0x400;
    write_far_block(env_fd, player_block, 0x28e);
    write_far_block(env_fd, suspects, num_suspects * 48);
    write_far_block(env_fd, suspect_state, num_suspects * 6);
    write_far_block(env_fd, plots, num_plots * 44);
    write_far_block(env_fd, cities, 0x220);
    write_far_block(env_fd, orgs, 0x240);
    write_far_block(env_fd, persons, 0x400);
    write_far_block(env_fd, sites, 0xc00);
    write_far_block(env_fd, clues, 0x3c0);
    write_far_block(env_fd, msgs, 0x700);
    write_far_block(env_fd, items, 0x48);
    write_far_block(env_fd, city_clue_count, 0x40);
    if (!env_mem_offset)
        close(env_fd);
}

write_far_block(fd, buf, n)
int fd;
char *buf;
int n;
{
    char far *fp;

    if (env_mem_offset) {
        fp = (char far *)buf;
        env_ptr = ENV + env_mem_offset;
        movedata(FP_SEG(fp), FP_OFF(fp), FP_SEG(env_ptr), FP_OFF(env_ptr), n);
        env_mem_offset += n;
    } else
        write(fd, buf, n);
}

read_far_block(fd, buf, n)
int fd;
char *buf;
int n;
{
    char far *fp;

    if (env_mem_offset) {
        fp = (char far *)buf;
        env_ptr = ENV + env_mem_offset;
        movedata(FP_SEG(env_ptr), FP_OFF(env_ptr), FP_SEG(fp), FP_OFF(fp), n);
        env_mem_offset += n;
    } else
        read(fd, buf, n);
}

load_env(fname)
char *fname;
{
    int i;
    int preserve[3];
    char far *bufp;
    char buf[1024];

    if (strcmp(fname, "env.sve")) {
        bufp = (char far *)buf;
        env_fd = open(fname, 0x8000);
        if (env_fd == -1) {
            strcpy(text_buf, "File Error: ");
            strcat(text_buf, fname);
            strcat(text_buf, "\n");
            show_menu(text_buf, 100, 80);
            return 0;
        }
        for (i = 0; i < 3; i++)
            preserve[i] = ((int far *)(ENV + 0x60))[i];
        env_ptr = ENV + 0x10;
        read(env_fd, buf, 0x3f0);
        movedata(FP_SEG(bufp), FP_OFF(bufp), FP_SEG(env_ptr), FP_OFF(env_ptr), 0x3f0);
        for (i = 0; i < 3; i++)
            ((int far *)(ENV + 0x60))[i] = preserve[i];
        env_mem_offset = 0;
    } else
        env_mem_offset = 0x400;
    here_city = *(int far *)(ENV + 0x20);
    here_org = *(int far *)(ENV + 0x22);
    options = *(int far *)(ENV + 0x24);
    msg_day = *(int far *)(ENV + 0x26);
    org2 = *(int far *)(ENV + 0x28);
    org3 = *(int far *)(ENV + 0x2a);
    city1 = *(int far *)(ENV + 0x2c);
    city2 = *(int far *)(ENV + 0x2e);
    clock_base = *(int far *)(ENV + 0x30);
    num_persons = *(int far *)(ENV + 0x32);
    num_sites = *(int far *)(ENV + 0x34);
    game_time = *(int far *)(ENV + 0x36);
    env_var_38 = *(int far *)(ENV + 0x38);
    difficulty = *(int far *)(ENV + 0x3a);
    rand_seed = *(int far *)(ENV + 0x3c);
    num_suspects = *(int far *)(ENV + 0x3e);
    num_plots = *(int far *)(ENV + 0x40);
    jailbreak_person = *(int far *)(ENV + 0x42);
    if (env_mem_offset)
        video_mode = ENV[0x44];
    is_cga = video_mode == 'C';
    num_msgs = *(int far *)(ENV + 0x46);
    double_agents = *(int far *)(ENV + 0x4a);
    seen_orgs = *(int far *)(ENV + 0x4c);
    skill_levels = *(int far *)(ENV + 0x4e);
    env_var_52 = *(int far *)(ENV + 0x52);
    read_far_block(env_fd, player_block, 0x28e);
    read_far_block(env_fd, suspects, num_suspects * 48);
    read_far_block(env_fd, suspect_state, num_suspects * 6);
    read_far_block(env_fd, plots, num_plots * 44);
    read_far_block(env_fd, cities, 0x220);
    read_far_block(env_fd, orgs, 0x240);
    read_far_block(env_fd, persons, 0x400);
    read_far_block(env_fd, sites, 0xc00);
    read_far_block(env_fd, clues, 0x3c0);
    read_far_block(env_fd, msgs, 0x700);
    read_far_block(env_fd, items, 0x48);
    read_far_block(env_fd, city_clue_count, 0x40);
    if (!env_mem_offset)
        close(env_fd);
}
