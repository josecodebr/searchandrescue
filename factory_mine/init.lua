-- ========================================================================
-- FACTORY MINE - INITIALIZATION
-- ========================================================================

-- Tabela global para exportar funções e APIs do mod
factory_mine = factory_mine or {}

-- Obtém o caminho base do mod
local modpath = minetest.get_modpath("factory_mine")

-- Carregamento dos sub-módulos do mod
dofile(modpath .. "/factory_mine.lua")
dofile(modpath .. "/robo_operario.lua")
dofile(modpath .. "/acessorios.lua")
