local verssione = 1
-- Constantes de voo e física
searchandrescue.tilting_speed = 1
searchandrescue.tilting_max = 0.5
searchandrescue.power_max = 20
searchandrescue.power_min = 0.2
searchandrescue.wanted_vert_speed = 10

searchandrescue.friction_air_quadratic = 0.01
searchandrescue.friction_air_constant = 0.2
searchandrescue.friction_land_quadratic = 1
searchandrescue.friction_land_constant = 2
searchandrescue.friction_water_quadratic = 0.1
searchandrescue.friction_water_constant = 1

searchandrescue.heli_scale = 0.50
local scale = searchandrescue.heli_scale

if not minetest.global_exists("matrix3") then
    dofile(minetest.get_modpath("searchandrescue") .. "/searchandrescue_api/matrix.lua")
end

local gravity = tonumber(minetest.settings:get("movement_gravity")) or 9.81
searchandrescue.vector_up = vector.new(0, 1, 0)
searchandrescue.vector_forward = vector.new(0, 0, 1)

function searchandrescue.vector_length_sq(v)
    return v.x * v.x + v.y * v.y + v.z * v.z
end

-- Verifica se a entidade está tocando o chão ou água
function searchandrescue.check_node_below(obj)
    local pos_below = obj:get_pos()
    if not pos_below then return false, false end
    pos_below.y = pos_below.y - 0.1

    local node_below = minetest.get_node(pos_below).name
    local nodedef = minetest.registered_nodes[node_below]
    
    local touching_ground = not nodedef or nodedef.walkable or false
    local liquid_below = not touching_ground and nodedef.liquidtype ~= "none"
    return touching_ground, liquid_below
end

-- Função para desembarcar o piloto
function searchandrescue.sair_helicoptero(self, player)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()

    if name == self.driver_name then
        self.driver_name = nil

        -- Parar som e animação
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
        self.object:set_animation_frame_speed(0)

        -- Desanexar jogador e resetar visão/animação
        player:set_detach()
        player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})

        if player_api and player_api.player_attached then
            player_api.player_attached[name] = nil
            player_api.set_animation(player, "stand")
        end

        -- Aplica gravidade ao helicóptero vazio
        self.object:set_acceleration(vector.new(0, -gravity, 0))
    end
end

-- Controle de Voo do Helicóptero
function searchandrescue.heli_control(self, dtime, touching_ground, liquid_below, vel_before)
    local driver = minetest.get_player_by_name(self.driver_name)

    -- Se o piloto desconectou ou não existe, desliga os motores
    if not driver then
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
        self.driver_name = nil
        self.object:set_animation_frame_speed(0)
        self.object:set_acceleration(vector.new(0, -gravity, 0))
        return vel_before
    end

    local ctrl = driver:get_player_control()

    -- Tecla para Sair (E = Aux1 / Sneak)
    if ctrl.aux1 then
        searchandrescue.sair_helicoptero(self, driver)
        return vel_before
    end

    local vert_vel_goal = 0
    if not liquid_below then
        if ctrl.jump then vert_vel_goal = vert_vel_goal + searchandrescue.wanted_vert_speed end
        if ctrl.sneak then vert_vel_goal = vert_vel_goal - searchandrescue.wanted_vert_speed end
    else
        vert_vel_goal = searchandrescue.wanted_vert_speed
    end

    local rot = self.object:get_rotation()

    -- Inclinação e Direção
    if not touching_ground then
        local tilting_goal = vector.new()
        if ctrl.up then tilting_goal.z = tilting_goal.z + 1 end
        if ctrl.down then tilting_goal.z = tilting_goal.z - 1 end
        if ctrl.right then tilting_goal.x = tilting_goal.x + 1 end
        if ctrl.left then tilting_goal.x = tilting_goal.x - 1 end

        if searchandrescue.vector_length_sq(tilting_goal) > 0 then
            tilting_goal = vector.multiply(vector.normalize(tilting_goal), searchandrescue.tilting_max)
        end

        -- Transição suave da inclinação
        if searchandrescue.vector_length_sq(vector.subtract(tilting_goal, self.tilting)) > (dtime * searchandrescue.tilting_speed)^2 then
            self.tilting = vector.add(self.tilting, vector.multiply(vector.direction(self.tilting, tilting_goal), dtime * searchandrescue.tilting_speed))
        else
            self.tilting = tilting_goal
        end

        local new_up = vector.normalize(vector.new(self.tilting.x, 1, self.tilting.z))
        local new_right = vector.cross(new_up, searchandrescue.vector_forward)
        local new_forward = vector.cross(new_right, new_up)

        local rot_mat = matrix3.new(
            new_right.x, new_up.x, new_forward.x,
            new_right.y, new_up.y, new_forward.y,
            new_right.z, new_up.z, new_forward.z
        )
        rot = matrix3.to_pitch_yaw_roll(rot_mat)
        rot.y = driver:get_look_horizontal()
    else
        rot.x = 0
        rot.z = 0
        self.tilting.x = 0
        self.tilting.z = 0
    end

    self.object:set_rotation(rot)

    -- Aceleração e Empuxo
    local power = vert_vel_goal - vel_before.y + gravity * dtime
    power = math.min(math.max(power, searchandrescue.power_min * dtime), searchandrescue.power_max * dtime)
    local rotated_up = matrix3.multiply(matrix3.from_pitch_yaw_roll(rot), searchandrescue.vector_up)
    
    local added_vel = vector.multiply(rotated_up, power)
    added_vel = vector.add(added_vel, vector.new(0, -gravity * dtime, 0))

    return vector.add(vel_before, added_vel)
