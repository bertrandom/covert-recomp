/* CHASE.H - Covert Action car chase (CHASE.EXE): shared types and globals.
 * DGROUP offsets of the original are given in the comments. Library globals
 * (g_gfx, options, bios_regs, back_page) come from MPS.H. */

/* Shared game state: COVERT.EXE stores a far pointer to it at 0000:04F0. */
#define ENV (*(unsigned char far * far *)0x4F0L)

typedef struct Rect {
    int x0, y0, x1, y1;
} Rect;

typedef struct Car {    /* 0x14 bytes */
    int x, y;           /* +00 map position (pixels, 32 per block) */
    int dir;            /* +04 heading 0 N, 1 E, 2 S, 3 W */
    int follow;         /* +06 tracking the suspect */
    int tx, ty;         /* +08 last known suspect position / destination */
    int req;            /* +0C requested turn, -1 none */
    int heat;           /* +0E how much the suspect has noticed this car */
    int speed;          /* +10 */
    int bits;           /* +12 car spec: 0-1 speed, 2 tracking, 3 handling, 4-5 visibility */
} Car;

struct city {           /* 0x22 bytes, env block 5 */
    char name[24];      /* +00 */
    int code;           /* +18 low nibble x, high nibble y */
    int size;           /* +1A */
    unsigned org_mask;  /* +1C organizations with a building in this city */
    int pad;            /* +1E */
    unsigned char map_x, map_y;     /* +20 */
};

struct org {            /* 0x24 bytes, env block 6 */
    char abbrev[6];     /* +00 */
    char name[26];      /* +06 */
    char flags;         /* +20 */
    char pad[3];
};

/* Game variables mirrored in the env block (env word offset in the name) */
extern int city_id;                 /* 6844 env +20 */
extern int target_building;         /* 69d2 env +22: building the suspect heads for */
extern int env26;                   /* 5c06 */
extern int env28;                   /* 5c0a */
extern int env2a;                   /* 5c0e */
extern int env2c;                   /* 5bee */
extern int env2e;                   /* 5bf0 */
extern unsigned game_time;          /* 428e env +30, minutes */
extern int env32;                   /* 4786 */
extern int env34;                   /* 5be6 */
extern int env36;                   /* 5be8 */
extern int env38;                   /* 684c */
extern int difficulty;              /* 4288 env +3A */
extern int env3c;                   /* 5be4 */
extern int num_agents;              /* 5c66 env +3E */
extern int num_plots;               /* 5bfe env +40 */
extern int env42;                   /* 684a */
extern int env44;                   /* 5bea */
extern char video_mode;             /* 67fe env byte +44 */
extern int is_cga;                  /* 4560 video_mode == 'C' */
extern int env46;                   /* 5be0 */
extern int alert_level;             /* 3e80 env +48 */
extern int env4a;                   /* 5c64 */
extern int env4c;                   /* 6848 */
extern int env_flags;               /* 647e env +4E */

/* Env file reader */
extern int env_file;                /* 23b8 */
extern unsigned env_pos;            /* 23b6 read position in the env block, 0 = read the file */
extern char far *env_cur;           /* 23b2 */
extern char player_block[];         /* 42ce 0x28E bytes */
extern char agents[];               /* 5c6a 48 bytes per agent */
extern char agent_extra[];          /* 673e 6 bytes per agent */
extern char plots[];                /* 50e0 44 bytes per plot */
extern struct city cities[];        /* 4562 16 x 0x22 */
extern struct org orgs[];           /* 648a 16 x 0x24 */

/* Chase state */
extern int chase_mode;              /* 16f4 0 follow, 1 ?, 2 you are chased */
extern int game_speed;              /* 16f6 0 slow, 1 normal, 2 fast (env flags bits 10-11) */
extern int real_mission;            /* 5bfc started from the game: real city and buildings */
extern int is_night;                /* 4286 limited view distance */
extern Car cars[3];                 /* 4290 0 suspect (player when chase_mode 2), 1-2 Max's team */
extern int cur_car;                 /* 17da car the player drives */
extern int chase_clock;             /* 50de frames since the chase started, shown as seconds */
extern int chase_over;              /* 66ce */
extern int outcome;                 /* 50dc */
extern int score;                   /* 6842 */
extern int heat_limit;              /* 6846 heat a car can build before the suspect notices */
extern int in_range;                /* 50cc a team car is right behind the suspect */
extern int show_targets;            /* 626a */
extern int escape_timer;            /* 5c62 */
extern int lost_count;              /* 4784 */
extern int turn_toggle;             /* 42cc */
extern int car_ahead;               /* 3e84 car_in_view: the other car is in front */
extern int sound_param;             /* 5bfa */
extern int target_x, target_y;      /* 69ce, 69d0 */
extern int dir_dx[4];               /* 17a0 */
extern int dir_dy[4];               /* 17a8 */
extern unsigned speed_masks[];      /* 17b0 frames (of 6) a car moves at each speed */
extern int grade_colors[][2];       /* 1862 */

/* City map */
extern unsigned map_seed;           /* 5c00 */
extern unsigned char city_map[24][24];  /* 4788 block road bits: 1 east/west, 8 north/south */
extern int bld_x[], bld_y[];        /* 6802, 6822 building positions on the map */
extern int chase_start, chase_dest; /* 5c02, 428c buildings the suspect starts at and heads for */
extern int wall_x[4][2], wall_y[4][2];      /* 17ba, 17ca map lines closing each side of a block */

/* Street view and dashboard */
extern int offscreen_page;          /* 178c */
extern RastPort *sprite_page;       /* 17ee */
extern RastPort *scene_page;        /* 1802 */
extern RastPort *car_sprites;       /* 1816 windshield view port */
extern Rect car_shape_rect[];       /* 170c car seen through the windshield, 16 sizes */
extern int car_shapes[];            /* 5c12 */
extern char select_palette[];       /* 16e4 */
extern char chase_palette[];        /* 16fa */
extern char text_palette[];         /* 178e */
extern int view_x, view_y;          /* 23ba, 23bc street view scroll position */
extern int tile_x, tile_y;          /* 23be, 23c0 block drawn at the view page origin */
extern int edge_xw[4][2], edge_yh[4][2];   /* 189c, 18ac walls drawn where a block has no road */
extern int scene;                   /* 50c8 street scene picture shown in the windshield */
extern int last_scene, last_dash_y; /* 18be, 18c0 */
extern int dash_near, dash_dist, dash_x, dash_y, dash_dx, dash_dy, dash_size;  /* 23c2-23ce */
extern char clock_str[];            /* 18c2 "0:00:00" */
extern char message[];              /* 3e86 */
extern char num_buf[];              /* 626c */
extern char loc_buf[];              /* 23d0 */
