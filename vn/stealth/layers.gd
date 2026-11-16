extends RefCounted
## Physics layers of the stealth minigame, as bit values.

const WALL := 1    ## full height: blocks movement and sight
const COVER := 2   ## low cover: blocks movement; blocks sight only while the player crouches
const FLOOR := 4   ## ground, platforms, ramps: walkable, and solid to sight
const PLAYER := 8
const GUARD := 16

const SOLID := WALL | COVER | FLOOR
const SIGHT := WALL | FLOOR
