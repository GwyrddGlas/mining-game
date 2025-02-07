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
    placeable = false,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Wall",
    textureID = 17, 
    maxHP = 5,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = false,
    placeable = true,
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
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Shrub",
    textureID = 18, 
    maxHP = 10,
    drop = {1, 1},
    solid = false,
    destructible = true,
    placeable = true,
    item = "Shrub",
    itemTextureID = 50,
}

tileData[#tileData+1] = {
    type = "MagicPlant",
    textureID = 18, 
    maxHP = 10,
    drop = {1, 1},
    solid = false,
    destructible = true,
    interactable = true,
    placeable = true,
    item = "MagicPlant",
    itemTextureID = 49,
}

tileData[#tileData+1] = {
    type = "Coal",
    textureID = 18, 
    maxHP = 10,
    drop = {1, 3},
    solid = false,
    destructible = true, 
    item = "Coal",
    placeable = false,
    itemTextureID = 19,
}

tileData[#tileData+1] = {
    type = "Iron",
    textureID = 18, 
    maxHP = 12,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Iron",
    placeable = false,
    itemTextureID = 20,
}

tileData[#tileData+1] = {
    type = "Gold",
    textureID = 18, 
    maxHP = 15,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Gold",
    placeable = false,
    itemTextureID = 21,
}

tileData[#tileData+1] = {
    type = "Uranium",
    textureID = 18, 
    maxHP = 15,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Uranium",
    placeable = false,
    itemTextureID = 22,
}

tileData[#tileData+1] = {
    type = "Diamond",
    textureID = 18, 
    maxHP = 20,
    drop = {1, 2}, 
    destructible = true, 
    solid = false,
    item = "Diamond",
    placeable = false,
    itemTextureID = 23,
}

tileData[#tileData+1] = {
    type = "Ruby",
    textureID = 18, 
    maxHP = 18,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Ruby",
    placeable = false,
    itemTextureID = 24,
}

tileData[#tileData+1] = {
    type = "Tanzenite",
    textureID = 18, 
    maxHP = 30,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Tanzenite",
    placeable = false,
    itemTextureID = 25,
}

tileData[#tileData+1] = {
    type = "Copper",
    textureID = 18, 
    maxHP = 15,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Copper",
    placeable = false,
    itemTextureID = 26,
}

tileData[#tileData+1] = {
    type = "Furnace",
    textureID = 27, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = false,
    interactable = true,
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Crafting",
    textureID = 28, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = false,
    interactable = true,
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Teleporter",
    textureID = 36, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = false,
    interactable = true,
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "StoneBrick",
    textureID = 30, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = false,
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Torch",
    textureID = 18, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = true,
    item = "Torch",
    placeable = true,
    itemTextureID = 33,
}

tileData[#tileData+1] = {
    type = "Grass",
    textureID = 31, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = false,
    placeable = true,
    itemTextureID = 0,
}

tileData[#tileData+1] = {
    type = "Mushroom",
    textureID = 18, 
    maxHP = 8,
    drop = {1, 1}, 
    destructible = true, 
    solid = false,
    item = "Mushroom",
    placeable = true,
    itemTextureID = 51,
}

return tileData