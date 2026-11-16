/* GUARD.C - Covert Action building infiltration (TAC.EXE): the guards' AI,
 * room distances and guard path finding, guard placement and line of sight,
 * the equipment screen and the equipment panel.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "mps.h"
#include "tac.h"

/* Assembly segment (far) */
extern int far drv_begin_image_grab();
extern int far drv_get_image();
extern int far drv_end_image_grab();
extern void far gate_thunk_b();     /* draw an image: (port, x, y, image) */

/* MS C runtime */
extern char *itoa();
extern char *strcat();

/* One frame of a guard's life: spawning, noticing Max, choosing where to go
 * and walking there step by step. */
guard_think(n)
int n;
{
    int nvals, chase, dist, here, tries, destx, mindist, desty, wayout, i, minvals, ok;
    int cx, sx, dx, cy, sy, room, dy, item, dir;

    if (n == 1) {
        last_at_goal = guards_at_goal;
        guards_at_goal = max_heard = guards_active = guards_near = guard_in_room = 0;
        if (!frame_count) {
            compute_room_distances(post_room, 0);
            for (i = 0; i < 24; i++)
                room_dist[i] = rooms[i].dist;
            compute_room_distances(start_room, 0);
        }
        if (made_noise && target_person != -1 && cur_room == start_room)
            compute_room_distances(start_room, 240);
    }
    if (!(guards[n].flags & 0x80) && !(frame_count & 15) &&
        ((tac_mode != 2 && (random(1000 / (difficulty + 1)) < alarm_timer || !frame_count)) ||
         ((tac_mode == 2 || on_alert) && (n & 7) == ((frame_count >> 5) & 7))))
        spawn_guard(n);
    if (!(guards[n].flags & 0x80)) return;
    if (guards[n].stun < 999) guards_active++;
    if (guards[n].stun < 24) guards_near++;
    if (guards[n].room == goal_room && (guards[n].stun < 999 || difficulty < 2) &&
        ++guards_at_goal >= 2 && goal_room != cur_room)
        compute_room_distances(-1, 0);
    if (tac_mode == 2 && guards[n].room == start_room && guards[n].stun < 24 && cur_room != start_room)
        mission_over = 1;
    cx = guards[n].x / 16;
    cy = guards[n].y / 16;
    if (guard_sees_max(n) && guards[n].stun < 24 && tac_mode != 1) {
        if (disguised) {
            dx = guards[n].x - guards[0].x;
            dy = guards[n].y - guards[0].y;
            dir = direction8_coarse(dx, dy);
            dir = abs(dir - guards[0].dir);
            if (++max_moved > 256 / (difficulty + 1) || dir < 2 || dir > 6)
                guards[n].spotted += 2;
            else
                guards[n].spotted = 0;
        } else {
            guards[n].spotted++;
            guards[n].flags &= ~1;
            last_seen_x = max_x / 16;
            last_seen_y = max_y / 16;
            guards[n].wait = 1;
        }
    } else
        guards[n].spotted = 0;
    if (guard_saw_max) {
        if (made_noise && guards[n].stun < 24) {
            disguised = 0;
            compute_room_distances(cur_room, 240);
        }
        if (++guards[n].heard > max_heard && guards[n].stun < 999)
            max_heard = guards[n].heard;
    } else
        guards[n].heard = 0;
    if (guards[n].room == cur_room) {
        if (guards[n].stun < 999) guard_in_room = 1;
        if (guard_saw_max || guards[n].firing || !alarm_timer || goal_room != cur_room)
            guards[n].flags &= ~8;
        else if (!(frame_count & 3))
            guards[n].flags |= 8;
    }
    if ((rooms[guards[n].room].flags & 0x10) && (n & 3))
        guards[n].stun += 2;
    if (guards[n].stun && --guards[n].stun > 32) {
        guards[n].spotted = 0;
        guards[n].flags |= 4;
        return;
    }
    if (guards[n].room == goal_room && goal_room == cur_room && alarm_timer && !(frame_count & 7)) {
        guards[n].flags |= 4;
        if (last_seen_x && line_of_sight(guards[n].x, guards[n].y, last_seen_x * 16 + 8, last_seen_y * 16 + 8) + (see_bits & 1) >= 2)
            guards[n].flags &= ~4;
    }
    if (guards[n].spotted) {
        dx = max_x - guards[n].x;
        dy = max_y - guards[n].y;
        dir = direction8_coarse(dx, dy);
        if (dir) guards[n].dir = dir;
        if (guards[n].room == cur_room && guards[n].spotted > (5 - difficulty) * 7 - 6) {
            compute_room_distances(cur_room, 240);
            room_noise[cur_room] = 0;
            if (!guards[n].firing) guards[n].firing += 4;
            guards[n].wait = 9;
            guards[n].flags &= ~4;
        }
    }
    room = room_map[cx][cy];
    if (!room) {
        guards[n].flags &= ~0x80;
gone:
        guards_left++;
        return;
    }
    if (rooms[room].flags & 8) {
        rooms[room].flags &= ~8;
        if (!alarm_timer)
            compute_room_distances(room, 240);
        else
            alarm_timer = 240;
    }
    chase = guards[n].room == goal_room && alarm_timer;
    if (guards[n].tx == -1 && !guards[n].wait && !guards[n].firing) {
        ok = 0;
        tries = 0;
        if (chase) {
            mindist = 999;
            destx = -1;
            do {
                dx = rooms[room].x + random(rooms[room].w);
                dy = rooms[room].y + random(rooms[room].h);
                item = building[dx][dy];
                dist = abs(dx - last_seen_x) + abs(dy - last_seen_y);
                dist += abs(dx - cx) + abs(dy - cy);
                if (item == -1 && dist < mindist &&
                    line_of_sight(dx * 16 + 8, dy * 16 + 8, last_seen_x * 16 + 8, last_seen_y * 16 + 8) + (see_bits & 1) < 2) {
                    destx = dx;
                    desty = dy;
                    mindist = dist;
                }
            } while (++tries < 16 || (tries < 32 && destx == -1));
        } else {
            do {
                destx = rooms[room].x + random(rooms[room].w);
                desty = rooms[room].y + random(rooms[room].h);
                item = building[destx][desty];
                if (item != -1 && (obj_types[item & 0x3f].flags & 0x21c)) ok = 1;
                if (ok) break;
            } while (++tries < room_types[rooms[room].type].value - alert_level / 16 - violence * 2);
            if (!ok || (alarm_timer && room != goal_room) || (rooms[room].flags & 0x10)) {
                wayout = guard_choose_goal(room, n);
                find_door(room, wayout, &destx, &desty);
                guards[n].flags |= 1;
            }
            if (!ok && guard_reserve_check(n) == 2 && guards[n].room == post_room && !alarm_timer) {
                destx = rooms[room].x + random(rooms[room].w);
                desty = rooms[room].y + random(rooms[room].h);
                guards[n].flags &= ~1;
            }
        }
        if (destx == -1) {
            destx = cx;
            desty = cy;
        }
        guard_plan_path(n, room, cx, cy, destx, desty);
        if (!guard_paths[n][cx][cy] && guards[n].room != cur_room) {
            guards[n].flags &= ~0x80;
            goto gone;
        }
        guards[n].tx = destx;
        guards[n].ty = desty;
        guards[n].room = room;
    }
    if (!guards[n].stun) {
        for (i = 0; i < 16; i++) {
            if (projectiles[i].type != -1 && projectiles[i].timer == -9998 &&
                abs(projectiles[i].x - guards[n].x) + abs(projectiles[i].y - guards[n].y) < 24 &&
                room_map[projectiles[i].x / 16][projectiles[i].y / 16] == guards[n].room) {
                projectiles[i].timer = -63;
                break;
            }
        }
    }
    if (!guards[n].wait && !guards[n].firing) {
        here = guard_paths[n][cx][cy];
        minvals = 999;
        dir = 0;
        for (i = 0; i <= 8; i++) {
            nvals = guard_paths[n][dir_dx[i] + cx][dir_dy[i] + cy];
            if (nvals && (here - 1 == nvals || (!here && nvals < minvals)) && (!dir || (i & 1))) {
                dir = i;
                minvals = nvals;
            }
        }
        sx = (dir_dx[dir] + cx) * 16 + 8;
        sy = (dir_dy[dir] + cy) * 16 + 8;
        dx = (sx - guards[n].x) / 2;
        dy = (sy - guards[n].y) / 2;
        dir = dir_from_sign[sign(dx) + 1][sign(dy) + 1];
        if (dir) {
            if (guards[n].dir == dir) {
                if (guards[n].flags & 4) {
                    guards[n].x += dir_dx[dir];
                    guards[n].y += dir_dy[dir];
                } else {
                    guards[n].x += step_dx[dir];
                    guards[n].y += step_dy[dir];
                }
            } else {
                if (((dir - guards[n].dir) & 7) < 4)
                    guards[n].dir++;
                else
                    guards[n].dir--;
                guards[n].dir = ((guards[n].dir - 1) & 7) + 1;
                if (guards[n].dir != dir) guards[n].flags &= ~4;
            }
        }
        guards[n].anim = ++guards[n].anim & 3;
        if (abs(dx) < 2 && abs(dy) < 2) {
            dx = guards[n].tx - cx;
            dy = guards[n].ty - cy;
            dir = dir_from_sign[sign(dx) + 1][sign(dy) + 1];
            if (dir)
                guards[n].dir = dir;
            else
                guards[n].dir = (building[cx][cy] & 3) * 2 + 1;
            if (chase) {
                guards[n].tx = -1;
                dx = last_seen_x * 16 - guards[n].x;
                dy = last_seen_y * 16 - guards[n].y;
                dir = 0;
                if (abs(dx) < 12 || abs(dy) < 12 || abs(abs(dx) - abs(dy)) < 12) {
                    dir = direction8_coarse(dx, dy);
                    dist = approx_distance(dx, dy);
                    if (dist > 32 && dist < 112 && frame_count - last_grenade > (5 - difficulty) * 8) {
                        grenade_menu(guards[n].x, guards[n].y, dir, (dist + 16) / 32, 0x80);
                        last_grenade = frame_count;
                    }
                }
                guards[n].wait = random(8) + (4 - difficulty) * 4;
            } else {
                guards[n].wait = (4 - difficulty) * 6 + random(8);
                guards[n].anim = 0;
                item = building[guards[n].tx][guards[n].ty];
                if (item != -1 && guards[n].tx != -1) {
                    item &= 0x3f;
                    if (obj_types[item].flags & 2) {
                        if (guards[n].room == cur_room && !(obj_types[item].flags & 0x10))
                            doors_open++;
                        building[guards[n].tx][guards[n].ty] |= 0x80;
                        reveal_rooms(guards[n].tx, guards[n].ty);
                        if (!(guards[n].flags & 1)) guards[n].wait += 18;
                    }
                }
            }
            if (guards[n].flags & 1) {
                if (orig_difficulty > 1 && alarm_timer && !last_at_goal &&
                    room_map[dir_dx[guards[n].dir] + cx][dir_dy[guards[n].dir] + cy] == goal_room) {
                    guards[n].wait = random(3) * 5 + 9;
                    grenade_menu(guards[n].x, guards[n].y, guards[n].dir, guards[n].wait / 5, 0x82);
                }
                guards[n].dir = ((guards[n].dir + 3) & 7) + 1;
            }
        }
    }
    if (guards[n].wait && !--guards[n].wait) {
        item = building[guards[n].tx][guards[n].ty];
        if (item != -1 && guards[n].tx != -1) {
            item &= 0x3f;
            if (obj_types[item].flags & 2) {
                if (guards[n].room == cur_room && !(obj_types[item].flags & 0x10))
                    doors_open--;
                building[guards[n].tx][guards[n].ty] &= 0x7f;
                reveal_rooms(guards[n].tx, guards[n].ty);
            }
        }
        guards[n].tx = -1;
        if (guards[n].flags & 1) {
            for (i = 0; i < 4; i++) {
                dx = door_dx[i] + cx;
                dy = door_dy[i] + cy;
                if (guards[n].room != room_map[dx][dy]) {
                    guards[n].x = dx * 16 + 8;
                    guards[n].y = dy * 16 + 8;
                    guards[n].room = room_map[dx][dy];
                    guards[n].dir = i * 2 + 1;
                    guards[n].spotted = 10;
                    break;
                }
            }
            guards[n].flags &= ~1;
        }
    }
}

