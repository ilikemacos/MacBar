namespace SpriteKind {
    export const Enemy = SpriteKind.create()
    export const Gold = SpriteKind.create()
}

const TILE = 8
const COLS = 20
const ROWS = 15

const EMPTY = 0
const SOLID = 1
const BRICK = 2
const LADDER = 3
const HOLE = 4

const HOLE_TICKS = 24
const TICK_MS = 120

const brickTile = img`
    4 4 4 4 4 4 4 4
    4 4 4 4 4 4 4 4
    4 4 4 4 4 4 4 4
    f f f f f f f f
    4 4 4 4 4 4 4 4
    4 4 4 4 4 4 4 4
    4 4 4 4 4 4 4 4
    f f f f f f f f
`

const solidTile = img`
    d d d d d d d d
    d f f f f f f d
    d f d d d d f d
    d f d d d d f d
    d f d d d d f d
    d f d d d d f d
    d f f f f f f d
    d d d d d d d d
`

const ladderTile = img`
    . d . . . . d .
    . d . . . . d .
    . d d d d d d .
    . d . . . . d .
    . d d d d d d .
    . d . . . . d .
    . d d d d d d .
    . d . . . . d .
`

const emptyTile = img`
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
`

const playerImg = img`
    . . 1 1 1 1 . .
    . . 1 f 1 f . .
    . . 1 1 1 1 . .
    . 8 8 8 8 8 8 .
    8 8 8 8 8 8 8 8
    . 8 8 . . 8 8 .
    . 8 8 . . 8 8 .
    . f f . . f f .
`

const enemyImg = img`
    . . 1 1 1 1 . .
    . . 1 f 1 f . .
    . . 1 1 1 1 . .
    . 2 2 2 2 2 2 .
    2 2 2 2 2 2 2 2
    . 2 2 . . 2 2 .
    . 2 2 . . 2 2 .
    . f f . . f f .
`

const goldImg = img`
    . . . 5 5 . . .
    . . 5 5 5 5 . .
    . 5 5 5 5 5 5 .
    5 5 5 4 4 5 5 5
    5 5 5 4 4 5 5 5
    . 5 5 5 5 5 5 .
    . . 5 5 5 5 . .
    . . . 5 5 . . .
`

const LEVEL = [
    "#..................#",
    "#BBHBBBBBBBBBBBBHBB#",
    "#....G........G....#",
    "#BBBBBHBBBBBBHBBBBB#",
    "#.........G....E...#",
    "#BBHBBBBBBBBBBBBHBB#",
    "#...G..........G...#",
    "#BBBBBBBBHBBBBBBHBB#",
    "#.......G....E.....#",
    "#BBHBBBBBBBBBHBBBBB#",
    "#....G......G......#",
    "#BBBBBHBBBBBBBBBHBB#",
    "#.P......G.......G.#",
    "####################",
    "####################",
]

let grid: number[][] = []
let goldSpawns: number[][] = []
let enemySpawns: number[][] = []
let playerSpawnCol = 1
let playerSpawnRow = 1

function parseLevel() {
    for (let r = 0; r < LEVEL.length; r++) {
        let row: number[] = []
        for (let c = 0; c < LEVEL[r].length; c++) {
            let ch = LEVEL[r].charAt(c)
            let val = EMPTY
            if (ch == "#") val = SOLID
            else if (ch == "B") val = BRICK
            else if (ch == "H") val = LADDER
            else if (ch == "G") goldSpawns.push([c, r])
            else if (ch == "E") enemySpawns.push([c, r])
            else if (ch == "P") { playerSpawnCol = c; playerSpawnRow = r }
            row.push(val)
        }
        grid.push(row)
    }
}
parseLevel()

function tileArt(t: number): Image {
    if (t == SOLID) return solidTile
    if (t == BRICK) return brickTile
    if (t == LADDER) return ladderTile
    return emptyTile
}

function redrawBackground() {
    let bg = image.create(COLS * TILE, ROWS * TILE)
    for (let r = 0; r < ROWS; r++) {
        for (let c = 0; c < COLS; c++) {
            bg.drawImage(tileArt(grid[r][c]), c * TILE, r * TILE)
        }
    }
    scene.setBackgroundImage(bg)
}
redrawBackground()

function isBlocking(col: number, row: number): boolean {
    if (col < 0 || col >= COLS || row < 0 || row >= ROWS) return true
    let t = grid[row][col]
    return t == SOLID || t == BRICK
}

function isLadderAt(col: number, row: number): boolean {
    if (col < 0 || col >= COLS || row < 0 || row >= ROWS) return false
    return grid[row][col] == LADDER
}

function isSupported(col: number, row: number): boolean {
    if (grid[row][col] == LADDER) return true
    if (isBlocking(col, row + 1)) return true
    return isLadderAt(col, row + 1)
}

let goldRemaining = 0
for (let g of goldSpawns) {
    let s = sprites.create(goldImg, SpriteKind.Gold)
    s.x = g[0] * TILE + TILE / 2
    s.y = g[1] * TILE + TILE / 2
    goldRemaining += 1
}

let player = sprites.create(playerImg, SpriteKind.Player)
player.x = playerSpawnCol * TILE + TILE / 2
player.y = playerSpawnRow * TILE + TILE / 2
let facing = 1

