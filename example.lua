local APTX = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/APTX/refs/heads/main/main.lua"))()

-- ============================================================
--  CONFIGURACI脫N INICIAL
-- ============================================================

APTX:Config(
    "Mi Script",  -- t铆tulo del GUI
    true,         -- draggable (arrastrable)
    false         -- devmode (imprime logs en consola)
)


-- ============================================================
--  SECCIONES (pesta帽as del sidebar)
-- ============================================================

-- Secci贸n b谩sica (sin icono). La primera secci贸n se selecciona autom谩ticamente.
APTX:Section("Principal", nil, true)

-- Secci贸n con icono
APTX:Section("Combate", "sword")

-- Secci贸n con icono, sin marcarla como default
APTX:Section("Visual", "eye")

-- Secci贸n para demostrar interacciones entre componentes
APTX:Section("Interacciones", "settings")

-- Secci贸n vac铆a que se llenar谩 din谩micamente desde otra secci贸n
APTX:Section("Dinamico", "plus")


-- ============================================================
--  LABEL 鈥� texto informativo
-- ============================================================

-- Label simple
local lbl = APTX:Label("Principal", "Texto de ejemplo")

-- Editar texto y color despu茅s de crearlo
lbl:Edit({ text = "Texto actualizado" })
lbl:Edit({ text = "Rojo ahora", color = Color3.fromRGB(255, 80, 80) })
lbl:SetText("Texto final del label")

-- Desactivar / activar (overlay semitransparente, sin interacci贸n)
lbl:Disable()
lbl:Enable()

-- Saber si est谩 desactivado
print(lbl:IsDisabled())

-- Mover a otra secci贸n
-- lbl:MoveTo("Visual")

-- Quitar del GUI completamente
-- lbl:Remove()


-- ============================================================
--  BUTTON 鈥� bot贸n clickeable
-- ============================================================

-- Bot贸n m铆nimo (sin icono)
local btn1 = APTX:Button("Principal", "Bot贸n Simple", nil, function()
    print("Bot贸n Simple clickeado")
end)

-- Bot贸n con icono
local btn2 = APTX:Button("Principal", "Bot贸n con Icono", "star", function()
    print("Bot贸n con icono clickeado")
end)

-- Editar texto y callback de un bot贸n existente
btn1:Edit({ text = "Bot贸n Renombrado" })
btn1:Edit({ callback = function()
    print("Nuevo callback del bot贸n")
end })

-- Desactivar bot贸n (no responde a clicks, muestra overlay)
btn2:Disable()

-- Reactivarlo
btn2:Enable()

-- Mover a otra secci贸n
-- btn1:MoveTo("Visual")

-- Eliminar del GUI
-- btn2:Remove()


-- ============================================================
--  TOGGLE 鈥� interruptor on/off
-- ============================================================

-- Toggle sin icono, por defecto en OFF
local tog1 = APTX:Toggle("Principal", "Toggle B谩sico", nil, false, function(valor)
    print("Toggle B谩sico:", valor)
end)

-- Toggle con icono, por defecto en ON
local tog2 = APTX:Toggle("Principal", "Toggle con Icono", "check", true, function(valor)
    print("Toggle con Icono:", valor)
end)

-- Leer el valor actual
print("Valor toggle:", tog1:GetValue())

-- Editar texto
tog1:Edit({ text = "Toggle Renombrado" })

-- Cambiar el valor program谩ticamente (tambi茅n activa la animaci贸n)
tog1:Edit({ value = true })
tog2:Edit({ value = false })

-- Cambiar callback
tog1:Edit({ callback = function(v)
    print("Nuevo callback toggle:", v)
end })

-- Desactivar / activar
tog2:Disable()
tog2:Enable()

-- Eliminar
-- tog1:Remove()


-- ============================================================
--  SLIDER 鈥� control deslizante num茅rico
-- ============================================================

-- Slider sin icono (min, max, default)
local sld1 = APTX:Slider("Principal", "Velocidad", nil, 0, 100, 50, function(valor)
    print("Velocidad:", valor)
end)

-- Slider con icono
local sld2 = APTX:Slider("Combate", "Da帽o", "sword", 1, 500, 100, function(valor)
    print("Da帽o:", valor)
end)

-- Leer valor actual
print("Valor slider:", sld1:GetValue())

-- Establecer valor program谩ticamente (mueve el knob)
sld1:SetValue(75)

-- Editar par谩metros
sld1:Edit({ text = "Velocidad (Editada)" })
sld1:Edit({ min = 10, max = 200, value = 80 })
sld1:Edit({ callback = function(v)
    print("Nuevo callback slider:", v)
end })