/* Pick the room a guard heads for next: the neighbour of room with the
 * lowest guard_next_room() score. */
guard_choose_goal(room, guard)
int room, guard;
{
    int mode, mindist, i, next;

    mindist = 9999;
    mode = guard_reserve_check(guard);
    for (i = 0; i < n_doors; i++) {
        if (doors[i].room_a == room && guard_next_room(doors[i].room_b, mode) < mindist && doors[i].room_b) {
            next = doors[i].room_b;
            mindist = guard_next_room(next, mode);
        }
        if (doors[i].room_b == room && guard_next_room(doors[i].room_a, mode) < mindist && doors[i].room_a) {
            next = doors[i].room_a;
            mindist = guard_next_room(next, mode);
        }
    }
    room = next;
    room_noise[room] = frame_count + 1;
    return room;
}

/* Score of a room for a guard: 0 least recently visited, 1 towards the
 * goal, -1/2 towards Max (or the goal while the alarm runs). */
guard_next_room(room, mode)
int room, mode;
{
    switch (mode) {
    case 0:
        return room_noise[room];
    case 1:
        if (goal_room > 0) return rooms[room].dist * 4 + random(7);
        return room_noise[room];
    case -1:
    case 2:
        if (alarm_timer) return rooms[room].dist * 4 + random(7);
        return room_dist[room] * 4 + random(7);
    }
}

