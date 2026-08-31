-- ========================================================================
-- FACTORY MINE - MÓDULO PRINCIPAL
-- ========================================================================
local item_requisitado = "searchandrescue:heli"
local entidade_gerada  = "searchandrescue:helicopter"

local furnace_formspec = 
    "formspec_version[5]" ..
    "size[14,10]" ..
    "label[5,0.6;Insira: " .. item_requisitado .. "]" ..
    "label[5.5,2.1;Entrada]" ..
    "list[current_name;item1;5.4,2.6;1,1;0]" ..
    "list[current_player;main;2.2,8.3;8,1;1]" ..
    "list[current_player;main;2.2,4.3;8,3;0]"

-- Declaração antecipada de funções auxiliares
local add_acessorios
local limpar_area

-- ========================================================================
-- REGISTRO DO BLOCO DA FÁBRICA
-- ========================================================================
minetest.register_node("factory_mine:factory", {
    description = "Fábrica de Montagem",
    visual_size = {x = 1, y = 1},

    selection_box = {type = "fixed", fixed = {-4, -5, -4, 4, 0, 4}},
    collision_box = {type = "fixed", fixed = {-4, -5, -4, 4, 0, 4}},

    drawtype = "mesh",
    mesh = "factory_mine.b3d",
    tiles = {"factory_mine.png"},
    inventory_image = "factory_mine_icon.png",
    wield_image = "factory_mine_icon.png",
    paramtype = "light",
    groups = {snappy = 1, choppy = 2, flammable = 3, oddly_breakable_by_hand = 2},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", furnace_formspec)
        meta:set_string("infotext", "Fábrica de Veículos")
        meta:set_int("Total", 0)
        
        local inv = meta:get_inventory()
        inv:set_size("item1", 1)

        -- Adiciona as luzes periféricas e o robô operário
        add_acessorios(pos)
    end,

    -- Dispara quando o jogador insere um item na interface
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "item1" and stack:get_name() == item_requisitado then
            local timer = minetest.get_node_timer(pos)
            if not timer:is_started() then
                timer:start(1.0) -- Inicia o processamento
            end
        end
    end,

    -- Timer de processamento (substitui o ABM de alta carga)
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local stack = inv:get_stack("item1", 1)

        if stack:get_name() == item_requisitado then
            -- Consome 1 item do slot
            stack:take_item(1)
            inv:set_stack("item1", 1, stack)

            -- Spawn do helicóptero sobre a fábrica
            local spawn_pos = vector.add(pos, {x = 0, y = 1, z = 0})
            if minetest.get_node(spawn_pos).name == "air" then
                minetest.add_entity(spawn_pos, entidade_gerada)
            end

            -- Atualiza o contador de produção
            local total = meta:get_int("Total") + 1
            meta:set_int("Total", total)
            meta:set_string("formspec", furnace_formspec .. "label[4.5,1.5;Total Produzido: " .. total .. "]")

            -- Se ainda houverem itens no slot, agenda o próximo ciclo
            if not inv:get_stack("item1", 1):is_empty() then
                return true
            end
        end
        return false
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        
        if not inv:is_empty("item1") then 
            return false 
        end
        
        limpar_area(pos)
        return true
    end,

    on_destruct = function(pos)
        limpar_area(pos)
    end,
})

-- ========================================================================
-- FUNÇÕES AUXILIARES DE ESTRUTURA E LIMPEZA
-- ========================================================================

add_acessorios = function(pos)
    local posicoes_luz = {
        {5, 3, 3},
        {5, 3, -3},
        {-5, 3, -3},
        {-5, 3, 3},
    }

    -- Instancia o Robô Operário no centro se o nó estiver livre
    local node_center = minetest.get_node(pos)
    if node_center.name ~= "ignore" then
        minetest.add_entity(pos, "factory_mine:robo_operario")
    end

    -- Posiciona as luminárias industriais
    for _, offset in ipairs(posicoes_luz) do
        local light_pos = vector.add(pos, {x = offset[1], y = offset[2], z = offset[3]})
        if minetest.get_node(light_pos).name == "air" then
            minetest.set_node(light_pos, {name = "factory_mine:factory_mine_light"})
        end
    end
end

limpar_area = function(pos)
    local posicoes_luz = {
        {5, 3, 3},
        {5, 3, -3},
        {-5, 3, -3},
        {-5, 3, 3},
    }

    -- Remove as luzes criadas no perímetro
    for _, offset in ipairs(posicoes_luz) do
        local light_pos = vector.add(pos, {x = offset[1], y = offset[2], z = offset[3]})
        if minetest.get_node(light_pos).name == "factory_mine:factory_mine_light" then
            minetest.set_node(light_pos, {name = "air"})
        end
    end

    -- Remove a entidade do Robô Operário associada
    local objects = minetest.get_objects_inside_radius(pos, 15)
    for _, obj in ipairs(objects) do
        if not obj:is_player() then
            local luaentity = obj:get_luaentity()
            if luaentity and luaentity.name == "factory_mine:robo_operario" then
                obj:remove()
            end
        end
    end
end