-- Desactivar (no se puede arrastrar)
sld2:Disable()
sld2:Enable()

-- Mover a otra secci贸n
-- sld1:MoveTo("Visual")

-- Eliminar
-- sld2:Remove()


-- ============================================================
--  MENU 鈥� dropdown de opciones
-- ============================================================

-- Menu sin icono (texto, placeholder, icono, opciones, default, callback)
local men1 = APTX:Menu(
    "Principal",
    "Modo de juego",
    "Selecciona...",
    nil,
    { "Normal", "Dif铆cil", "Imposible" },
    "Normal",
    function(opcion)
        print("Modo seleccionado:", opcion)
    end
)

-- Menu con icono
local men2 = APTX:Menu(
    "Combate",
    "Arma",
    "Elige arma...",
    "sword",
    { "Espada", "Arco", "Magia", "Lanza" },
    "Espada",
    function(opcion)
        print("Arma seleccionada:", opcion)
    end
)

-- Leer opci贸n actualmente seleccionada
print("Opci贸n actual:", men1:GetValue())

-- Editar t铆tulo del menu
men1:Edit({ text = "Dificultad" })

-- Cambiar opciones completamente (tambi茅n cierra el dropdown si estaba abierto)


-- Cambiar la selecci贸n mostrada sin disparar el callback
men1:Edit({ selected = "Dif铆cil" })

-- Reemplazar opciones usando el m茅todo directo
men2:SetOptions({ "Espada", "Arco", "Bomba", "Daga", "Hacha" })

-- Cambiar callback
men1:Edit({ callback = function(v)
    print("Nuevo callback menu:", v)
end })

-- Desactivar (no se puede abrir el dropdown)
men2:Disable()
men2:Enable()

-- Eliminar
-- men1:Remove()


-- ============================================================
--  INPUT 鈥� caja de texto
-- ============================================================

-- Input sin icono (el callback se dispara al presionar Enter)
local inp1 = APTX:Input(
    "Principal",
    "Nombre de usuario",
    nil,
    "Escribe aqu铆...",
    function(texto)
        print("Texto ingresado:", texto)
    end
)

-- Input con icono
local inp2 = APTX:Input(
    "Visual",
    "Color (hex)",
    "palette",
    "#RRGGBB",
    function(texto)
        print("Color:", texto)
    end
)

-- Leer el texto actual
print("Texto input:", inp1:GetValue())

-- Establecer texto program谩ticamente
inp1:SetValue("UsuarioEjemplo")

-- Editar label, placeholder, valor y callback
inp1:Edit({ text = "Nick de jugador" })
inp1:Edit({ placeholder = "Tu nick aqu铆..." })
inp1:Edit({ value = "NuevoValor" })
inp1:Edit({ callback = function(t)
    print("Nuevo callback input:", t)
end })

-- Desactivar (no se puede escribir ni enfocar)
inp2:Disable()
inp2:Enable()

-- Mover secci贸n
-- inp1:MoveTo("Combate")

-- Eliminar
-- inp2:Remove()


-- ============================================================
--  INTERACCIONES ENTRE COMPONENTES
--  (agregar/modificar/eliminar desde callbacks de otros)
-- ============================================================

local seccion = "Interacciones"

-- Label de estado
local lblEstado = APTX:Label(seccion, "Estado: sin componentes extra")

-- Variable para guardar el componente creado din谩micamente
local sliderDinamico = nil
local menuDinamico = nil

-- Bot贸n que agrega un Slider a la secci贸n "Dinamico" al hacer click
APTX:Button(seccion, "Agregar Slider a Dinamico", "plus", function()
    if sliderDinamico then
        lblEstado:SetText("Estado: slider ya existe")
        return
    end
    sliderDinamico = APTX:Slider("Dinamico", "Slider Creado", nil, 0, 10, 5, function(v)
        print("Slider din谩mico:", v)
    end)
    lblEstado:SetText("Estado: slider agregado")
end)

-- Bot贸n que elimina el slider din谩mico
APTX:Button(seccion, "Eliminar Slider de Dinamico", "trash", function()
    if sliderDinamico then
        sliderDinamico:Remove()
        sliderDinamico = nil
        lblEstado:SetText("Estado: slider eliminado")
    else
        lblEstado:SetText("Estado: no hay slider que eliminar")
    end
end)

