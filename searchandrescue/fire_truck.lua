-- ========================================================================
-- CONFIGURAÇÕES E ESCALA
-- ========================================================================
searchandrescue = searchandrescue or {}
searchandrescue.fire_truck_scale = 1.0 -- Ajuste o tamanho do caminhão aqui (ex: 0.8, 0.5)

local scale = searchandrescue.fire_truck_scale

local vehicles = {
    {"fire_truck", "fire_truck.png", "fire_truck.b3d", "fire_truck_icon.png"},
}

-- Função para verificar se o nó abaixo é terreno sólido
local function is_ground(pos)
    if not pos then return false end
    local node = minetest.get_node(pos)
    local nodedef = minetest.registered_nodes[node.name]
    return nodedef and nodedef.walkable or false
end

local function get_sign(i)
    if i == 0 then return 0 end
    return i / math.abs(i)
end

local function get_velocity(v, yaw, y)
    local x = -math.sin(yaw) * v
    local z =  math.cos(yaw) * v
    return {x = x, y = y, z = z}
end

local function get_v(v)
    return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

-- ========================================================================
-- DEFINIÇÃO DA ENTIDADE DO CAMINHÃO
-- ========================================================================
local fire_truck = {
    physical = true,
    -- Caixas de colisão e seleção ajustadas dinamicamente pela escala
    selection_box = {type = "fixed", fixed = {-1 * scale, -0.5 * scale, -1.5 * scale, 1 * scale, 1.3 * scale, 1.5 * scale}},
    collision_box = {type = "fixed", fixed = {-1 * scale, -0.5 * scale, -1.5 * scale, 1 * scale, 1.3 * scale, 1.5 * scale}},
    visual = "mesh",
    mesh = vehicles[1][3],
    backface_culling = false,
    textures = {vehicles[1][2]},
    visual_size = {x = scale, y = scale, z = scale},
    stepheight = 1.1 * scale, -- Sobe degraus/slabs proporcionalmente ao tamanho

    driver = nil,
    v = 0,
    last_v = 0,
    removed = false
}

function fire_truck.on_rightclick(self, clicker)
    if not clicker or not clicker:is_player() then return end
    local name = clicker:get_player_name()

    -- SE O JOGADOR JÁ FOR O MOTORISTA -> DESEMBARCAR
    if self.driver and clicker == self.driver then
        self.driver = nil
        clicker:set_detach()

        if player_api and player_api.player_attached then
            player_api.player_attached[name] = nil
            player_api.set_animation(clicker, "stand", 30)
        end

        local pos = clicker:get_pos()
        clicker:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        
        -- Move ligeiramente para o lado ao sair para não prender no veículo
        minetest.after(0.1, function()
            clicker:set_pos({x = pos.x + (1.5 * scale), y = pos.y + 0.2, z = pos.z})
        end)

    -- SE NÃO HOUVER MOTORISTA -> EMBARCAR
    elseif not self.driver then
        self.driver = clicker
        
        -- 1. Reduza o valor Y aqui para "baixar" o corpo do jogador dentro da cabine
        local attach_pos = {x = -0.3 * scale, y = 0.5 * scale, z = 0.2 * scale}
        clicker:set_attach(self.object, "", attach_pos, {x = 0, y = 0, z = 0})

        if player_api then
            player_api.set_animation(clicker, "sit", 30)
            if player_api.player_attached then
                player_api.player_attached[name] = true
            end
        end

        -- 2. Ajuste a altura do olho em primeira pessoa (Y menor = visão mais baixa)
        -- Estava em: {x = 0, y = 0.9 * scale, z = 0}
        clicker:set_eye_offset({x = 0, y = 0.3 * scale, z = 0}, {x = 0, y = 0, z = 0})
        self.object:set_yaw(clicker:get_look_horizontal())
    end
end

