local icon = {
    Coal = 1, --1 - 8 are ores
    Iron = 2,
    Gold = 3,
    Uranium = 4,
    Diamond = 5,
    Ruby = 6,
    Tanzenite = 7,
    Copper = 8,
    Shrub = 9, --stick
    ironIngot = 10, 
    goldIngot = 11, 
    emeraldIngot = 12, 
    diamondIngot = 13, 
    rubyIngot = 14,
    tanzeniteIngot = 15, 
    copperIngot = 16, 
    Wall = 18,
    Crafting = 28,
    Furnace = 29,
    StoneBrick = 30,
    Grass = 31,
    Dirt = 32,
    Torch = 33,
    Chest = 34,
    Water = 35,
    Teleporter = 36,
    health = 41,
    halfHeart = 42,
    MagicPlant = 49,
    Mushroom = 51,
}

local recipes = {
    Resources = {
        {name = "Iron", input = icon.Iron, output = icon.ironIngot, cost = 4, description = "Smelt Iron Ore into Iron Ingot" },
        {name = "Gold", input = icon.Gold, output = icon.goldIngot, cost = 5, description = "Smelt Gold Ore into Gold Ingot" },
        {name = "Diamond", input = icon.Diamond, output = icon.diamondIngot, cost = 7, description = "Smelt Diamond Ore into Diamond Ingot" },
        {name = "Tazenite", input = icon.Tanzenite, output = icon.tanzeniteIngot, cost = 6, description = "Smelt Tanzenite Ore into Tanzenite Ingot" },
        {name = "Copper", input = icon.Copper, output = icon.copperIngot, cost = 3, description = "Smelt Copper Ore into Copper Ingot" },
        {name = "Ruby", input = icon.Ruby, output = icon.rubyIngot, cost = 6, description = "Smelt Ruby Ore into Ruby Ingot" },
    },
    Tools = {
        {name = "TEMP", input = icon.Ruby, output = icon.rubyIngot, cost = 6, description = "Smelt Ruby Ore into Ruby Ingot" },
        {name = "TEMP", input = icon.Ruby, output = icon.rubyIngot, cost = 6, description = "Smelt Ruby Ore into Ruby Ingot" },
        {name = "TEMP", input = icon.Ruby, output = icon.rubyIngot, cost = 6, description = "Smelt Ruby Ore into Ruby Ingot" },

    },
    Misc = {
        {name = "Tazenite", input = icon.Tanzenite, output = icon.tanzeniteIngot, cost = 6, description = "Smelt Tanzenite Ore into Tanzenite Ingot" },
        {name = "Tazenite", input = icon.Tanzenite, output = icon.tanzeniteIngot, cost = 6, description = "Smelt Tanzenite Ore into Tanzenite Ingot" },
        {name = "Tazenite", input = icon.Tanzenite, output = icon.tanzeniteIngot, cost = 6, description = "Smelt Tanzenite Ore into Tanzenite Ingot" },
        {name = "Tazenite", input = icon.Tanzenite, output = icon.tanzeniteIngot, cost = 6, description = "Smelt Tanzenite Ore into Tanzenite Ingot" },

    }
}

return recipes