end

-- Registro da Entidade do Helicóptero
minetest.register_entity("searchandrescue:helicopter", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        -- As caixas de colisão agora encolhem proporcionalmente com a escala!
        collisionbox = {-1 * scale, 0, -1 * scale, 1 * scale, 1 * scale, 1 * scale},
        selectionbox = {-1 * scale, 0, -1 * scale, 1 * scale, 1 * scale, 1 * scale},
        visual = "mesh",
        mesh = "helicoptero.b3d",
        textures = {"helicoptero.png"},
        -- Reduz o tamanho visual da malha 3D
        visual_size = {x = scale, y = scale, z = scale},
    },
    
    driver_name = nil,
    sound_handle = nil,
    tilting = vector.new(0, 0, 0),
    tilting = vector.new(0, 0, 0),

    on_activate = function(self)
        self.object:set_animation({x = 0, y = 5}, 0, 0, true)
        self.object:set_armor_groups({immortal = 1})
        self.object:set_acceleration(vector.new(0, -gravity, 0))
    end,

    on_detach = function(self)
        self.object:set_acceleration(vector.new(0, -gravity, 0))
    end,

    on_step = function(self, dtime)
        local vel = self.object:get_velocity() or vector.new()
        local touching_ground, liquid_below

        if self.driver_name then
            touching_ground, liquid_below = searchandrescue.check_node_below(self.object)
            vel = searchandrescue.heli_control(self, dtime, touching_ground, liquid_below, vel) or vel
        end

        if vel.x == 0 and vel.y == 0 and vel.z == 0 then return end
        if touching_ground == nil then 
            touching_ground, liquid_below = searchandrescue.check_node_below(self.object) 
        end

        -- Desaceleração por atrito
        local speedsq = searchandrescue.vector_length_sq(vel)
        local fq, fc

        if touching_ground then 
            fq, fc = searchandrescue.friction_land_quadratic, searchandrescue.friction_land_constant
        elseif liquid_below then 
            fq, fc = searchandrescue.friction_water_quadratic, searchandrescue.friction_water_constant
        else 
            fq, fc = searchandrescue.friction_air_quadratic, searchandrescue.friction_air_constant
        end

        vel = vector.apply(vel, function(a)
            local s = math.sign(a)
            a = math.abs(a)
            a = math.max(0, a - fq * dtime * speedsq - fc * dtime)
            return a * s
        end)

        self.object:set_velocity(vel)
    end,

    on_punch = function(self, puncher)
        return false
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local name = clicker:get_player_name()
        
        if not self.driver_name then
            searchandrescue.entrar_helicoptero(self, clicker)
        end
    end
})

-- Embarque no Helicóptero
function searchandrescue.entrar_helicoptero(self, clicker)
    local name = clicker:get_player_name()
    self.driver_name = name

    local scale = searchandrescue.heli_scale or 1

    -- Som e animação das hélices
    self.sound_handle = minetest.sound_play("helicopter_motor", {
        object = self.object,
        gain = 2.0,
        max_hear_distance = 32,
        loop = true,
    })
    self.object:set_animation_frame_speed(30)

    -- Multiplica a posição de anexo e a visão do jogador pela escala
    local base_y = (verssione == 0) and 17 or 18
    local attach_pos = {x = 0, y = base_y * scale, z = 28 * scale}
    local eye_pos = {x = 0, y = 24.5 * scale, z = 30 * scale}
    local eye_look = {x = 0, y = 8 * scale, z = -5 * scale}

    clicker:set_attach(self.object, "", attach_pos, {x = 0, y = 0, z = 0})
    clicker:set_eye_offset(eye_pos, eye_look)

    if player_api and player_api.player_attached then
        player_api.player_attached[name] = true
        minetest.after(0.2, function()
            local player = minetest.get_player_by_name(name)
            if player then player_api.set_animation(player, "sit") end
        end)
    end

    self.object:set_acceleration(vector.new(0, 0, 0))
end
