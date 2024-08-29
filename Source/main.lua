-- Import Playdate libraries
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/timer"

local gfx = playdate.graphics


-- Grid dimensions
local gridRows = 3
local gridCols = 5
local grid = {}

-- Square (tile) dimensions
local squareSize = 70
local squareSize2 = 63
local squarePadding = 5
local squarePadding2 = 5

-- Screen dimensions
local screenWidth = 400
local screenHeight = 240

-- Space reserved for the score at the top
local scoreHeight = 30

-- Calculate the starting position of the grid to center it below the score
local gridWidth = gridCols * squareSize + (gridCols - 1) * squarePadding
local gridHeight = gridRows * squareSize2 + (gridRows - 1) * squarePadding2
local startX = (screenWidth - gridWidth) / 2
local startY = scoreHeight + ((screenHeight - scoreHeight) - gridHeight) / 2

-- Score variable
local score = 0
local gameOver = false
local highScore = 0
local highestTile = 0  -- Current game's highest tile
local allTimeHighestTile = 0  -- All-time highest tile
 -- Variable to track the highest tile achieved


local grid = {}
local tiles = {}
local animationSpeed =0.1  -- Adjust the speed of the animation

local gameState = "opening"  -- Can be "opening", "playing", or "gameOver"
local c_major_scale = {261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99, 880.00}
local c_minor_scale = {
    261.63, -- C4
    293.66, -- D4
    311.13, -- Eb4
    349.23, -- F4
    392.00, -- G4
    415.30, -- Ab4
    466.16, -- Bb4
    523.25, -- C5
    587.33, -- D5
    622.25, -- Eb5
    698.46, -- F5
    783.99, -- G5
    830.61  -- Ab5
}
local a_major_scale = {
    220.00,  -- A3
    246.94,  -- B3
    277.18,  -- C#4
    293.66,  -- D4
    329.63,  -- E4
    369.99,  -- F#4
    415.30,  -- G#4
    440.00,  -- A4
    493.88,  -- B4
    554.37,  -- C#5
    587.33,  -- D5
    659.25,  -- E5
    739.99   -- F#5
}
local chromatic_scale = {
    220.00,  -- A3
    233.08,  -- A#3/Bb3
    246.94,  -- B3
    261.63,  -- C4
    277.18,  -- C#4/Db4
    293.66,  -- D4
    311.13,  -- D#4/Eb4
    329.63,  -- E4
    349.23,  -- F4
    369.99,  -- F#4/Gb4
    392.00,  -- G4
    415.30,  -- G#4/Ab4
    440.00,  -- A4
    466.16,  -- A#4/Bb4
    493.88,  -- B4
    523.25,  -- C5
    554.37,  -- C#5/Db5
    587.33,  -- D5
    622.25,  -- D#5/Eb5
    659.25,  -- E5
    698.46,  -- F5
    739.99,  -- F#5/Gb5
    783.99,  -- G5
    830.61   -- G#5/Ab5
}

local d_blues_scale_13 = {
    146.83,  -- D3
    174.61,  -- F3
    196.00,  -- G3
    207.65,  -- G#3
    220.00,  -- A3
    261.63,  -- C4
    293.66,  -- D4
    349.23,  -- F4
    392.00,  -- G4
    415.30,  -- G#4
    440.00,  -- A4
    523.25,  -- C5
    587.33   -- D5
}

local d_blues_scale_15 = {
    146.83,  -- D3
    174.61,  -- F3
    196.00,  -- G3
    207.65,  -- G#3
    220.00,  -- A3
    261.63,  -- C4
    293.66,  -- D4
    349.23,  -- F4
    392.00,  -- G4
    415.30,  -- G#4
    440.00,  -- A4
    523.25,  -- C5
    587.33,  -- D5
    698.46,  -- F5
    783.99   -- G5
}
local the_scale = d_blues_scale_15

