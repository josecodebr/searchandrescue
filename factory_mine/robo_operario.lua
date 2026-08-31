-- ========================================================================
-- FACTORY MINE - ROBÔ OPERÁRIO
-- ========================================================================

-- 1. REGISTRO DO ITEM DE INVENTÁRIO (OPCIONAL/CRAFTABLE)
minetest.register_craftitem("factory_mine:robo_operario", {
    description = "Robô Operário Industrial",
    inventory_image = "factory_mine_icon.png",
    stack_max = 1,

    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing or pointed_thing.type ~= "node" then
            return itemstack
        end

        local spawn_pos = pointed_thing.above
        local obj = minetest.add_entity(spawn_pos, "factory_mine:robo_operario")

        if obj then
            if placer then
                obj:set_yaw(placer:get_look_horizontal())
            end

            minetest.sound_play("transformation", {
                pos = spawn_pos,
                gain = 1.0,
                max_hear_distance = 10
            }, true)

            local pname = placer and placer:get_player_name() or ""
            if not (minetest.is_creative_enabled and minetest.is_creative_enabled(pname)) then
                itemstack:take_item()
            end
        end

        return itemstack
    end,
})

-- 2. REGISTRO DA ENTIDADE DO ROBÔ
minetest.register_entity("factory_mine:robo_operario", {
    hp_max = 100,
    physical = false,
    collide_with_objects = false,
    
    visual = "mesh",
    mesh = "robo_operario.b3d",
    textures = {"factory_mine.png"},
    visual_size = {x = 1, y = 1, z = 1},

    sound_handle = nil,

    on_activate = function(self, staticdata, dtime_s)
        self.object:set_armor_groups({immortal = 1})

        -- Inicia a animação de trabalho do modelo .b3d (frames 0 a 100 na velocidade 30)
        self.object:set_animation({x = 0, y = 100}, 30, 0, true)

        -- Inicia o áudio em loop atrelado à posição do robô
        self.sound_handle = minetest.sound_play("helicopter_motor", {
            object = self.object,
            gain = 0.8,
            max_hear_distance = 20,
            loop = true,
        })
    end,

    -- Garante o encerramento limpo do áudio ao remover a entidade
    on_step = function(self, dtime)
        -- Caso o robô seja desanexado ou precise de verificações adicionais de estado
    end,

    on_deactivate = function(self)
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end
    end,

    on_punch = function(self, puncher)
		return true
        --[[ if not puncher or not puncher:is_player() then return end

        -- Se socado por um jogador, interrompe o áudio e remove
		
        if self.sound_handle then
            minetest.sound_stop(self.sound_handle)
            self.sound_handle = nil
        end

        local inv = puncher:get_inventory()
        if inv then
            inv:add_item("main", "factory_mine:robo_operario")
        end

        self.object:remove()]]
    end,
})