-- Toggle que desactiva/activa el slider din谩mico
APTX:Toggle(seccion, "Bloquear Slider Din谩mico", "lock", false, function(on)
    if sliderDinamico then
        if on then
            sliderDinamico:Disable()
            lblEstado:SetText("Estado: slider bloqueado")
        else
            sliderDinamico:Enable()
            lblEstado:SetText("Estado: slider desbloqueado")
        end
    else
        lblEstado:SetText("Estado: no hay slider todav铆a")
    end
end)

-- Bot贸n que agrega un Menu a la secci贸n "Dinamico" y lo edita inmediatamente
APTX:Button(seccion, "Agregar y Editar Menu", "list", function()
    if menuDinamico then
        menuDinamico:Edit({ options = { "A", "B", "C", "D", "E" } })
        menuDinamico:Edit({ text = "Menu Editado" })
        lblEstado:SetText("Estado: menu editado")
        return
    end
    menuDinamico = APTX:Menu("Dinamico", "Menu Din谩mico", "Elige...", nil,
        { "Opcion 1", "Opcion 2", "Opcion 3" }, "Opcion 1",
        function(v)
            print("Menu din谩mico:", v)
            lblEstado:SetText("Estado: seleccionaste " .. v)
        end
    )
    lblEstado:SetText("Estado: menu agregado")
end)

-- Slider que al moverse edita el texto de un label en tiempo real
local lblSliderVivo = APTX:Label(seccion, "Valor del slider: 0")
APTX:Slider(seccion, "Slider en vivo", nil, 0, 100, 0, function(v)
    lblSliderVivo:SetText("Valor del slider: " .. tostring(v))
end)

-- Menu que al cambiar de opci贸n desactiva o activa un bot贸n
local btnControlado = APTX:Button(seccion, "Bot贸n controlado por menu", "check", function()
    print("Bot贸n controlado clickeado")
end)

APTX:Menu(seccion, "Control de bot贸n", nil, nil,
    { "Activado", "Desactivado" }, "Activado",
    function(v)
        if v == "Desactivado" then
            btnControlado:Disable()
            lblEstado:SetText("Estado: bot贸n desactivado por menu")
        else
            btnControlado:Enable()
            lblEstado:SetText("Estado: bot贸n activado por menu")
        end
    end
)

-- Input que al escribir mueve un componente de secci贸n
local inp3 = APTX:Input(seccion, "Mover slider a secci贸n", nil, "Principal / Visual / Combate", function(texto)
    if sliderDinamico then
        local seccionesValidas = { Principal = true, Visual = true, Combate = true, Dinamico = true }
        if seccionesValidas[texto] then
            sliderDinamico:MoveTo(texto)
            lblEstado:SetText("Estado: slider movido a " .. texto)
        else
            lblEstado:SetText("Estado: secci贸n no v谩lida")
        end
    else
        lblEstado:SetText("Estado: crea el slider primero")
    end
end)


-- ============================================================
--  NOTIFY 鈥� notificaciones flotantes
-- ============================================================

-- Notificaci贸n m铆nima (solo t铆tulo y contenido, sin duraci贸n = persiste hasta cerrar)
local n1 = APTX:Notify({
    title   = "Aviso",
    content = "Esta notificaci贸n no tiene tiempo l铆mite.",
})

-- Notificaci贸n con duraci贸n (se cierra sola)
local n2 = APTX:Notify({
    title    = "Cargando...",
    content  = "Espera mientras se procesa.",
    duration = 4,
    type     = "neutral",
})

-- Notificaci贸n tipo success
local n3 = APTX:Notify({
    title    = "脡xito",
    content  = "El proceso termin贸 correctamente.",
    duration = 3,
    type     = "success",
})

-- Notificaci贸n tipo warning
local n4 = APTX:Notify({
    title    = "Advertencia",
    content  = "Algo podr铆a salir mal.",
    duration = 3,
    type     = "warning",
})

-- Notificaci贸n tipo error
local n5 = APTX:Notify({
    title    = "Error",
    content  = "Algo sali贸 muy mal.",
    duration = 3,
    type     = "error",
})

-- Notificaci贸n con icono en topbar
local n6 = APTX:Notify({
    title         = "Con Avatar",
    content       = "Esta tiene icono en la barra superior.",
    duration      = 5,
    type          = "neutral",
    ["topbar-icon"] = "rbxassetid://7072725342",
})

-- Notificaci贸n con icono en el cuerpo
local n7 = APTX:Notify({
    title            = "Con Icono",
    content          = "Esta tiene icono en el cuerpo del mensaje.",
    duration         = 5,
    type             = "success",
    ["content-icon"] = "rbxassetid://7072725342",
})

