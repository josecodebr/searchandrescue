-- ========================================================================
-- CONFIGURAÇÕES E ESCALA
-- ========================================================================
searchandrescue = searchandrescue or {}
searchandrescue.carga_scale = 0.50 -- Ajuste o tamanho geral das cargas aqui

local scale = searchandrescue.carga_scale

-- Tabela de cargas cadastradas (Adicione novos itens facilmente nesta lista!)
local cargas_lista = {
    {
        name = "tanque_toxico",
        mesh = "tanque_toxico.obj",
        texture = "tanque_toxico.png",
        icon = "tanque_toxico_icon.png",
        description = "Tanque Tóxico",
        -- Caixas de colisão personalizadas para o formato do tanque (Escaladas)
        box = {-0.6 * scale, 0.0, -0.6 * scale, 0.6 * scale, 1.2 * scale, 0.6 * scale},
    },
}

-- ========================================================================
-- REGISTRO DINÂMICO DE ITENS E ENTIDADES
-- ========================================================================
for _, def in ipairs(cargas_lista) do
    local item_id = "searchandrescue:" .. def.name
    local box = def.box or {-0.5 * scale, 0.0, -0.5 * scale, 0.5 * scale, 1.0 * scale, 0.5 * scale}

    -- 1. Registro do Item de Inventário
    minetest.register_craftitem(item_id, {
        description = def.description or def.name,
        inventory_image = def.icon,
        wield_image = def.icon,
        stack_max = 1,

        on_place = function(itemstack, placer, pointed_thing)
            if not pointed_thing or pointed_thing.type ~= "node" then
                return itemstack
            end

            local pos_above = pointed_thing.above
            local node = minetest.get_node(pos_above)

            -- Garante que só posiciona em nós onde é possível construir/spawnar (ar, água, etc.)
            local def_node = minetest.registered_nodes[node.name]
            if not def_node or not def_node.buildable_to then
                return itemstack
            end

            -- Instancia a entidade 3D no mundo
            local obj = minetest.add_entity(pos_above, item_id)
            if obj and placer then
                obj:set_yaw(placer:get_look_horizontal())
            end

            -- Consome o item se não estiver no modo criativo
            local player_name = placer and placer:get_player_name() or ""
            if not (minetest.is_creative_enabled and minetest.is_creative_enabled(player_name)) then
                itemstack:take_item()
            end

            return itemstack
        end,
    })

    -- 2. Registro da Entidade 3D (Object)
    minetest.register_entity(item_id, {
        hp_max = 200,
        physical = true,
        weight = 5,
        collide_with_objects = true, -- Permite colisão sólida com outros objetos/veículos

        selectionbox = box,
        collisionbox = box,

        visual = "mesh",
        mesh = def.mesh,
        textures = { def.texture },
        visual_size = {x = scale, y = scale, z = scale},

        is_visible = true,
        backface_culling = false,

        on_activate = function(self, staticdata, dtime_s)
            self.object:set_armor_groups({immortal = 1})
            self.object:set_acceleration({x = 0, y = -9.81, z = 0})
        end,

        on_step = function(self, dtime)
            -- Se a carga NÃO estiver presa ao gancho do helicóptero, aplica gravidade contínua
            if not self.object:get_attach() then
                local vel = self.object:get_velocity()
                if vel and (math.abs(vel.x) > 0.01 or math.abs(vel.z) > 0.01 or vel.y ~= 0) then
                    self.object:set_acceleration({x = 0, y = -9.81, z = 0})
                end
            else
                -- Quando anexada ao gancho, zera a aceleração própria
                self.object:set_acceleration({x = 0, y = 0, z = 0})
            end
        end,

        -- Permite ao jogador socar/clicar para devolver a carga ao inventário
        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)
            if not puncher or not puncher:is_player() then return end

            -- Se estiver presa ao guincho, desanexa primeiro
            if self.object:get_attach() then
                self.object:set_detach()
            end

            local inv = puncher:get_inventory()
            if inv then
                local leftover = inv:add_item("main", item_id)
                -- Se não sobrou item (inventário tinha espaço), remove a entidade do mundo
                if leftover:is_empty() then
                    self.object:remove()
                end
            end
        end,
    })
end
