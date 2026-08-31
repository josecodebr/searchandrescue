-- ========================================================================
-- FACTORY MINE - ACESSÓRIOS E ILUMINAÇÃO
-- ========================================================================

-- 1. LUZ INDUSTRIAL DE MINA (Luminária de Teto)
minetest.register_node("factory_mine:factory_mine_light", {
    description = "Luz Industrial de Mina",
    drawtype = "nodebox",
    
    paramtype = "light",
    use_texture_alpha = "clip",
    sunlight_propagates = true,
    light_source = 13,
    is_ground_content = false,
    drop = "factory_mine:factory_mine_light",
    
    -- Design da luminária presa ao teto
    node_box = {
        type = "fixed",
        fixed = {
            {-0.25, 0.3, -0.25, 0.25, 0.5, 0.25}, -- Corpo principal da luminária
        },
    },
    
    groups = {
        cracky = 3,
        oddly_breakable_by_hand = 3,
        not_in_creative_inventory = 1
    },
    
    tiles = {
        {
            name = "factory_mine_light.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1.0,
            },
        }
    },
})