-- Notificaci贸n con ambos iconos
local n8 = APTX:Notify({
    title            = "Completa",
    content          = "Tiene icono arriba y en el cuerpo.",
    duration         = 5,
    type             = "warning",
    ["topbar-icon"]  = "rbxassetid://7072725342",
    ["content-icon"] = "rbxassetid://7072725342",
})

-- Notificaci贸n con sonido
local n9 = APTX:Notify({
    title    = "Con Sonido",
    content  = "Reproduce un sonido al aparecer.",
    duration = 4,
    type     = "neutral",
    sound    = "rbxassetid://9120285940",
})

-- Notificaci贸n con botones de acci贸n (hasta 3)
local n10 = APTX:Notify({
    title   = "驴Confirmar acci贸n?",
    content = "Esta acci贸n no se puede deshacer.",
    type    = "error",
    buttons = {
        {
            label    = "Confirmar",
            color    = Color3.fromRGB(0, 200, 80),
            callback = function()
                print("Confirmado")
            end,
        },
        {
            label    = "Cancelar",
            color    = Color3.fromRGB(200, 50, 50),
            callback = function()
                print("Cancelado")
            end,
        },
        {
            label    = "Info",
            color    = Color3.fromRGB(80, 80, 200),
            callback = function()
                print("Info clickeada")
            end,
        },
    },
})

-- Notificaci贸n escalada (size < 1 = m谩s peque帽a, size > 1 = m谩s grande)
local n11 = APTX:Notify({
    title    = "Peque帽a",
    content  = "Esta notificaci贸n es m谩s compacta.",
    duration = 4,
    type     = "neutral",
    size     = 0.7,
})

local n12 = APTX:Notify({
    title    = "Grande",
    content  = "Esta notificaci贸n es m谩s grande de lo normal.",
    duration = 4,
    type     = "success",
    size     = 1.4,
})


-- ============================================================
--  M脡TODOS DE NOTIFICACIONES
-- ============================================================

-- :Edit 鈥� editar t铆tulo, contenido, iconos o resetear el timer
task.delay(1, function()
    n1:Edit({ title = "Aviso Editado" })
    n1:Edit({ content = "Contenido cambiado desde c贸digo." })
    n1:Edit({
        title   = "Ambos Editados",
        content = "T铆tulo y cuerpo al mismo tiempo.",
    })
    -- Resetear el timer (si tiene duration)
    n2:Edit({ resetTimer = 5 })
    -- Cambiar iconos si existen
    n6:Edit({ ["topbar-icon"] = "rbxassetid://9120285940" })
    n7:Edit({ ["content-icon"] = "rbxassetid://9120285940" })
end)

-- :SetBody 鈥� cambiar solo el texto del cuerpo, con efecto pulse opcional
task.delay(2, function()
    n1:SetBody("Cuerpo reemplazado r谩pido.")
    n2:SetBody("Ahora con pulse.", true)  -- true = efecto de parpadeo
end)

-- :SetAccent 鈥� cambiar el color del borde del icono del cuerpo
task.delay(1.5, function()
    n7:SetAccent(Color3.fromRGB(255, 200, 0))
end)

-- :Flash 鈥� hace un flash en el borde de la notificaci贸n con un color
task.delay(2, function()
    n1:Flash(Color3.fromRGB(255, 0, 0))    -- flash rojo
    n3:Flash()                              -- flash blanco (por defecto)
end)

-- :Shake 鈥� sacude la tarjeta de la notificaci贸n
task.delay(3, function()
    n1:Shake()
end)

-- :Close 鈥� cierra con animaci贸n, con callback opcional al terminar
task.delay(6, function()
    n1:Close(function()
        print("n1 cerrada y destruida")
    end)
end)

-- :Destroy 鈥� cierra inmediatamente con animaci贸n (sin callback)
task.delay(5, function()
    n4:Destroy()
end)


-- ============================================================
--  OTROS M脡TODOS GLOBALES
-- ============================================================

-- Mostrar / ocultar el GUI completo (tambi茅n lo hace el bot贸n de men煤 flotante)
task.delay(10, function()
    APTX:ToggleVisibility()   -- oculta
    task.wait(2)
    APTX:ToggleVisibility()   -- vuelve a mostrar
end)

-- Seleccionar una secci贸n program谩ticamente
task.delay(1, function()
    APTX:SelectSection("Combate")
end)

-- Obtener referencia a una secci贸n por nombre
local secRef = APTX:GetSection("Visual")
if secRef then
    print("Secci贸n encontrada:", secRef.Name)
end