/* Distances (in doors) of every room from a room, for the guards to home in;
 * the noise also raises the alarm timer. */
compute_room_distances(room, noise)
int room, noise;
{
    int a, b, done, i;

    if (noise) disguised = 0;
    noise = noise / 4 * (difficulty + 4);
    goal_room = room;
    if (tac_mode == 2) {
        if (room == -1) goal_room = start_room;
        room = start_room;
    }
    alarm_timer = clamp(alarm_timer, noise, 9999);
    if (room == room_none) return;
    for (i = 0; i <= n_rooms; i++)
        rooms[i].dist = -1;
    rooms[room].dist = 0;
    do {
        done = 1;
        for (i = 0; i < n_doors; i++) {
            a = doors[i].room_a;
            b = doors[i].room_b;
            if (a || b) {
                if (rooms[b].dist != -1 && (rooms[a].dist == -1 || rooms[b].dist + 1 < rooms[a].dist)) {
                    rooms[a].dist = rooms[b].dist + 1;
                    done = 0;
                }
                if (rooms[a].dist != -1 && (rooms[b].dist == -1 || rooms[a].dist + 1 < rooms[b].dist)) {
                    rooms[b].dist = rooms[a].dist + 1;
                    done = 0;
                }
            }
        }
    } while (!done);
    rooms[0].dist = 999;
}