local scales = {"Cmaj", "Amaj", "Blues", "Cmin", "Dmaj"}
local selected_index = 3  -- Default selection is "Blues" (index 3)
local scale_mapping = {c_major_scale, a_major_scale, d_blues_scale_13, c_minor_scale, d_blues_scale_15}
local synth = playdate.sound.synth.new(playdate.sound.kWaveSine)
local current_note_index = 1
local melody_timer = nil

-- Function to draw the opening screen
function drawOpeningScreen()
    -- Clear screen and set initial drawing parameters
    gfx.clear(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)

    -- Draw central rounded rectangle and title
    gfx.fillRoundRect(screenWidth / 2 - 35, screenHeight / 2 - 119, 70, 28, 8)
    gfx.fillCircleAtPoint(screenWidth / 2 - 35, screenHeight / 2 + 88, 15)
    local largeFont = gfx.getSystemFont("bold")
    gfx.setFont(largeFont)
    playdate.graphics.setImageDrawMode("fillWhite")
    gfx.drawTextAligned("SumFib", screenWidth / 2, screenHeight / 2 - 115, kTextAlignment.center)
    gfx.drawTextAligned("A", screenWidth / 2 - 35, screenHeight / 2 + 80, kTextAlignment.center)

    -- Reset image draw mode to default
    playdate.graphics.setImageDrawMode("copy")

    -- Draw high score and highest tile achieved
    gfx.drawTextAligned("High Score: " .. tostring(highScore), screenWidth / 2, screenHeight / 2, kTextAlignment.center)
    gfx.drawTextAligned("All-Time Highest Tile: " .. tostring(allTimeHighestTile), screenWidth / 2, screenHeight / 2 + 40, kTextAlignment.center)

    -- Draw "to Start" prompt and 'A' button indicator
    gfx.drawTextAligned("to Start", screenWidth / 2 + 15, screenHeight / 2 + 80, kTextAlignment.center)
    
    

    -- Draw title aligned to the right with padding
    local titleX, titleY = screenWidth - 60, 20
    gfx.drawText("Pisano", titleX, titleY)
    gfx.drawText("Period", titleX, titleY + 20)

    -- Draw the scale selection menu justified to the right
    local menuX, menuY = titleX, 70
    for i, scale in ipairs(scales) do
        local y_position = menuY + (i - 1) * 20
        if i == selected_index then
            gfx.setFont(largeFont)  -- Bold font for selected option
            gfx.drawText("* " .. scale, menuX, y_position)
        else
            gfx.setFont(gfx.getSystemFont())  -- Regular font for non-selected options
            gfx.drawText(scale, menuX + 10, y_position)
        end
    end

    -- Call additional function if necessary
    fibRect()
end


function fibRect()
    local xOff = screenWidth / 2 - 10  -- Combined xOff calculation

    -- Draw Fibonacci-inspired rectangles
    gfx.fillRoundRect(xOff, screenHeight / 2 - 30, 5, 5, 0)
    gfx.fillRoundRect(xOff, screenHeight / 2 - 36, 5, 5, 0)
    gfx.fillRoundRect(xOff - 12, screenHeight / 2 - 36, 11, 11, 1)
    gfx.fillRoundRect(xOff - 12, screenHeight / 2 - 55, 17, 17, 1)
    gfx.fillRoundRect(xOff + 6, screenHeight / 2 - 55, 30, 30, 1)
end

-- Function to play the next note in the melody
function play_next_note()
    if melody_timer then
        melody_timer:remove()  -- Remove the previous timer to stop any ongoing playback
    end
    synth:playNote(melody[current_note_index], 1.0)  -- Play the current note
    current_note_index += 1
    if current_note_index > #melody then
        current_note_index = 1  -- Loop back to the start
    end
    local delay1 = 300 + 100 * (current_note_index % 2)
    melody_timer = playdate.timer.performAfterDelay(delay1, play_next_note)  -- Continue playing the melody
end