function respawnPlayer() {
    player.x = playerSpawnCol * TILE + TILE / 2
    player.y = playerSpawnRow * TILE + TILE / 2
}

function loseLife() {
    info.changeLifeBy(-1)
    respawnPlayer()
}

const ENEMY_SPEED = 20

let enemies: Sprite[] = []
let enemyHomeCol: number[] = []
let enemyHomeRow: number[] = []
let enemyDir: number[] = []
let enemyWaitTicks: number[] = []
for (let e of enemySpawns) {
    let s = sprites.create(enemyImg, SpriteKind.Enemy)
    s.x = e[0] * TILE + TILE / 2
    s.y = e[1] * TILE + TILE / 2
    enemies.push(s)
    enemyHomeCol.push(e[0])
    enemyHomeRow.push(e[1])
    enemyDir.push(Math.random() < 0.5 ? -1 : 1)
    enemyWaitTicks.push(0)
}

let holeCol: number[] = []
let holeRow: number[] = []
let holeTicksLeft: number[] = []

function digAt(col: number, row: number) {
    if (col < 0 || col >= COLS || row < 0 || row >= ROWS) return
    if (grid[row][col] != BRICK) return
    grid[row][col] = HOLE
    holeCol.push(col)
    holeRow.push(row)
    holeTicksLeft.push(HOLE_TICKS)
    redrawBackground()
}

controller.A.onEvent(ControllerButtonEvent.Pressed, function () {
    let col = Math.floor(player.x / TILE)
    let row = Math.floor(player.y / TILE)
    digAt(col + facing, row + 1)
})

function updateHoles() {
    let changed = false
    for (let i = holeTicksLeft.length - 1; i >= 0; i--) {
        holeTicksLeft[i] -= 1
        if (holeTicksLeft[i] <= 0) {
            let c = holeCol[i]
            let r = holeRow[i]
            grid[r][c] = BRICK
            changed = true

            if (Math.floor(player.x / TILE) == c && Math.floor(player.y / TILE) == r) {
                loseLife()
            }
            for (let k = 0; k < enemies.length; k++) {
                if (Math.floor(enemies[k].x / TILE) == c && Math.floor(enemies[k].y / TILE) == r) {
                    enemies[k].x = enemyHomeCol[k] * TILE + TILE / 2
                    enemies[k].y = enemyHomeRow[k] * TILE + TILE / 2
                    info.changeScoreBy(25)
                }
            }

            holeCol.removeAt(i)
            holeRow.removeAt(i)
            holeTicksLeft.removeAt(i)
        }
    }
    if (changed) redrawBackground()
}

function movePlayer() {
    let col = Math.floor(player.x / TILE)
    let row = Math.floor(player.y / TILE)

    if (!isSupported(col, row)) {
        player.y += TILE
        return
    }

    if (controller.up.isPressed()) {
        if (grid[row][col] == LADDER || isLadderAt(col, row - 1)) {
            player.y -= TILE
        }
    } else if (controller.down.isPressed()) {
        if (grid[row][col] == LADDER || isLadderAt(col, row + 1)) {
            player.y += TILE
        }
    } else if (controller.left.isPressed()) {
        facing = -1
        if (!isBlocking(col - 1, row)) {
            player.x -= TILE
        }
    } else if (controller.right.isPressed()) {
        facing = 1
        if (!isBlocking(col + 1, row)) {
            player.x += TILE
        }
    }
}

function moveEnemy(index: number) {
    let s = enemies[index]
    let col = Math.floor(s.x / TILE)
    let row = Math.floor(s.y / TILE)

    if (!isSupported(col, row)) {
        s.y += TILE
        return
    }

    enemyWaitTicks[index] += 1
    if (enemyWaitTicks[index] >= ENEMY_SPEED) {
        enemyWaitTicks[index] = 0
        let choice = Math.floor(Math.random() * 4)
        if (choice == 0 && (grid[row][col] == LADDER || isLadderAt(col, row - 1))) {
            s.y -= TILE
            return
        } else if (choice == 1 && (grid[row][col] == LADDER || isLadderAt(col, row + 1))) {
            s.y += TILE
            return
        } else {
            enemyDir[index] = Math.floor(Math.random() * 3) - 1
        }
    }

    let dir = enemyDir[index]
    if (dir < 0 && !isBlocking(col - 1, row)) {
        s.x -= TILE
    } else if (dir > 0 && !isBlocking(col + 1, row)) {
        s.x += TILE
    } else if (dir != 0) {
        enemyDir[index] = -dir
    }
}

function checkWin() {
    let row = Math.floor(player.y / TILE)
    if (goldRemaining <= 0 && row == 0) {
        game.over(true)
    }
}

sprites.onOverlap(SpriteKind.Player, SpriteKind.Gold, function (_playerSprite, goldSprite) {
    goldSprite.destroy()
    goldRemaining -= 1
    info.changeScoreBy(50)
})

sprites.onOverlap(SpriteKind.Player, SpriteKind.Enemy, function () {
    loseLife()
})

info.setScore(0)
info.setLife(3)
info.onLifeZero(function () {
    game.over(false)
})

game.splash("Gold Runner", "Grab all the gold, then climb to the top!")

game.onUpdateInterval(TICK_MS, function () {
    movePlayer()
    for (let i = 0; i < enemies.length; i++) moveEnemy(i)
    updateHoles()
    checkWin()
})