/* The door between two rooms: the map cell on room b's side. */
find_door(a, b, px, py)
int a, b, *px, *py;
{
    int i;

    for (i = 0; i < n_doors; i++) {
        if (doors[i].room_a == a && doors[i].room_b == b) {
            *px = doors[i].x;
            *py = doors[i].y;
            return 1;
        }
        if (doors[i].room_a == b && doors[i].room_b == a) {
            *px = doors[i].x + door_dx[doors[i].dir];
            *py = doors[i].y + door_dy[doors[i].dir];
            return 1;
        }
    }
    return 0;
}

/* Breadth-first search from (sx, sy) inside a room, marking guard g's path map,
 * until (tx, ty) is reached. */
guard_plan_path(g, room, tx, ty, sx, sy)
int g, room, tx, ty, sx, sy;
{
    int tailv, head_, dn, foundw, cxy;
    int okk[10];
    int cyz, in, us, nxs, ws, nys1, obj1;
    char vw;

    memset(guard_paths[g], 0, 0x500);
    tailv = 0;
    head_ = 0;
    queue_x[0] = sx;
    queue_y[tailv++] = sy;
    obj1 = building[sx][sy] & 0x3f;
    if (obj1 != 0x3f && (obj_types[obj1].flags & 1))
        guard_paths[g][sx][sy] = 0;
    else
        guard_paths[g][sx][sy] = 1;
    foundw = 0;
    do {
        cxy = queue_x[head_];
        cyz = queue_y[head_];
        dn = guard_paths[g][cxy][cyz];
        head_++;
        head_ = (unsigned char)head_;
        for (in = 1; in <= 8; in++) {
            nxs = dir_dx[in] + cxy;
            nys1 = dir_dy[in] + cyz;
            okk[in] = 1;
            if (room_map[nxs][nys1] != room) okk[in] = 0;
            obj1 = building[nxs][nys1] & 0x3f;
            if (obj1 != 0x3f && (obj_types[obj1].flags & 1)) okk[in] = 0;
            if (!dn && !(in & 1)) okk[in] = 0;
        }
        okk[0] = okk[8];
        okk[9] = okk[1];
        for (in = 1; in <= 8; in++) {
            nxs = dir_dx[in] + cxy;
            nys1 = dir_dy[in] + cyz;
            if (!okk[in]) continue;
            if (!(in & 1)) {
                if (!okk[in - 1]) continue;
                if (!okk[in + 1]) continue;
            }
            if (!guard_paths[g][nxs][nys1]) {
                guard_paths[g][nxs][nys1] = dn + 1;
                queue_x[tailv] = nxs;
                queue_y[tailv] = nys1;
                tailv++;
                tailv = (unsigned char)tailv;
                if (nxs == tx && nys1 == ty) foundw = 1;
            }
        }
    } while (!foundw && head_ != tailv);
    if (!guard_paths[g][tx][ty])
        for (in = 0; in < 4; in++) {
            nxs = door_dx[in] + tx;
            nys1 = door_dy[in] + ty;
            if (vw = guard_paths[g][nxs][nys1]) guard_paths[g][tx][ty] = vw;
        }
    return foundw;
}

