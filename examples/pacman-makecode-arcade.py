# Pac-Man clone for Microsoft MakeCode Arcade
# Target: MakeCode Arcade "Static Python" editor - https://arcade.makecode.com
# Paste this whole file into a new Python project there and press Run/Download.
#
# Controls: D-pad moves Pac-Man. Eat all dots to win, avoid ghosts (unless
# you just ate a power pellet - then ghosts turn blue and can be eaten).

TILE = 8
COLS = 20
ROWS = 15
SPEED = 60          # pixel/sec movement speed
FRIGHT_MS = 6000     # how long ghosts stay frightened after a power pellet

# Maze layout: # wall, . dot, o power pellet, space empty floor, P player start, G ghost start
MAZE = [
    "####################",
    "#........##........#",
    "#.##.###.##.###.##.#",
    "#o##.###.##.###.##o#",
    "#.##.###.##.###.##.#",
    "#..................#",
    "#.####.##G##.####.##",
    "#......##.##.......#",
    "#.####.##.##.####.##",
    "#..................#",
    "#o####.####.####o..#",
    "#.####.####.####...#",
    "#........P.........#",
    "#.####.####.####.###",
    "####################",
]

grid = [list(row) for row in MAZE]

GhostKind = SpriteKind.create()
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]

score = 0
lives = 3
dots_left = 0
frightened = False
frighten_timer = 0

player = None
player_dir = (0, 0)
player_wish = (0, 0)

ghosts = []


def tile_center(col, row):
    return col * TILE + TILE // 2, row * TILE + TILE // 2


def is_wall(col, row):
    if row < 0 or row >= ROWS or col < 0 or col >= COLS:
        return True
    return grid[row][col] == "#"


def sprite_tile(spr):
    return int(spr.x) // TILE, int(spr.y) // TILE


