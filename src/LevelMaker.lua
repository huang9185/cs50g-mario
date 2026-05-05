--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- whether we have generated a key or a lock
    local has_key = false
    local has_lock = false

    -- randomize the variety and position in table
    local key_id = math.random(4)
    local key_y = math.random(3, 6)
    local key_x = math.random(width)
    local lock_y = 3
    local lock_x = math.random(width-7)
    while lock_x == key_x do
        lock_x = math.random(width)
    end

    -- obtain the position of last tile in table
    local post_spawn_x = width
    local post_spawn_y = 7

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x ~= width and x ~= key_x and x ~= lock_x then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- generate a key if at right position
            if x == key_x then
                table.insert(objects,
                    GameObject {
                        texture = 'keys',
                        x = (x - 1) * TILE_SIZE,
                        y = (key_y - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = key_id,
                        collidable = true,
                        consumable = true,
                        solid = false,

                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.key_obtained = true
                        end
                    }
                )
                has_key = true
            
            -- generate a lock if at right position
            elseif x == lock_x then
                local object = GameObject {
                    texture = 'locks',
                    x = (x-1) * TILE_SIZE,
                    y = (lock_y-1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = key_id,
                    collidable = true,
                    solid = true,

                    onCollide = function(player, obj)
                        if player.key_obtained then
                            gSounds['powerup-reveal']:play()
                            player.lock_obtained = true

                            -- spawn the flag and pole
                            local singleflag = GameObject {
                                texture = 'flags',
                                x = (post_spawn_x - 1) * TILE_SIZE + 11,
                                y = (post_spawn_y - 1) * TILE_SIZE - 32,
                                width = 16,
                                height = 16,
                                frame = math.random(8)
                            }

                            local pole = GameObject {
                                -- 4 pixels on both right and left are extra
                                texture = 'poles',
                                x = (post_spawn_x - 1) * TILE_SIZE,
                                y = (post_spawn_y - 1) * TILE_SIZE - 48,
                                width = 16,
                                height = 48,
                                frame = math.random(6)
                            }

                            -- spawn an invisible layer for the goal post
                            -- to handle the oncollision function
                            local post = GameObject {
                                texture = 'posts',
                                x = (post_spawn_x - 1) * TILE_SIZE,
                                y = (post_spawn_y - 1) * TILE_SIZE - 48,
                                width = 20,
                                height = 48,
                                frame = 1,
                                consumable = true,

                                onConsume = function(player, object)
                                    gStateMachine:change('play',{
                                        score = player.score,
                                        width = width + 20
                                    })
                                    end
                            }

                            table.insert(objects, pole)
                            table.insert(objects, singleflag)
                            table.insert(objects, post)
                        else
                            gSounds['empty-block']:play()
                        end
                    end
                }
                table.insert(objects, object)
                has_lock = true

            -- chance to generate a pillar
            elseif math.random(8) == 1 and math.abs(x-lock_x) > 2 and x ~= width then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x ~= lock_x and x ~= width then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end