/* Place guard n somewhere in the building: in a rescue at an outside door,
 * otherwise in a random empty cell (away from Max, or near the start room when
 * the building is on alert). */
spawn_guard(n)
int n;
{
    int triesy, distsz, doorn, mindistk;

    if ((on_alert ? 5 : 3) + difficulty * 2 < n) return;
    if (!guards_left) return;
    mindistk = (4 - difficulty) * 75;
    triesy = 0;
    if (tac_mode == 2) {
        guards[n].x = -1;
        do {
            doorn = random(n_doors);
            if (!doors[doorn].room_a && doors[doorn].room_b && doors[doorn].room_b != start_room) {
                guards[n].room = doors[doorn].room_b;
                guards[n].x = doors[doorn].x + door_dx[doors[doorn].dir];
                guards[n].y = doors[doorn].y + door_dy[doors[doorn].dir];
                guards[n].dir = doors[doorn].dir * 2 + 1;
            }
            if (!doors[doorn].room_b && doors[doorn].room_a && doors[doorn].room_a != start_room) {
                guards[n].room = doors[doorn].room_a;
                guards[n].x = doors[doorn].x;
                guards[n].y = doors[doorn].y;
                guards[n].dir = ((doors[doorn].dir + 2) & 3) * 2 + 1;
            }
        } while (guards[n].x == -1 && ++triesy < 999);
        guards[n].x = guards[n].x * 16 + 8;
        guards[n].y = guards[n].y * 16 + 8;
    } else if (!on_alert || tac_mode) {
        do {
            guards[n].x = random(40) * 16 + 8;
            guards[n].y = random(32) * 16 + 8;
            guards[n].room = room_map[guards[n].x / 16][guards[n].y / 16];
            distsz = abs(guards[n].x - max_x) + abs(guards[n].y - max_y);
        } while (!(guards[n].room && (guards[n].room != cur_room || tac_mode == 3)
                   && building[guards[n].x / 16][guards[n].y / 16] == -1
                   && (guards[n].room == start_room || guards[n].room == post_room || !frame_count || start_room <= 0)
                   && distsz >= mindistk--)
                 && ++triesy < 999);
    } else {
        if (frame_count > 16 && cur_room == start_room) return;
        do {
            guards[n].x = random(40) * 16 + 8;
            guards[n].y = random(32) * 16 + 8;
            guards[n].room = room_map[guards[n].x / 16][guards[n].y / 16];
        } while ((guards[n].room != start_room || building[guards[n].x / 16][guards[n].y / 16] != -1)
                 && ++triesy < 999);
    }
    if (triesy < 999) {
        guards_left--;
        guards[n].flags = 0x80;
        guards[n].tx = -1;
        guards[n].anim = 0;
        guards[n].dir = 1;
        guards[n].firing = 0;
        guards[n].wait = 0;
        guards[n].mode = 0;
        guards[n].spotted = guards[n].heard = guards[n].stun = 0;
    }
}

/* Guard n spots Max: same room, a line of sight, and Max inside his field of
 * view (or the alarm sent him to this room). */
guard_sees_max(n)
int n;
{
    int diffw, dxs2, dys2;

    guard_saw_max = 0;
    if (guards[n].room != cur_room) return 0;
    guard_saw_max = guard_can_see_max(n);
    dxs2 = max_x - guards[n].x;
    dys2 = max_y - guards[n].y;
    diffw = guards[n].dir - direction8_coarse(dxs2, dys2);
    if ((!alarm_timer || guards[n].room != goal_room) && abs(diffw) > 2 && abs(diffw) < 6)
        return 0;
    return guard_saw_max;
}

/* Line of sight from guard n to Max, taking Max's disguise into account. */
guard_can_see_max(n)
int n;
{
    int los;

    los = line_of_sight(guards[n].x, guards[n].y, max_x, max_y);
    if (!los) return 0;
    if (los == 2) return 1;
    if (!(guards[n].flags & 4) && (!sneaking || fire_timer)) return 1;
    if ((guards[n].flags & 4) && sneaking && !fire_timer) return 0;
    if (sneaking && !fire_timer) return see_bits & 2;
    return see_bits & 1;
}

/* Walk the map cells along the line from (x1, y1) to (x2, y2) (pixels):
 * 2 clear, 1 partly blocked (see_bits says which half is visible), 0 a wall. */
