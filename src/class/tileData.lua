-- Contains all data relating to tiles
-- Wall, floor, coal, iron, gold, uranium, Diamond, Ruby, Tanzenite
local tileData = {}
local preset = {
    type = "type",
    textureID = 0, 
    maxHP = 2,
    drop = {0, 0}, 
    destructible = true, 
    solid = true,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Wall",
    textureID = 17, 
    maxHP = 5,
    drop = {0, 0}, 
    destructible = true, 
    solid = true,
    item = false,
    itemTextureID = 0,
}
    
tileData[#tileData+1] = {
    type = "Floor",
    textureID = 18, 
    maxHP = 0,
    drop = {0, 0}, 
    destructible = false, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Shrub",
    textureID = 18, 
    maxHP = 3,
    drop = {0, 2}, 
    destructible = true, 
    solid = false,
    item = "Shrub",
    itemTextureID = 50,
}

tileData[#tileData+1] = {
    type = "Coal",
    textureID = 19, 
    maxHP = 10,
    drop = {2, 6},
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Iron",
    textureID = 20, 
    maxHP = 12,
    drop = {1, 3}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Gold",
    textureID = 21, 
    maxHP = 15,
    drop = {1, 2}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Uranium",
    textureID = 22, 
    maxHP = 15,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Diamond",
    textureID = 23, 
    maxHP = 20,
    drop = {1, 2}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Ruby",
    textureID = 24, 
    maxHP = 18,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Tanzenite",
    textureID = 25, 
    maxHP = 30,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Copper",
    textureID = 26, 
    maxHP = 15,
    drop = {1, 3}, 
    destructible = true, 
    solid = false,
    item = false,
    itemTextureID = 0,
}

return tileData