function startMusic()
    if not synth then
        synth = playdate.sound.synth.new(playdate.sound.kWaveSine)
    end
    the_scale = scale_mapping[selected_index]  -- Set the selected scale (default is Blues)
    local pisano_period = calculate_pisano_period(#the_scale)
    local fib_mod_sequence = generate_fibonacci_modulo_sequence(#the_scale, pisano_period)
    melody = map_to_scale(fib_mod_sequence, the_scale)
    current_note_index = 1  -- Reset the note index
    play_next_note()  -- Start playing the melody
end



function saveAllTimeHighestTile()
    playdate.datastore.write({allTimeHighestTile = allTimeHighestTile}, "highestTile")
end

function loadAllTimeHighestTile()
    local data = playdate.datastore.read("highestTile")
    if data and data.allTimeHighestTile then
        allTimeHighestTile = data.allTimeHighestTile
    else
        allTimeHighestTile = 0
    end
end

function updateTilePositions()
    local allTilesReachedTarget = true

    for row = 1, gridRows do
        for col = 1, gridCols do
            local tile = tiles[row][col]
            if tile then  -- Ensure the tile exists
                -- Check if the tile's x position needs to be updated
                if tile.x ~= tile.targetX then
                    allTilesReachedTarget = false
                    if tile.x < tile.targetX then
                        tile.x = math.min(tile.x + animationSpeed, tile.targetX)
                    elseif tile.x > tile.targetX then
                        tile.x = math.max(tile.x - animationSpeed, tile.targetX)
                    end
                end

                -- Check if the tile's y position needs to be updated
                if tile.y ~= tile.targetY then
                    allTilesReachedTarget = false
                    if tile.y < tile.targetY then
                        tile.y = math.min(tile.y + animationSpeed, tile.targetY)
                    elseif tile.y > tile.targetY then
                        tile.y = math.max(tile.y - animationSpeed, tile.targetY)
                    end
                end
            end
        end
    end

    return allTilesReachedTarget
end



function initializeTiles()
    for row = 1, gridRows do
        tiles[row] = {}
        for col = 1, gridCols do
            tiles[row][col] = {
                value = grid[row][col], -- The value of the tile (e.g., 1, 2, etc.)
                x = col, -- Current x position (column)
                y = row, -- Current y position (row)
                targetX = col, -- Target x position
                targetY = row, -- Target y position
            }
        end
    end
end

-- Fibonacci check function
function isFibonacciNumber(n)
    if n == 1 or n == 2 then
        return true
    end
    
    local a, b = 1, 2
    while b < n do
        a, b = b, a + b
    end
    
    return b == n
end

-- Function to check if two numbers are consecutive Fibonacci numbers
function isConsecutiveFibonacci(a, b)
    -- Ensure both a and b are not nil
    if a == nil or b == nil then
        return false
    end

    local sum = a + b
    return isFibonacciNumber(sum)
end


function loadHighScore()
    
    local data = playdate.datastore.read("highscore")
    if data then
        highScore = data.highScore
    else
        highScore = 0
    end
end

function saveHighScore()
    playdate.datastore.write({highScore = highScore}, "highscore")

end





function initializeGrid()
    for row = 1, gridRows do
        grid[row] = {}
        tiles[row] = {}  -- Initialize the tiles row
        for col = 1, gridCols do
            grid[row][col] = 0  -- Initialize grid with zeros
            tiles[row][col] = {
                value = grid[row][col],  -- The value of the tile (0 initially)
                x = col,  -- Current x position (column)
                y = row,  -- Current y position (row)
                targetX = col,  -- Target x position (column)
                targetY = row,  -- Target y position (row)
            }
        end
    end

    -- Add initial random tiles with values 1 or 2
    for i = 1, 2 do
        local row = math.random(1, gridRows)
        local col = math.random(1, gridCols)
        grid[row][col] = math.random(1, 2)
        tiles[row][col].value = grid[row][col]
    end
end


initializeGrid()


-- Function to draw the score
function drawScore()
    gfx.setFont(gfx.getSystemFont("bold")) -- Use the system font
    gfx.setColor(gfx.kColorBlack) -- Set text color to black

    -- Draw the high score on the left
    gfx.drawTextAligned("Highest: " .. tostring(highScore), 10, scoreHeight / 2-10, kTextAlignment.left)

    -- Draw the current score on the right
    gfx.drawTextAligned("Score: " .. tostring(score), screenWidth - 10, scoreHeight / 2-10, kTextAlignment.right)
end

function updateGridAfterMove()
    for row = 1, gridRows do
        for col = 1, gridCols do
            -- Ensure the tile exists before trying to update it
            if tiles[row] and tiles[row][col] then
                local tile = tiles[row][col]
                tile.value = grid[row][col]  -- Update the tile value from the grid
                tile.targetX = col  -- Update target positions
                tile.targetY = row  -- Update target positions

                -- Update the highest tile value
                if tile.value > highestTile then
                    highestTile = tile.value
                end

                -- Update the all-time highest tile if a new record is set
                if highestTile > allTimeHighestTile then
                    allTimeHighestTile = highestTile
                    saveAllTimeHighestTile()  -- Save the new all-time highest tile
                end
            end
        end
    end
end







-- Function to draw the grid
function drawGrid()
    gfx.clear()  -- Clear the screen

    drawScore()  -- Draw the scores at the top
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(screenWidth / 2 - 35, screenHeight / 2 - 119, 70, 28, 8)
   
local largeFont = gfx.getSystemFont("bold") -- Use a bold system font for emphasis
    gfx.setFont(largeFont)
    gfx.setColor(gfx.kColorWhite)
    playdate.graphics.setImageDrawMode("fillWhite")
    
    gfx.drawTextAligned("SumFib", screenWidth / 2, screenHeight / 2 - 115 , kTextAlignment.center)
    playdate.graphics.setImageDrawMode("copy")
    for row = 1, gridRows do
        for col = 1, gridCols do
            local tile = tiles[row][col]
            
            -- Calculate the current position for the tile, considering its animated position
            local x = startX + (tile.x - 1) * (squareSize + squarePadding)
            local y = startY + (tile.y - 1) * (squareSize2 + squarePadding2)
            local number = tile.value
            
            -- Draw the tile only if it has a number
            if number > 0 then
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRoundRect(x + 3, y + 3, squareSize, squareSize2, 8)
                
                gfx.setColor(gfx.kColorBlack)
                gfx.drawRoundRect(x - 0.2, y - 0.2, squareSize, squareSize2, 8)
                
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRoundRect(x+1, y+1, squareSize-2, squareSize2-2, 8)
                
                -- Draw the number inside the tile
                
                gfx.setFont(gfx.getSystemFont("bold"))  -- Use the system font
                gfx.setColor(gfx.kColorBlack)  -- Set text color to black
                gfx.drawTextAligned(tostring(number), x + squareSize / 2, y + squareSize2 / 2-squarePadding2, kTextAlignment.center)
            else
                -- Draw the dithered tile for empty positions
                gfx.setColor(gfx.kColorBlack)
                gfx.setDitherPattern(0.5)
                gfx.fillRoundRect(x, y, squareSize, squareSize2, 8)
            end
        end
    end
end



function shiftRight()
    local moved = false

    for row = 1, gridRows do
        local newRow = {}
        
        -- Step 1: Compress the row by moving all non-zero tiles to the right
        for col = gridCols, 1, -1 do
            if grid[row][col] > 0 then
                table.insert(newRow, 1, grid[row][col]) -- Insert at the start to maintain right alignment
            end
        end
        
        -- Step 2: Combine consecutive Fibonacci numbers
        for i = #newRow, 2, -1 do
            if isConsecutiveFibonacci(newRow[i], newRow[i - 1]) then
                newRow[i] = newRow[i] + newRow[i - 1] -- Combine them
                score = score + newRow[i] -- Update the score
                table.remove(newRow, i - 1) -- Remove the combined tile
                moved = true
            end
        end

        -- Step 3: Compress again after combining
        while #newRow < gridCols do
            table.insert(newRow, 1, 0) -- Fill the start with zeros
        end

        -- Step 4: Check if the grid has changed and update it
        for col = 1, gridCols do
            if grid[row][col] ~= newRow[col] then
                grid[row][col] = newRow[col]
                moved = true
            end
        end
    end

    return moved
end



-- Function to shift tiles to the left
function shiftLeft()
    local moved = false

    for row = 1, gridRows do
        local newRow = {}
        
        -- Step 1: Compress the row by moving all non-zero tiles to the left
        for col = 1, gridCols do
            if grid[row][col] > 0 then
                table.insert(newRow, grid[row][col]) -- Insert at the end to maintain left alignment
            end
        end
        
        -- Step 2: Combine consecutive Fibonacci numbers
        for i = 1, #newRow - 1 do
            if isConsecutiveFibonacci(newRow[i], newRow[i + 1]) then
                newRow[i] = newRow[i] + newRow[i + 1] -- Combine them
                score = score + newRow[i] -- Update the score
                table.remove(newRow, i + 1) -- Remove the combined tile
                moved = true
            end
        end

        -- Step 3: Compress again after combining
        while #newRow < gridCols do
            table.insert(newRow, 0) -- Fill the end with zeros
        end

        -- Step 4: Check if the grid has changed and update it
        for col = 1, gridCols do
            if grid[row][col] ~= newRow[col] then
                grid[row][col] = newRow[col]
                moved = true
            end
        end
    end

    return moved
end


-- Function to shift tiles up
function shiftUp()
    local moved = false

    for col = 1, gridCols do
        local newCol = {}
        
        -- Step 1: Compress the column by moving all non-zero tiles upwards
        for row = 1, gridRows do
            if grid[row][col] > 0 then
                table.insert(newCol, grid[row][col]) -- Insert at the end to maintain upward alignment
            end
        end
        
        -- Step 2: Combine consecutive Fibonacci numbers
        for i = 1, #newCol - 1 do
            if isConsecutiveFibonacci(newCol[i], newCol[i + 1]) then
                newCol[i] = newCol[i] + newCol[i + 1] -- Combine them
                score = score + newCol[i] -- Update the score
                table.remove(newCol, i + 1) -- Remove the combined tile
                moved = true
            end
        end

        -- Step 3: Compress again after combining
        while #newCol < gridRows do
            table.insert(newCol, 0) -- Fill the end with zeros
        end

        -- Step 4: Check if the grid has changed and update it
        for row = 1, gridRows do
            if grid[row][col] ~= newCol[row] then
                grid[row][col] = newCol[row]
                moved = true
            end
        end
    end

    return moved
end


-- Function to shift tiles down
function shiftDown()
    local moved = false

    for col = 1, gridCols do
        local newCol = {}
        
        -- Step 1: Compress the column by moving all non-zero tiles downwards
        for row = gridRows, 1, -1 do
            if grid[row][col] > 0 then
                table.insert(newCol, 1, grid[row][col]) -- Insert at the start to maintain downward alignment
            end
        end
        
        -- Step 2: Combine consecutive Fibonacci numbers
        for i = #newCol, 2, -1 do
            if isConsecutiveFibonacci(newCol[i], newCol[i - 1]) then
                newCol[i] = newCol[i] + newCol[i - 1] -- Combine them
                score = score + newCol[i] -- Update the score
                table.remove(newCol, i - 1) -- Remove the combined tile
                moved = true
            end
        end

        -- Step 3: Compress again after combining
        while #newCol < gridRows do
            table.insert(newCol, 1, 0) -- Fill the start with zeros
        end

        -- Step 4: Check if the grid has changed and update it
        for row = 1, gridRows do
            if grid[row][col] ~= newCol[row] then
                grid[row][col] = newCol[row]
                moved = true
            end
        end
    end

    return moved
end


-- Playdate update function, called every frame
function addNewTile()
    local emptyPositions = {}

    for row = 1, gridRows do
        for col = 1, gridCols do
            if grid[row][col] == 0 then
                table.insert(emptyPositions, {row = row, col = col})
            end
        end
    end

    if #emptyPositions > 0 then
        local newTilePosition = emptyPositions[math.random(#emptyPositions)]
        local possibleValues = {1, 1, 1, 1, 2}  -- List of numbers to choose from
        local index = math.random(1, #possibleValues)  -- Random index in the list
        local newValue = possibleValues[index]  -- Select th
        -- local newValue = math.random(1, 2)
        grid[newTilePosition.row][newTilePosition.col] = newValue
        tiles[newTilePosition.row][newTilePosition.col].value = newValue
    end
end





function saveHighScore()
    playdate.datastore.write({highScore = highScore}, "highscore")
end

function isGameOver()
    -- Check for any empty tiles
    for row = 1, gridRows do
        for col = 1, gridCols do
            if grid[row][col] == 0 then
                return false -- Not game over if there's at least one empty tile
            end
        end
    end

    -- Check for any valid moves horizontally (left-right)
    for row = 1, gridRows do
        for col = 1, gridCols - 1 do
            if isConsecutiveFibonacci(grid[row][col], grid[row][col + 1]) then
                return false -- Not game over if a valid move exists
            end
        end
    end

    -- Check for any valid moves vertically (up-down)
    for col = 1, gridCols do
        for row = 1, gridRows - 1 do
            if isConsecutiveFibonacci(grid[row][col], grid[row + 1][col]) then
                return false -- Not game over if a valid move exists
            end
        end
    end

    return true -- No empty tiles and no valid moves left
end



function resetGame()
    initializeGrid()
    score = 0
    currentHighestTile = 0
    gameOver = false
    musicStarted = false  -- Reset the flag to start music again on opening

    -- Safeguard against nil synth
    if synth then
        synth:stop()
    end

    -- Safeguard against nil melody_timer
    if melody_timer then
        melody_timer:remove()
        melody_timer = nil
    end
end






function drawGameOverScreen()
    
    gfx.clear(gfx.kColorWhite)
 
    -- Set a larger font for the "Game Over!" text if available
    gfx.setColor(gfx.kColorBlack)
        gfx.fillRoundRect(screenWidth / 2 - 35, screenHeight / 2 - 119, 70, 28, 8)
       fibRect()
    local largeFont = gfx.getSystemFont("bold") -- Use a bold system font for emphasis
        gfx.setFont(largeFont)
        gfx.setColor(gfx.kColorWhite)
        playdate.graphics.setImageDrawMode("fillWhite")
        
        gfx.drawTextAligned("SumFib", screenWidth / 2, screenHeight / 2 - 115 , kTextAlignment.center)
        playdate.graphics.setImageDrawMode("copy")
        gfx.setFont(largeFont)
    gfx.setColor(gfx.kColorBlack)

    -- Draw the "Game Over!" text larger and higher on the screen
    
    gfx.drawTextAligned("Game Over!", screenWidth / 2, screenHeight / 2 - 80, kTextAlignment.center)

    -- Reset to normal font
    local normalFont = gfx.getSystemFont()
    gfx.setFont(gfx.getSystemFont("bold"))

    -- Draw the score and high score
    gfx.drawTextAligned("Score: " .. tostring(score), screenWidth / 2, screenHeight / 2 - 10, kTextAlignment.center)
    gfx.drawTextAligned("High Score: " .. tostring(highScore), screenWidth / 2, screenHeight / 2 + 10, kTextAlignment.center)

    -- Draw the All-Time Highest Tile label
    -- gfx.drawTextAligned("to play again.", screenWidth / 2, screenHeight / 2 + 40, kTextAlignment.center)
    -- Prompt to start the game
    gfx.drawTextAligned("to play again", screenWidth / 2+32, screenHeight / 2 + 80, kTextAlignment.center)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(screenWidth / 2 - 35, screenHeight / 2 + 88, 15)
    gfx.setFont(largeFont)
    gfx.setColor(gfx.kColorWhite)
    playdate.graphics.setImageDrawMode("fillWhite")
    
    gfx.drawTextAligned("A", screenWidth / 2 - 35, screenHeight / 2 + 80 , kTextAlignment.center)
    playdate.graphics.setImageDrawMode("copy")
    -- Calculate the position to draw the tile
    local tileX = 20  --screenWidth / 2 - squareSize / 2
    local tileY = 20--screenHeight / 2 + 40

    -- Draw the tile for the highest tile
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(tileX + 3, tileY + 3, squareSize, squareSize2, 8)  -- Drop shadow
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(tileX, tileY, squareSize, squareSize2, 8)  -- Tile border
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(tileX+1, tileY+1, squareSize-2, squareSize2-2, 8) -- Tile background

    -- Draw the highest tile value in the center of the tile
    gfx.setFont(gfx.getSystemFont("Bold"))
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(tostring(allTimeHighestTile), tileX + squareSize / 2, tileY + squareSize2 / 2 - 5, kTextAlignment.center)

    -- Draw the "Press A to Restart" text, slightly higher than before
    gfx.drawTextAligned("to Restart", screenWidth / 2, screenHeight / 2 + 120, kTextAlignment.center)
    -- Draw the scale selection menu justified to the right
    
    gfx.setFont(gfx.getSystemFont("Bold"))
    gfx.setColor(gfx.kColorBlack)
    
    -- Draw title aligned left with padding
    local titleX = screenWidth - 60
    local titleY = 20
    gfx.drawText("Pisano", titleX, titleY)
    gfx.drawText("Period", titleX, titleY+20)
    local menuX = screenWidth - 60  -- Adjust as needed for your layout
    local menuY = 70
    gfx.setColor(gfx.kColorBlack)
    
    for i, scale in ipairs(scales) do
        local y_position = menuY + (i - 1) * 20  -- Adjust vertical spacing as needed
        if i == selected_index then
            gfx.setFont(gfx.getSystemFont("bold"))  -- Use bold font for selected option
            gfx.drawText("* " .. scale, menuX, y_position)  -- Highlight selected option with asterisk
        else
            gfx.setFont(gfx.getSystemFont())  -- Use regular font for non-selected options
            gfx.drawText(scale, menuX + 10, y_position)
        end
    end
    
end




--SOUND



-- Function to calculate the Pisano period for a given modulus
function calculate_pisano_period(modulus)
    local previous, current = 0, 1
    for i = 0, modulus * modulus do
        local temp = current
        current = (previous + current) % modulus
        previous = temp
        if previous == 0 and current == 1 then
            return i + 1
        end
    end
end

-- Function to generate the Fibonacci sequence modulo a given number, up to the Pisano period length
function generate_fibonacci_modulo_sequence(modulus, period_length)
    local fib_seq_mod = {}
    local previous, current = 0, 1
    for i = 1, period_length do
        table.insert(fib_seq_mod, previous % modulus)
        local temp = current
        current = (previous + current) % modulus
        previous = temp
    end
    return fib_seq_mod
end

-- Function to map the Fibonacci sequence modulo values to the scale
function map_to_scale(fib_mod_seq, scale)
    local mapped_notes = {}
    
    for i, fib_num in ipairs(fib_mod_seq) do
        local note_index = (fib_num % #scale) + 1 -- Map to scale
        
        table.insert(mapped_notes, scale[note_index])
    end
    return mapped_notes
end

-- Calculate the Pisano period for modulus 13
local pisano_period = calculate_pisano_period(#the_scale)
-- print("Pisano period for modulus 13 is: " .. tostring(pisano_period))

-- Generate the Fibonacci sequence modulo 13, up to the Pisano period
local fib_mod_sequence = generate_fibonacci_modulo_sequence(#the_scale, pisano_period)
-- print("Generated Fibonacci sequence modulo 13: " .. table.concat(fib_mod_sequence, ", "))

-- Map the sequence to the C-major scale
local melody = map_to_scale(fib_mod_sequence, the_scale)
-- print("Melody mapped to scale: " .. table.concat(melody, ", "))

-- Initialize variables for playing the melody
local current_note_index = 1
local synth = playdate.sound.synth.new(playdate.sound.kWaveSine)

-- Function to play the next note in the melody
function play_next_note()
    synth:playNote(melody[current_note_index], 1.0) -- Play current note
    -- Assuming this function exists for visuals

    current_note_index += 1
    if current_note_index > #melody then
        current_note_index = 1 -- Loop back to the start
    end
    local delay1 = 300 + 100*(current_note_index%2)
    playdate.timer.performAfterDelay(delay1, play_next_note) -- Wait 1000 ms before playing the next note
end





function update_selection_and_music()
    local previous_index = selected_index
    local crank_change = playdate.getCrankChange()

    if crank_change ~= 0 then
        previous_index = selected_index  -- Store the previous index
        
        selected_index = selected_index + (crank_change > 0 and 1 or -1)
        if selected_index < 1 then
            selected_index = #scales
        elseif selected_index > #scales then
            selected_index = 1
        end
        
        -- Check if the selected scale has changed
        if selected_index ~= previous_index then
            -- Stop the current sound and cancel the previous timer
            synth:stop()
            if melody_timer then
                melody_timer:remove()
                melody_timer = nil
            end

            -- Change the music to the newly selected scale
            the_scale = scale_mapping[selected_index]
            local pisano_period = calculate_pisano_period(#the_scale)
            local fib_mod_sequence = generate_fibonacci_modulo_sequence(#the_scale, pisano_period)
            melody = map_to_scale(fib_mod_sequence, the_scale)
            
            current_note_index = 1  -- Reset the note index
            -- play_next_note()  -- Start playing the new melody
        end
    end
end




function handleOpeningInput()
    update_selection_and_music()
    

    if playdate.buttonJustPressed(playdate.kButtonA) then
        the_scale = scale_mapping[selected_index]  -- Set the selected scale
        gameState = "playing"
        initializeGrid()  -- Initialize the grid for a new game

        -- Recalculate melody with the selected scale
        local pisano_period = calculate_pisano_period(#the_scale)
        local fib_mod_sequence = generate_fibonacci_modulo_sequence(#the_scale, pisano_period)
        melody = map_to_scale(fib_mod_sequence, the_scale)
        
    end
end


local musicStarted = false

function playdate.update()
    if gameState == "opening" then
        drawOpeningScreen()
        if not musicStarted then
            startMusic()  -- Start the music
            musicStarted = true  -- Flag to ensure music starts only once
        end
        update_selection_and_music()  -- Update the selection and change music as needed
        handleOpeningInput()  -- Handle button presses

    elseif gameState == "playing" then
        if gameOver then
            drawGameOverScreen()
            if not musicStarted then
                startMusic()  -- Start the music
                musicStarted = true  -- Flag to ensure music starts only once
            end
            update_selection_and_music()  -- Update the selection and change music as needed
            handleOpeningInput()  -- Handle button presses

            if playdate.buttonJustPressed(playdate.kButtonA) then
                resetGame()
                gameState = "playing"
            end
        else
            local moved = false

            -- Handle player input
            if playdate.buttonJustPressed(playdate.kButtonRight) then
                moved = shiftRight()
            elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
                moved = shiftLeft()
            elseif playdate.buttonJustPressed(playdate.kButtonUp) then
                moved = shiftUp()
            elseif playdate.buttonJustPressed(playdate.kButtonDown) then
                moved = shiftDown()
            end

            if moved then
                updateGridAfterMove()
                addNewTile()
            end

            updateTilePositions()  -- Update tile positions for sliding effect
            drawGrid()  -- Draw the grid after updating positions

            -- Check for game over
            if isGameOver() then
                gameState = "gameOver"
                musicStarted = false  -- Reset music flag for game over screen
                if score > highScore then
                    highScore = score
                    saveHighScore()
                end
            end
        end
    elseif gameState == "gameOver" then
        drawGameOverScreen()
        update_selection_and_music()  -- Update the selection and change music as needed
        handleOpeningInput()  -- Handle button presses

        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetGame()
            gameState = "playing"
        end
    end

    -- Keep the game loop running smoothly
    playdate.timer.updateTimers()
end



-- Start playing the melody
-- Load the high score when the game starts
-- Load the high score and all-time highest tile when the game starts
loadHighScore()
loadAllTimeHighestTile()

-- Initialize the grid with starting tiles
initializeGrid()