line_of_sight(x1, y1, x2, y2)
int x1, y1, x2, y2;
{
    int nyy, diagsy, cxw, padn, cyx, pxsz, pysz, sxsy, sysy, dxsz, dysz, res1, nxv, obj2, yxsz, xyn;

    dxsz = x2 - x1;
    dysz = y2 - y1;
    sxsy = sysy = 1;
    res1 = 2;
    see_bits = 3;
    if (dxsz < 0) {
        dxsz = -dxsz;
        x1 = 639 - x1;
        x2 = 639 - x2;
        sxsy = -1;
    }
    if (dysz < 0) {
        dysz = -dysz;
        y1 = 511 - y1;
        y2 = 511 - y2;
        sysy = -1;
    }
    pxsz = x1;
    pysz = y1;
    diagsy = x2 - x1 + y2 - y1;
    while (dxsz > 100 || dysz > 100) {
        dxsz /= 2;
        dysz /= 2;
    }
    for (;;) {
        nxv = (pxsz & ~15) + 16;
        if (dxsz)
            xyn = (nxv - x1) * dysz / dxsz + y1;
        else {
            nxv = 999;
            xyn = 999;
        }
        nyy = (pysz & ~15) + 16;
        if (dysz)
            yxsz = (nyy - y1) * dxsz / dysz + x1;
        else {
            yxsz = 999;
            nyy = 999;
        }
        if (nxv + xyn < nyy + yxsz) {
            pxsz = nxv;
            pysz = xyn;
        } else {
            pxsz = yxsz;
            pysz = nyy;
        }
        if (pxsz > x2 || pysz > y2) return res1;
        cxw = pxsz >> 4;
        cyx = pysz >> 4;
        if (sxsy < 0) cxw = 39 - cxw;
        if (sysy < 0) cyx = 31 - cyx;
        obj2 = building[cxw][cyx] & 0x3f;
        if (obj2 != 0x3f) {
            if (obj_types[obj2].flags & 0x20) return 0;
            if (obj_types[obj2].flags & 1) {
                res1 = 1;
                if (pxsz - x1 + pysz - y1 < diagsy / 2 + 4) see_bits &= ~1;
                if (pxsz - x1 + pysz - y1 > diagsy / 2 - 4) see_bits &= ~2;
            }
        }
    }
}

/* Whether guard n may be (re)placed now: 1 yes, 2 only at night, -1 never
 * (beyond the building's guard count; he goes back to the reserve), 0 no.
 * The self-assignment generates no code, but makes n * 28 a common
 * subexpression, which MSC keeps in SI as the original does. */
guard_reserve_check(n)
int n;
{
    if (tac_mode == 2) return 1;
    if ((on_alert ? 5 : 3) + difficulty * 2 < n && !guards[n].stun) {
        guards[n].flags = guards[n].flags;
        guards_left++;
        return -1;
    }
    if (alarm_timer && goal_room > 0) {
        if (n < 3) goto none;
        return 1;
    } else {
        if (alert_level / 25 + 3 > n) goto none;
        if (alert_level / 25 + 5 > n) return 1;
        if (is_night && !on_alert) return 2;
    }
none:
    return 0;
}

/* Direction 1-8 from a vector. */
direction8(dx, dy)
int dx, dy;
{
    int steep;

    steep = abs(dx) > abs(dy);
    if (dx > 0) {
        if (dy > 0) {
            if (steep) return 3;
            return 4;
        }
        if (steep) return 2;
        return 1;
    }
    if (dy > 0) {
        if (steep) return 6;
        return 5;
    }
    if (steep) return 7;
    return 8;
}

/* Direction 1-8 from a vector, preferring the four straight directions. */
direction8_coarse(dx, dy)
int dx, dy;
{
    int horizs1, vert;

    horizs1 = abs(dy) * 2 < abs(dx);
    vert = abs(dx) * 2 < abs(dy);
    if (dx > 0) {
        if (dy > 0) {
            if (horizs1) return 3;
            if (vert) return 5;
            return 4;
        }
        if (horizs1) return 3;
        if (vert) return 1;
        return 2;
    }
    if (dy > 0) {
        if (horizs1) return 7;
        if (vert) return 5;
        return 6;
    }
    if (horizs1) return 7;
    if (vert) return 1;
    return 8;
}

/* The items of the equipment room (their strings are emitted here; the tables
 * after the end of equipment_screen). */
