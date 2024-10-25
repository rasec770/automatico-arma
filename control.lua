---@diagnostic disable: undefined-global
-- Archivo: control.lua

-- Asegúrate de que la variable global esté inicializada
Global = Global or {}

-- Variable Global para mantener el estado del movimiento
Global.player_movement = Global.player_movement or {}

-- Función para mover al jugador
local function move_player(command)
    local player = game.get_player(command.player_index)
    local direction = command.parameter

    if direction == "stop" then
        Global.player_movement[player.index] = nil
        player.walking_state = {walking = false}
        player.print("Detenido")
    elseif defines.direction[direction] then
        Global.player_movement[player.index] = defines.direction[direction]
        player.print("Moviendo hacia " .. direction)
    else
        player.print("Dirección no válida. Usa: north, south, east, west, northeast, northwest, southeast, southwest, o stop")
    end
end

-- Función para actualizar el movimiento del jugador
local function update_player_movement()
    for player_index, direction in pairs(Global.player_movement) do
        local player = game.get_player(player_index)
        if player and player.valid then
            player.walking_state = {walking = true, direction = direction}
        else
            Global.player_movement[player_index] = nil
        end
    end
end

-- Registrar el comando
commands.add_command("move", "Mueve al jugador en la dirección especificada", move_player)

-- Evento que se ejecuta en cada tick del juego
script.on_event(defines.events.on_tick, update_player_movement)


-- Métodos comunes del objeto player:
-- print(message): Imprime un mensaje en la consola del jugador.
-- teleport(position, surface): Teletransporta al jugador a una posición específica en una superficie específica.
-- clear_items_inside(): Limpia todos los ítems dentro del inventario del jugador.
-- insert(item): Inserta un ítem en el inventario del jugador.
-- remove_item(item): Remueve un ítem del inventario del jugador.
-- get_inventory(inventory_type): Obtiene el inventario del jugador de un tipo específico.
-- get_main_inventory(): Obtiene el inventario principal del jugador.
-- get_quickbar(): Obtiene la barra rápida del jugador.
-- get_cursor_stack(): Obtiene la pila de ítems en el cursor del jugador.
-- get_blueprint_book(): Obtiene el libro de planos del jugador.

commands.add_command("teleport", "Teletransporta al jugador a una posición específica.", function(command)
    local player = game.get_player(command.player_index)
    local params = {}
    for param in string.gmatch(command.parameter, "%S+") do
        table.insert(params, param)
    end

    if #params ~= 2 then
        player.print("Uso incorrecto del comando. Uso correcto: /teleport <x> <y>")
        return
    end

    local x = tonumber(params[1])
    local y = tonumber(params[2])

    if not x or not y then
        player.print("Los parámetros deben ser números. Uso correcto: /teleport <x> <y>")
        return
    end

    local position = {x = x, y = y}
    local surface = player.surface

    player.teleport(position, surface)
end)

-- Ejemplo como ejecutar el comando teleport:
-- /teleport 0 0 


-- Buscar la entidad más cercana al jugador dentro de un radio específico
local function find_nearest_entity(player, radius)
    local position = player.position
    local surface = player.surface
    local entities = surface.find_entities_filtered{position = position, radius = radius}

    if #entities > 0 then
        return entities[1] -- Devuelve la primera entidad encontrada
    else
        return nil
    end
end

-- Minar una entidad específica manualmente
local function mine_entity(player, entity)
    if entity and entity.valid then
        if player.can_reach_entity(entity) then
            player.print("Has minado la entidad " .. entity.name)
            player.mine_entity(entity)
        else
            player.print("No puedes alcanzar esta entidad.")
        end
    else
        player.print("La entidad ya no es válida.")
    end
end

-- Tabla global para almacenar el estado del comando
Global.mine_command = Global.mine_command or {}


commands.add_command("mine", "Mina la entidad más cercana dentro de un radio específico una cierta cantidad de veces.", function(command)
    local player = game.get_player(command.player_index)
    local radius = 2 -- Radio de búsqueda en tiles
    local times = tonumber(command.parameter) or 1 -- Cantidad de veces a minar, por defecto 1

    local interval = 1 -- Intervalo en segundos

    -- Almacenar el estado del comando en la tabla Global
    Global.mine_command[player.index] = {
        player = player,
        radius = radius,
        times = times,
        current = 0,
        last_tick = game.tick, -- Almacenar el tick actual
        interval_ticks = interval * 60 -- Convertir segundos a ticks
    }

    player.print("Comenzando a minar " .. times .. " veces cada " .. interval .. " segundos.")
end)

-- Evento on_tick para procesar el minado
script.on_event(defines.events.on_tick, function(event)
    for player_index, command in pairs(Global.mine_command) do
        if command.current < command.times then
            if (game.tick - command.last_tick) >= command.interval_ticks then
                local entity = find_nearest_entity(command.player, command.radius)

                if entity and entity.valid then
                    mine_entity(command.player, entity)
                    command.current = command.current + 1
                    command.last_tick = game.tick -- Actualizar el último tick
                else
                    command.player.print("No hay ninguna entidad cercana para minar.")
                    Global.mine_command[player_index] = nil
                    break
                end
            end
        else
            command.player.print("Minado completado.")
            Global.mine_command[player_index] = nil
        end
    end
end)

-- Ejemplo como ejecutar el comando mine:
-- /mine 100