-- ========================================================================
-- DEFINIÇÃO DOS ITENS E NÓS
-- ========================================================================

-- Item do Gancho / Corda
minetest.register_craftitem("searchandrescue:hook", {
    description = "Gancho de Resgate",
    inventory_image = "rope.png",
})

-- Nó de Iluminação Dinâmica (para a lanterna/guincho do helicóptero)
minetest.register_node("searchandrescue:glow", {
    description = "Luz de Resgate",
    drawtype = "airlike",
    paramtype = "light",
    walkable = false,
    buildable_to = true,
    pointable = false,
    sunlight_propagates = true,
    light_source = 13,
    drop = "",
    groups = {not_in_creative_inventory = 1},
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(3.0) -- Mantém a iluminação acesa por 3 segundos
    end,
    on_timer = function(pos, elapsed)
        minetest.swap_node(pos, {name = "air"})
    end,
})

-- ========================================================================
-- ENTIDADE DO GANCHO DE RESGATE
-- ========================================================================
local rope_entity = {
    hp_max = 20,
    physical = false,
    collide_with_objects = false,
    collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
    visual = "mesh",
    mesh = "helicoptero_hook.obj",
    visual_size = {x = 1, y = 1, z = 1},
    textures = {"helicoptero_hook.png"},
    glow = 8,
    
    -- Atributos de controle do gancho
    timer = 0,
    cargo_attached = nil, -- Guarda a entidade presa no gancho
}

function rope_entity.on_step(self, dtime)
    self.timer = self.timer + dtime

    -- 1. Se o gancho for desconectado do helicóptero, remove o gancho e solta a carga
    local parent = self.object:get_attach()
    if not parent then
        if self.cargo_attached and self.cargo_attached:get_pos() then
            self.cargo_attached:set_detach()
        end
        self.object:remove()
        return
    end

    -- Executa a varredura a cada 0.2 segundos para otimizar desempenho
    if self.timer < 0.2 then return end
    self.timer = 0

    local pos = self.object:get_pos()
    if not pos then return end

    -- 2. Gera ponto de luz logo abaixo do gancho
    local light_pos = vector.round(pos)
    local node = minetest.get_node(light_pos)
    if node.name == "air" then
        minetest.set_node(light_pos, {name = "searchandrescue:glow"})
    end

    -- 3. Lógica para capturar entidades (Se ainda não houver nenhuma presa)
    if not self.cargo_attached or not self.cargo_attached:get_pos() then
        self.cargo_attached = nil

        -- Procura por objetos em um raio de 2 blocos ao redor do gancho
        local objects = minetest.get_objects_inside_radius(pos, 2.0)
        for _, obj in ipairs(objects) do
            local entity = obj:get_luaentity()
            
            -- Evita prender o próprio gancho, o helicóptero pai ou jogadores
            if obj ~= self.object and obj ~= parent and not obj:is_player() then
                -- Se for uma entidade válida
                if entity then
                    -- Conecta a entidade logo abaixo do gancho
                    obj:set_attach(self.object, "", {x = 0, y = -10, z = 0}, {x = 0, y = 0, z = 0})
                    self.cargo_attached = obj
                    
                    minetest.sound_play("catch3", {
                        pos = pos,
                        gain = 1.0,
                        max_hear_distance = 10
                    }, true)
                    break
                end
            end
        end
    end
end

-- Registra a Entidade do Gancho
minetest.register_entity("searchandrescue:hook_entity", rope_entity)