char *item_names[16] = {
    "Pistol", "Uzi", "Camera", "Bugs", "Safecracking Tools", "Gas Mask", "Kevlar Vest",
    "Motion Detector", "Fragmentation Grenades", "Gas Grenades", "Stun Grenades",
    "Assorted Grenades", "", "", "", "Floor Plan"
};
struct Nav equip_nav[12] = {
    { 0, 0, 0, 0 }, { 1, 2, 1, 5 }, { 1, 3, 2, 6 }, { 2, 8, 3, 6 },
    { 6, 4, 8, 4 }, { 5, 6, 1, 7 }, { 7, 4, 2, 6 }, { 7, 6, 5, 7 },
    { 3, 9, 8, 4 }, { 8, 10, 9, 4 }, { 9, 11, 10, 4 }, { 10, 11, 11, 4 },
};
struct Pos panel_icons[13] = {
    { 170, 48 }, { 166, 46 }, { 216, 73 }, { 229, 7 }, { 252, 70 }, { 247, 0 }, { 247, 31 },
    { 266, 0 }, { 172, 3 }, { 172, 17 }, { 172, 31 }, { 172, 71 }, { 172, 80 },
};
struct Rect equip_pic_rects[15] = {
    { 162, 25, 189, 38 }, { 162, 71, 220, 93 }, { 272, 101, 296, 122 }, { 258, 41, 264, 45 },
    { 220, 172, 273, 198 }, { 254, 1, 291, 31 }, { 223, 71, 270, 132 }, { 246, 41, 255, 58 },
    { 285, 137, 293, 149 }, { 285, 152, 293, 164 }, { 285, 167, 293, 179 }, { 201, 41, 203, 47 },
    { 188, 41, 198, 55 }, { 162, 95, 170, 101 }, { 298, 101, 312, 113 },
};
struct Rect equip_rects[12] = {
    { 0, 0, 0, 0 }, { 2, 15, 62, 39 }, { 2, 54, 62, 72 }, { 2, 88, 62, 105 },
    { 69, 136, 157, 184 }, { 69, 15, 113, 50 }, { 69, 60, 157, 126 }, { 116, 15, 157, 50 },
    { 2, 122, 62, 138 }, { 2, 140, 62, 154 }, { 2, 156, 62, 170 }, { 2, 172, 62, 186 },
};

/* The equipment room (equip2.pic): pick up to five items with the cursor keys
 * or the joystick, Enter/Space to take or put back, Esc when done.  With
 * interactive == 0 only the item images are loaded. */
equipment_screen(interactive)
int interactive;
{
    int jxn, jyn, iy, keyz, prevw, leftz, sel2;

    drv_begin_image_grab();
    load_picture_swapped("equip2.pic", 3);
    for (iy = 0; iy < 15; iy++)
        equip_images[iy] = drv_get_image(3, equip_pic_rects[iy].x0, equip_pic_rects[iy].y0,
                                         equip_pic_rects[iy].x1 - equip_pic_rects[iy].x0 + 1,
                                         equip_pic_rects[iy].y1 - equip_pic_rects[iy].y0 + 1);
    drv_end_image_grab();
    drv_set_color_map(tac_colormap, tac_colormap);
    for (iy = 0; iy < 13; iy++)
        panel_icons[iy].x += 6;
    ammo = 6;
    clips = 3;
    rooms[0].flags |= 2;
    draw_room(180, 100, 3);
    if (!interactive) {
        gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
        return;
    }
    play_sound(39);
    leftz = 5;
    equipment = 1;
    sel2 = 1;
    draw_equipment_panel();
    do {
        drv_recolor_rect(g_gfx, equip_rects[sel2].x0, equip_rects[sel2].y0,
                         equip_rects[sel2].x1 - equip_rects[sel2].x0 + 1,
                         equip_rects[sel2].y1 - equip_rects[sel2].y0 + 1, 1, 11);
        wait_retrace(15);
        do {
            keyz = -1;
            if ((options & 0x10) && !kbhit()) {
                keyz = read_joystick(&jxn, &jyn);
                if (joystick_button(0)) keyz = 0x20;
                if (joystick_button(1)) keyz = 0x1b;
            } else
                keyz = get_key();
        } while (keyz == -1);
        prevw = sel2;
        switch (keyz) {
        case 2: case 0x4900:            /* PgUp */
            sel2 = equip_nav[sel2].right;
        case 1: case 0x4800:            /* Up */
            sel2 = equip_nav[sel2].up;
            break;
        case 6: case 0x4f00:            /* End */
            sel2 = equip_nav[sel2].left;
        case 5: case 0x5000:            /* Down */
            sel2 = equip_nav[sel2].down;
            break;
        case 8: case 0x4700:            /* Home */
            sel2 = equip_nav[sel2].up;
        case 7: case 0x4b00:            /* Left */
            sel2 = equip_nav[sel2].left;
            break;
        case 4: case 0x5100:            /* PgDn */
            sel2 = equip_nav[sel2].down;
        case 3: case 0x4d00:            /* Right */
            sel2 = equip_nav[sel2].right;
            break;
        case 0xd: case 0x20:
            if (equipment & ((unsigned)1 << sel2)) {
                equipment &= ~((unsigned)1 << sel2);
                drv_copy_rect(back_page, equip_rects[sel2].x0, equip_rects[sel2].y0,
                              equip_rects[sel2].x1 - equip_rects[sel2].x0 + 1,
                              equip_rects[sel2].y1 - equip_rects[sel2].y0 + 1,
                              g_gfx, equip_rects[sel2].x0, equip_rects[sel2].y0);
                leftz++;
            } else if (leftz) {
                equipment |= 1 << sel2;
                drv_copy_rect(work_page, equip_rects[sel2].x0, equip_rects[sel2].y0,
                              equip_rects[sel2].x1 - equip_rects[sel2].x0 + 1,
                              equip_rects[sel2].y1 - equip_rects[sel2].y0 + 1,
                              g_gfx, equip_rects[sel2].x0, equip_rects[sel2].y0);
                leftz--;
            }
            equipment = ((equipment & 2) == 0) + (equipment & 0x7ffe);
            bugs_left = (equipment & 8) ? 10 : 0;
            for (iy = 0; iy < 3; iy++)
                grenades[iy] = 0;
            if (equipment & 0x800) {
                grenades[0] = 2;
                grenades[1] = 2;
                grenades[2] = 2;
            }
            for (iy = 0; iy < 3; iy++)
                if (equipment & (0x100 << iy)) grenades[iy] = 8;
            draw_equipment_panel();
            break;
        case 0x1b:
            leftz = -1;
            break;
        }
        drv_copy_rect((equipment & (1 << prevw)) ? work_page : back_page,
                      equip_rects[prevw].x0, equip_rects[prevw].y0,
                      equip_rects[prevw].x1 - equip_rects[prevw].x0 + 1,
                      equip_rects[prevw].y1 - equip_rects[prevw].y0 + 1,
                      g_gfx, equip_rects[prevw].x0, equip_rects[prevw].y0);
    } while (leftz != -1);
    play_sound(1);
}