function fire_truck.on_activate(self, staticdata, dtime_s)
    self.object:set_armor_groups({immortal = 1})
    if staticdata and staticdata ~= "" then
        self.v = tonumber(staticdata) or 0
    end
    self.last_v = self.v
end

function fire_truck.get_staticdata(self)
    return tostring(self.v)
end

function fire_truck.on_punch(self, puncher, time_from_last_punch, tool_capabilities, direction)
    if not puncher or not puncher:is_player() or self.removed then return end

    if self.driver and puncher == self.driver then
        self.driver = nil
        puncher:set_detach()
        local pname = puncher:get_player_name()
        if player_api and player_api.player_attached then
            player_api.player_attached[pname] = nil
        end
    end

    if not self.driver then
        self.removed = true
        minetest.after(0.1, function()
            local inv = puncher:get_inventory()
            if inv then
                inv:add_item("main", "searchandrescue:" .. vehicles[1][1])
            end
            self.object:remove()
        end)
    end
end

function fire_truck.on_step(self, dtime)
    local velo = self.object:get_velocity() or vector.new()
    self.v = get_v(velo) * get_sign(self.v)

    -- Controle pelo Motorista
    if self.driver then
        local ctrl = self.driver:get_player_control()
        local yaw = self.object:get_yaw()

        if ctrl.up then
            self.v = self.v + 0.15
        elseif ctrl.down then
            self.v = self.v - 0.10
        end

        -- Direção (Ajusta rotação no sentido correto em ré)
        if ctrl.left then
            local dir = (self.v < 0) and -1 or 1
            self.object:set_yaw(yaw + dir * (1 + dtime) * 0.04)
        elseif ctrl.right then
            local dir = (self.v < 0) and -1 or 1
            self.object:set_yaw(yaw - dir * (1 + dtime) * 0.04)
        end
    end

    -- Veículo parado
    if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
        return
    end

    -- Atrito / Desaceleração Natural
    local s = get_sign(self.v)
    self.v = self.v - 0.03 * s
    if s ~= get_sign(self.v) then
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.v = 0
        return
    end

    -- Limite de Velocidade (Máximo 8 m/s)
    local max_speed = 8
    if math.abs(self.v) > max_speed then
        self.v = max_speed * get_sign(self.v)
    end

    -- Checagem de Terreno e Gravidade
    local p = self.object:get_pos()
    p.y = p.y - 0.5
    
    local new_velo = {x = 0, y = 0, z = 0}
    local new_acce = {x = 0, y = 0, z = 0}

    if not is_ground(p) then
        -- No ar: aplica gravidade
        new_acce = {x = 0, y = -9.81, z = 0}
        new_velo = get_velocity(self.v, self.object:get_yaw(), velo.y)
    else
        -- No chão: zera a aceleração Y e mantém o movimento horizontal
        new_acce = {x = 0, y = 0, z = 0}
        new_velo = get_velocity(self.v, self.object:get_yaw(), 0)
    end

    self.object:set_velocity(new_velo)
    self.object:set_acceleration(new_acce)
end

-- Registra a Entidade
minetest.register_entity("searchandrescue:" .. vehicles[1][1], fire_truck)

-- Registra o Item
minetest.register_craftitem("searchandrescue:" .. vehicles[1][1], {
    description = "Caminhão de Bombeiros",
    inventory_image = vehicles[1][4],
    wield_image = vehicles[1][4],
    stack_max = 1,
    liquids_pointable = true,

    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing or pointed_thing.type ~= "node" then return end

        local spawn_pos = pointed_thing.above
        local obj = minetest.add_entity(spawn_pos, "searchandrescue:" .. vehicles[1][1])

        if obj and placer then
            obj:set_yaw(placer:get_look_horizontal())
        end

        local player_name = placer and placer:get_player_name() or ""
        if not (minetest.is_creative_enabled and minetest.is_creative_enabled(player_name)) then
            itemstack:take_item()
        end

        return itemstack
    end,
})
