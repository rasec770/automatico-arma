---@diagnostic disable: undefined-global
-- Archivo: control.lua

-- Asegúrate de que la variable global esté inicializada
if not global then
    global = {}
end

-- Variable global para mantener el estado del movimiento
global.player_movement = global.player_movement or {}

-- Función para mover al jugador
local function move_player(command)
    local player = game.get_player(command.player_index)
    local direction = command.parameter

    if direction == "stop" then
        global.player_movement[player.index] = nil
        player.walking_state = {walking = false}
        player.print("Detenido")
    elseif defines.direction[direction] then
        global.player_movement[player.index] = defines.direction[direction]
        player.print("Moviendo hacia " .. direction)
    else
        player.print("Dirección no válida. Usa: north, south, east, west, northeast, northwest, southeast, southwest, o stop")
    end
end

-- Función para actualizar el movimiento del jugador
local function update_player_movement()
    for player_index, direction in pairs(global.player_movement) do
        local player = game.get_player(player_index)
        if player and player.valid then
            player.walking_state = {walking = true, direction = direction}
        else
            global.player_movement[player_index] = nil
        end
    end
end

-- Registrar el comando
commands.add_command("move", "Mueve al jugador en la dirección especificada", move_player)

-- Evento que se ejecuta en cada tick del juego
script.on_event(defines.events.on_tick, update_player_movement)


-- local function count_resources(command)
--     -- Obtener la superficie y posición del jugador que ejecuta el comando
--     local player = game.player
--     if not player then
--         game.print("Este comando debe ser ejecutado por un jugador.")
--         return
--     end

--     local surface = player.surface
--     local position = player.position

--     -- Definir el radio de búsqueda (por ejemplo, 20 tiles)
--     local radius = 20
--     if command.parameter then
--         radius = tonumber(command.parameter) or 20
--     end

--     -- Buscar los recursos en el área especificada
--     local resources = surface.find_entities_filtered{
--         position = position,
--         radius = radius,
--         type = "resource"
--     }

--     -- Contar los recursos por nombre
--     local resource_counts = {}

--     for _, resource in pairs(resources) do
--         local name = resource.name
--         resource_counts[name] = (resource_counts[name] or 0) + 1
--     end

--     -- Mostrar los resultados en la consola del juego
--     if next(resource_counts) then
--         for name, count in pairs(resource_counts) do
--             player.print("Recurso: " .. name .. " | Cantidad: " .. count)
--         end
--     else
--         player.print("No se encontraron recursos en un radio de " .. radius .. " tiles.")
--     end
-- end


-- -- Registro del comando "count-resources"
-- commands.add_command("count-resources", "Cuenta los recursos en un área alrededor del jugador.",  count_resources)




-- Función para contar recursos, árboles y rocas
local function count_resources(resource_type)
    local count = 0
    for _, entity in pairs(game.surfaces[1].find_entities_filtered{type=resource_type}) do
        count = count + 1
    end
    return count
end

-- Comando personalizado para contar recursos
commands.add_command("count_resources", "Cuenta la cantidad de recursos especificados", function(command)
    local resource_type = command.parameter
    if resource_type then
        local count = count_resources(resource_type)
        game.player.print(resource_type .. " count: " .. count)
    else
        game.player.print("Por favor, especifica un tipo de recurso. Ejemplo: /count_resources resource")
    end
end)