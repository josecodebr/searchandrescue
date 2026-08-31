searchandrescue = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())

local files = {
    "helicoptero.lua",
    "fire_truck.lua",
    "recipe.lua",
    "searchandrescue_objects/rope.lua",
    "searchandrescue_itens/itens.lua",
    "cargas/cargas.lua", -- Corrigido o caminho da pasta
}

for _, file in ipairs(files) do
    dofile(modpath .. "/" .. file)
end