/* Film left in the camera. */
draw_film_count()
{
    int a, b, c;

    gfx_fill_rect(g_gfx, 222, 86, 15, 9, 0);
    msg_buf[0] = 0;
    strcat(msg_buf, itoa(36 - photos_taken, film_buf, 10));
    draw_text_transparent(msg_buf, 224, 87, 10);
}

redraw_equipment_panel()
{
    draw_equipment_panel();
}

/* The equipment panel at the top right: items carried, rounds and clips,
 * bugs, grenades (the selected kind highlighted) and the password so far. */
draw_equipment_panel()
{
    int i, j;

    drv_copy_rect(back_page, 176, 0, 144, 100, g_gfx, 176, 0);
    for (j = 0; grenades[cur_grenade] <= 0 && ++j < 4; )
        if (++cur_grenade == 3) cur_grenade = 0;
    if (j < 4)
        gfx_fill_rect(g_gfx, panel_icons[cur_grenade + 8].x - 1, panel_icons[cur_grenade + 8].y - 1,
                      grenades[cur_grenade] * 6 + 8, 15, 9);
    for (i = 7; i >= 0; i--)
        if ((equipment & (1 << i)) && i != 3)
            gate_thunk_b(g_gfx, panel_icons[i].x, panel_icons[i].y, equip_images[i]);
    if (equipment & 4) draw_film_count();
    for (i = 0; i < ammo; i++)
        gate_thunk_b(g_gfx, i * 5 + panel_icons[11].x, panel_icons[11].y, equip_images[11]);
    for (i = 0; i < clips; i++)
        gate_thunk_b(g_gfx, i * 13 + panel_icons[12].x, panel_icons[12].y, equip_images[12]);
    for (i = 0; i < bugs_left; i++)
        gate_thunk_b(g_gfx, (i & 1) * 9 + panel_icons[3].x, i / 2 * 7 + panel_icons[3].y, equip_images[3]);
    for (i = 0; i < wounds; i++)
        gate_thunk_b(g_gfx, i * 6 + 260, (i & 1) * 10 + i + 63, equip_images[13]);
    for (j = 0; j < 3; j++)
        for (i = 0; i < grenades[j]; i++)
            gate_thunk_b(g_gfx, i * 6 + panel_icons[j + 8].x, panel_icons[j + 8].y, equip_images[j + 8]);
    for (i = 0; i < strlen(password); i++)
        if (password_shown[i] != '.') {
            gfx_fill_rect(g_gfx, 248, 88, 64, 9, 10);
            draw_rect_outline(248, 88, 64, 9, 2);
            draw_text_transparent(password_shown, 250, 89, 5);
            break;
        }
}