def centered(spr):
    return abs((spr.x - TILE // 2) % TILE) <= 2 and abs((spr.y - TILE // 2) % TILE) <= 2


def snap_to_tile(spr):
    col, row = sprite_tile(spr)
    x, y = tile_center(col, row)
    spr.x = x
    spr.y = y


def draw_background():
    bg = image.create(COLS * TILE, ROWS * TILE)
    bg.fill(9)
    for row in range(ROWS):
        for col in range(COLS):
            ch = grid[row][col]
            x, y = col * TILE, row * TILE
            if ch == "#":
                bg.fill_rect(x, y, TILE, TILE, 8)
            elif ch == ".":
                bg.set_pixel(x + 3, y + 3, 5)
                bg.set_pixel(x + 4, y + 3, 5)
                bg.set_pixel(x + 3, y + 4, 5)
                bg.set_pixel(x + 4, y + 4, 5)
            elif ch == "o":
                bg.fill_rect(x + 2, y + 2, 4, 4, 5)
    scene.set_background_image(bg)


def eat_at(col, row):
    global score, dots_left, frightened, frighten_timer
    ch = grid[row][col]
    if ch == ".":
        grid[row][col] = " "
        dots_left -= 1
        score += 10
        draw_background()
    elif ch == "o":
        grid[row][col] = " "
        score += 50
        frightened = True
        frighten_timer = game.runtime()
        draw_background()
        for g in ghosts:
            g["sprite"].set_image(ghost_frightened_img())
    info.set_score(score)
    if dots_left <= 0:
        game.splash("You win!", "Score: " + str(score))


def player_image():
    return img("""
        . . 5 5 5 5 . .
        . 5 5 5 5 5 5 .
        5 5 5 5 5 5 5 5
        5 5 5 5 5 5 . .
        5 5 5 5 5 5 5 .
        5 5 5 5 5 5 5 5
        . 5 5 5 5 5 5 .
        . . 5 5 5 5 . .
        """)


def ghost_normal_img(color_index):
    if color_index == 2:
        return img("""
            . 2 2 2 2 2 2 .
            2 2 2 2 2 2 2 2
            2 2 2 2 2 2 2 2
            2 2 1 2 2 1 2 2
            2 2 1 2 2 1 2 2
            2 2 2 2 2 2 2 2
            2 2 . 2 2 . 2 2
            2 . . 2 2 . . 2
            """)
    if color_index == 4:
        return img("""
            . 4 4 4 4 4 4 .
            4 4 4 4 4 4 4 4
            4 4 4 4 4 4 4 4
            4 4 1 4 4 1 4 4
            4 4 1 4 4 1 4 4
            4 4 4 4 4 4 4 4
            4 4 . 4 4 . 4 4
            4 . . 4 4 . . 4
            """)
    return img("""
        . 3 3 3 3 3 3 .
        3 3 3 3 3 3 3 3
        3 3 3 3 3 3 3 3
        3 3 1 3 3 1 3 3
        3 3 1 3 3 1 3 3
        3 3 3 3 3 3 3 3
        3 3 . 3 3 . 3 3
        3 . . 3 3 . . 3
        """)


def ghost_frightened_img():
    return img("""
        . 6 6 6 6 6 6 .
        6 6 6 6 6 6 6 6
        6 6 6 6 6 6 6 6
        6 6 1 6 6 1 6 6
        6 6 1 6 6 1 6 6
        6 6 6 6 6 6 6 6
        6 6 . 6 6 . 6 6
        6 . . 6 6 . . 6
        """)


def spawn_player(col, row):
    global player
    x, y = tile_center(col, row)
    player = sprites.create(player_image(), SpriteKind.Player)
    player.set_position(x, y)
    player.z = 10


def spawn_ghost(col, row, color_index):
    x, y = tile_center(col, row)
    spr = sprites.create(ghost_normal_img(color_index), GhostKind)
    spr.set_position(x, y)
    spr.z = 5
    ghosts.append({"sprite": spr, "color": color_index, "dir": (0, -1)})


def find_and_clear(letter):
    spots = []
    for row in range(ROWS):
        for col in range(COLS):
            if grid[row][col] == letter:
                spots.append((col, row))
                grid[row][col] = " "
    return spots


def setup():
    global dots_left
    scene.set_background_color(15)

    player_spots = find_and_clear("P")
    ghost_spots = find_and_clear("G")

    for row in range(ROWS):
        for col in range(COLS):
            if grid[row][col] == ".":
                dots_left += 1

    for col, row in player_spots:
        spawn_player(col, row)

    palette = [2, 4, 3, 2]
    for i, (col, row) in enumerate(ghost_spots):
        spawn_ghost(col, row, palette[i % len(palette)])

    if player is None:
        spawn_player(COLS // 2, ROWS // 2)

    # Make sure there are always a few ghosts, even if the maze only
    # marks one "G" spawn point - extra ones appear on open floor tiles.
    extra_spots = [(2, 5), (17, 5), (2, 9)]
    j = 0
    while len(ghosts) < 3 and j < len(extra_spots):
        col, row = extra_spots[j]
        spawn_ghost(col, row, palette[len(ghosts) % len(palette)])
        j += 1

    info.set_score(0)
    info.set_life(lives)
    draw_background()


def try_turn(spr, wish):
    if wish == (0, 0):
        return None
    if not centered(spr):
        return None
    col, row = sprite_tile(spr)
    nc, nr = col + wish[0], row + wish[1]
    if not is_wall(nc, nr):
        snap_to_tile(spr)
        return wish
    return None


def move_with_walls(spr, direction, speed_px):
    if direction == (0, 0):
        return direction
    col, row = sprite_tile(spr)
    if centered(spr):
        snap_to_tile(spr)
        nc, nr = col + direction[0], row + direction[1]
        if is_wall(nc, nr):
            spr.vx = 0
            spr.vy = 0
            return (0, 0)
    spr.vx = direction[0] * speed_px
    spr.vy = direction[1] * speed_px
    return direction


def on_player_update():
    global player_dir, player_wish
    turned = try_turn(player, player_wish)
    if turned is not None:
        player_dir = turned
    player_dir = move_with_walls(player, player_dir, SPEED)

    col, row = sprite_tile(player)
    if centered(player):
        eat_at(col, row)

    # wrap-around tunnel on left/right edge
    if player.x < 0:
        player.x = (COLS * TILE) - 1
    elif player.x > COLS * TILE:
        player.x = 1


def ghost_choose_direction(g):
    spr = g["sprite"]
    col, row = sprite_tile(spr)
    options = []
    reverse = (-g["dir"][0], -g["dir"][1])
    for d in DIRS:
        nc, nr = col + d[0], row + d[1]
        if not is_wall(nc, nr) and d != reverse:
            options.append(d)
    if len(options) == 0:
        options = [reverse]
    return options[randint(0, len(options) - 1)]


def on_ghost_update():
    global frightened, frighten_timer
    if frightened and game.runtime() - frighten_timer > FRIGHT_MS:
        frightened = False
        for g in ghosts:
            g["sprite"].set_image(ghost_normal_img(g["color"]))

    for g in ghosts:
        spr = g["sprite"]
        if centered(spr):
            g["dir"] = ghost_choose_direction(g)
        g["dir"] = move_with_walls(spr, g["dir"], SPEED - 10)


def on_ghost_hit(player_spr, ghost_spr):
    global lives, frightened
    if frightened:
        for g in ghosts:
            if g["sprite"] == ghost_spr:
                col, row = 1, 1
                x, y = tile_center(col, row)
                ghost_spr.set_position(x, y)
        return
    lives -= 1
    info.set_life(lives)
    if lives <= 0:
        game.game_over(False)
    else:
        x, y = tile_center(COLS // 2, ROWS // 2)
        player.set_position(x, y)


controller.up.on_event(ControllerButtonEvent.PRESSED, lambda: set_wish(0, -1))
controller.down.on_event(ControllerButtonEvent.PRESSED, lambda: set_wish(0, 1))
controller.left.on_event(ControllerButtonEvent.PRESSED, lambda: set_wish(-1, 0))
controller.right.on_event(ControllerButtonEvent.PRESSED, lambda: set_wish(1, 0))


def set_wish(dx, dy):
    global player_wish
    player_wish = (dx, dy)


setup()
sprites.on_overlap(SpriteKind.Player, GhostKind, on_ghost_hit)
game.on_update(on_player_update)
game.on_update(on_ghost_update)
