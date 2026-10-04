--[[

    Milenium Library
    -> Made by @finobe 
    -> Kind of got bored idk what to do with life
    -> Idk who or why this got leaked, ui was VERY popular and high in demand with customers
]]

-- Variables 
    local uis = game:GetService("UserInputService") 
    local players = game:GetService("Players") 
    local ws = game:GetService("Workspace")
    local rs = game:GetService("ReplicatedStorage")
    local http_service = game:GetService("HttpService")
    local gui_service = game:GetService("GuiService")
    local lighting = game:GetService("Lighting")
    local run = game:GetService("RunService")
    local stats = game:GetService("Stats")
    local coregui = game:GetService("CoreGui")
    local debris = game:GetService("Debris")
    local tween_service = game:GetService("TweenService")
    local sound_service = game:GetService("SoundService")

    local vec2 = Vector2.new
    local vec3 = Vector3.new
    local dim2 = UDim2.new
    local dim = UDim.new 
    local rect = Rect.new
    local cfr = CFrame.new
    local empty_cfr = cfr()
    local point_object_space = empty_cfr.PointToObjectSpace
    local angle = CFrame.Angles
    local dim_offset = UDim2.fromOffset

    local color = Color3.new
    local rgb = Color3.fromRGB
    local hex = Color3.fromHex
    local hsv = Color3.fromHSV
    local rgbseq = ColorSequence.new
    local rgbkey = ColorSequenceKeypoint.new
    local numseq = NumberSequence.new
    local numkey = NumberSequenceKeypoint.new

    local camera = ws.CurrentCamera
    local lp = players.LocalPlayer 
    local mouse = lp:GetMouse() 
    local gui_offset = gui_service:GetGuiInset().Y

    local max = math.max 
    local floor = math.floor 
    local min = math.min 
    local abs = math.abs 
    local noise = math.noise
    local rad = math.rad 
    local random = math.random 
    local pow = math.pow 
    local sin = math.sin 
    local pi = math.pi 
    local tan = math.tan 
    local atan2 = math.atan2 
    local clamp = math.clamp 

    local insert = table.insert 
    local find = table.find 
    local remove = table.remove
    local concat = table.concat
-- 

-- Library init
    getgenv().library = {
        directory = "milenium",
        folders = {
            "/fonts",
            "/configs",
        },
        flags = {},
        config_flags = {},
        connections = {},   
        notifications = {notifs = {}},
        current_open; 
    }

    -- Palette roles. Every element is built with the original Milenium colors (base palette below);
    -- library:create / library:tween translate those literals to the active theme, and
    -- library:set_theme repaints everything already on screen by mapping old theme color -> role -> new color.
    -- (black borders and pure white are left alone - white is used as the base for gradients/images)
    local palette_roles = {
        "accent", "background", "stroke", "divider", "info_bar", "tab_button", "section_outline", "section",
        "section_header", "separator", "scrollbar", "element", "toggle_off", "toggle_off_inner", "checkbox_off",
        "knob_off", "knob_on", "text", "text_dim", "text_dim2", "text_tab", "text_sub", "text_info",
        "text_info2", "text_hover",
    }

    local theme_presets = {
        ["Milenium"] = {
            accent = rgb(155, 150, 219), background = rgb(14, 14, 16), stroke = rgb(23, 23, 29),
            divider = rgb(21, 21, 23), info_bar = rgb(23, 23, 25), tab_button = rgb(29, 29, 29),
            section_outline = rgb(25, 25, 29), section = rgb(22, 22, 24), section_header = rgb(19, 19, 21),
            separator = rgb(36, 36, 37), scrollbar = rgb(44, 44, 46), element = rgb(33, 33, 35),
            toggle_off = rgb(58, 58, 62), toggle_off_inner = rgb(50, 50, 50), checkbox_off = rgb(67, 67, 68),
            knob_off = rgb(86, 86, 88), knob_on = rgb(244, 244, 244), text = rgb(245, 245, 245),
            text_dim = rgb(72, 72, 73), text_dim2 = rgb(72, 72, 72), text_tab = rgb(62, 62, 63),
            text_sub = rgb(86, 86, 87), text_info = rgb(130, 130, 130), text_info2 = rgb(145, 145, 145),
            text_hover = rgb(140, 140, 140),
        },
        ["Midnight"] = {
            accent = rgb(110, 150, 255), background = rgb(11, 13, 20), stroke = rgb(24, 28, 42),
            divider = rgb(20, 23, 34), info_bar = rgb(17, 20, 30), tab_button = rgb(24, 29, 45),
            section_outline = rgb(26, 30, 46), section = rgb(16, 19, 29), section_header = rgb(14, 17, 26),
            separator = rgb(32, 37, 54), scrollbar = rgb(48, 56, 82), element = rgb(29, 34, 51),
            toggle_off = rgb(52, 58, 80), toggle_off_inner = rgb(44, 50, 70), checkbox_off = rgb(60, 67, 92),
            knob_off = rgb(92, 100, 130), knob_on = rgb(242, 245, 255), text = rgb(236, 240, 252),
            text_dim = rgb(96, 106, 138), text_dim2 = rgb(97, 107, 139), text_tab = rgb(86, 95, 125),
            text_sub = rgb(112, 122, 155), text_info = rgb(128, 138, 168), text_info2 = rgb(142, 151, 180),
            text_hover = rgb(160, 170, 200),
        },
        ["Sakura"] = {
            accent = rgb(255, 128, 170), background = rgb(18, 12, 16), stroke = rgb(40, 24, 33),
            divider = rgb(32, 20, 27), info_bar = rgb(26, 17, 22), tab_button = rgb(42, 25, 34),
            section_outline = rgb(44, 27, 36), section = rgb(24, 16, 21), section_header = rgb(21, 14, 18),
            separator = rgb(50, 33, 42), scrollbar = rgb(78, 50, 64), element = rgb(45, 29, 38),
            toggle_off = rgb(74, 50, 62), toggle_off_inner = rgb(64, 42, 54), checkbox_off = rgb(84, 58, 71),
            knob_off = rgb(128, 96, 111), knob_on = rgb(255, 244, 248), text = rgb(252, 238, 244),
            text_dim = rgb(138, 104, 120), text_dim2 = rgb(139, 105, 121), text_tab = rgb(124, 92, 107),
            text_sub = rgb(150, 116, 131), text_info = rgb(168, 136, 150), text_info2 = rgb(180, 150, 163),
            text_hover = rgb(198, 168, 181),
        },
        ["Emerald"] = {
            accent = rgb(72, 214, 150), background = rgb(10, 16, 14), stroke = rgb(22, 36, 31),
            divider = rgb(18, 29, 25), info_bar = rgb(15, 24, 21), tab_button = rgb(22, 38, 32),
            section_outline = rgb(24, 40, 34), section = rgb(14, 22, 19), section_header = rgb(12, 19, 16),
            separator = rgb(30, 48, 41), scrollbar = rgb(44, 72, 61), element = rgb(26, 42, 36),
            toggle_off = rgb(46, 68, 59), toggle_off_inner = rgb(38, 58, 50), checkbox_off = rgb(54, 78, 68),
            knob_off = rgb(88, 118, 105), knob_on = rgb(240, 255, 248), text = rgb(234, 250, 243),
            text_dim = rgb(92, 128, 113), text_dim2 = rgb(93, 129, 114), text_tab = rgb(80, 114, 100),
            text_sub = rgb(106, 142, 127), text_info = rgb(124, 158, 143), text_info2 = rgb(138, 170, 156),
            text_hover = rgb(156, 188, 174),
        },
        ["Amber"] = {
            accent = rgb(255, 176, 72), background = rgb(17, 14, 10), stroke = rgb(38, 30, 21),
            divider = rgb(30, 24, 17), info_bar = rgb(25, 20, 14), tab_button = rgb(40, 31, 21),
            section_outline = rgb(42, 33, 23), section = rgb(23, 19, 13), section_header = rgb(20, 16, 11),
            separator = rgb(50, 40, 28), scrollbar = rgb(78, 62, 42), element = rgb(44, 35, 24),
            toggle_off = rgb(72, 59, 43), toggle_off_inner = rgb(62, 50, 36), checkbox_off = rgb(82, 67, 49),
            knob_off = rgb(126, 108, 84), knob_on = rgb(255, 250, 240), text = rgb(252, 245, 234),
            text_dim = rgb(136, 116, 90), text_dim2 = rgb(137, 117, 91), text_tab = rgb(122, 103, 79),
            text_sub = rgb(150, 130, 104), text_info = rgb(166, 148, 124), text_info2 = rgb(178, 161, 138),
            text_hover = rgb(196, 180, 158),
        },
        ["Crimson"] = {
            accent = rgb(235, 72, 88), background = rgb(15, 11, 12), stroke = rgb(34, 22, 24),
            divider = rgb(27, 18, 20), info_bar = rgb(22, 15, 17), tab_button = rgb(37, 23, 26),
            section_outline = rgb(39, 25, 28), section = rgb(21, 15, 16), section_header = rgb(18, 13, 14),
            separator = rgb(46, 31, 34), scrollbar = rgb(72, 48, 53), element = rgb(40, 27, 30),
            toggle_off = rgb(66, 48, 52), toggle_off_inner = rgb(57, 41, 45), checkbox_off = rgb(76, 56, 60),
            knob_off = rgb(118, 94, 99), knob_on = rgb(255, 244, 245), text = rgb(248, 236, 238),
            text_dim = rgb(126, 100, 105), text_dim2 = rgb(127, 101, 106), text_tab = rgb(112, 88, 93),
            text_sub = rgb(140, 114, 119), text_info = rgb(158, 134, 139), text_info2 = rgb(170, 148, 152),
            text_hover = rgb(190, 168, 172),
        },
        ["Mono"] = {
            accent = rgb(185, 185, 196), background = rgb(12, 12, 12), stroke = rgb(30, 30, 30),
            divider = rgb(24, 24, 24), info_bar = rgb(20, 20, 20), tab_button = rgb(34, 34, 34),
            section_outline = rgb(35, 35, 35), section = rgb(19, 19, 19), section_header = rgb(16, 16, 16),
            separator = rgb(42, 42, 42), scrollbar = rgb(66, 66, 66), element = rgb(38, 38, 38),
            toggle_off = rgb(62, 62, 62), toggle_off_inner = rgb(54, 54, 54), checkbox_off = rgb(70, 70, 70),
            knob_off = rgb(108, 108, 110), knob_on = rgb(24, 24, 26), text = rgb(240, 240, 240),
            text_dim = rgb(110, 110, 110), text_dim2 = rgb(111, 111, 111), text_tab = rgb(98, 98, 98),
            text_sub = rgb(124, 124, 124), text_info = rgb(142, 142, 142), text_info2 = rgb(154, 154, 154),
            text_hover = rgb(176, 176, 176),
        },
    }
    local theme_order = { "Milenium", "Midnight", "Sakura", "Emerald", "Amber", "Crimson", "Mono" }

    local themes = {
        preset = {},
        base = theme_presets["Milenium"],
        current_name = "Milenium",

        utility = {
            accent = {
                BackgroundColor3 = {},
                TextColor3 = {},
                ImageColor3 = {},
                ScrollBarImageColor3 = {}
            },
        }
    }
    for role, value in theme_presets["Milenium"] do themes.preset[role] = value end

    library.themes = theme_presets
    -- Milenium TextSize -> Hirimi TextSize. Hirimi draws text at 10 / 8 and scales the window up
    -- (fit 75% of the screen, max 1.35). Milenium's layout was built for bigger text, so text is
    -- drawn at Hirimi x 1.2 and the window scale is Hirimi's fit / 1.2 -> same size on screen.
    local text_size_map = { [16] = 10, [14] = 8, [26] = 14, [22] = 12 }
    library.text_scale = 1.2
    library.theme_order = theme_order

    -- color -> role lookup for a palette (keyed by rounded RGB so float noise does not matter)
    local function color_key(c)
        return floor(c.R * 255 + 0.5) * 65536 + floor(c.G * 255 + 0.5) * 256 + floor(c.B * 255 + 0.5)
    end

    local function build_lookup(palette)
        local lookup = {}
        for _, role in palette_roles do
            local c = palette[role]
            if c and lookup[color_key(c)] == nil then lookup[color_key(c)] = role end
        end
        return lookup
    end

    local base_lookup = build_lookup(themes.base)
    local color_props = { "BackgroundColor3", "TextColor3", "ImageColor3", "ScrollBarImageColor3", "PlaceholderColor3" }

    -- base literal (or current accent) -> active theme color
    local function theme_color(c)
        if typeof(c) ~= "Color3" then return c end
        local role = base_lookup[color_key(c)]
        if role then return themes.preset[role] end
        return c
    end

    -- Language. Text of TextLabel/TextButton made through library:create is remembered by its
    -- original (English) string; library:set_language swaps every remembered label in place.
    -- Scripts add their own words with library:add_translations("th", { ["Auto Farm"] = "ฟาร์มอัตโนมัติ" }).
    local i18n_registry = setmetatable({}, { __mode = "k" })
    local all_objects = setmetatable({}, { __mode = "k" })
    local languages = {
        en = {},
        th = {
            ["Settings"] = "ตั้งค่า", ["Configs"] = "คอนฟิก", ["Main"] = "หลัก", ["Misc."] = "อื่นๆ",
            ["Config name:"] = "ชื่อคอนฟิก:", ["Save"] = "บันทึก", ["Load"] = "โหลด", ["Delete"] = "ลบ",
            ["Menu Accent"] = "สีหลักเมนู", ["Menu Bind"] = "ปุ่มเปิด/ปิดเมนู", ["Theme"] = "ธีม",
            ["Language"] = "ภาษา", ["Interface"] = "หน้าตา", ["UI Scale"] = "ขนาด UI",
            ["Search..."] = "ค้นหา...", ["No results"] = "ไม่พบรายการ", ["Toggle"] = "สลับ",
            ["Hold"] = "กดค้าง", ["Always"] = "ตลอด", ["Saved config to:"] = "บันทึกคอนฟิกไว้ที่:",
            ["Loaded config:"] = "โหลดคอนฟิก:", ["Deleted config:"] = "ลบคอนฟิก:",
            ["Mobile Button"] = "ปุ่มลอย (มือถือ)", ["Refresh"] = "รีเฟรช",
        },
    }
    library.languages = languages
    library.language = "en"

    local function translate(text)
        if type(text) ~= "string" then return text end
        local dict = languages[library.language]
        return dict and dict[text] or text
    end
    library.translate = function(_, text) return translate(text) end

    local keys = {
        [Enum.KeyCode.LeftShift] = "LS",
        [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC",
        [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.Insert] = "INS",
        [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent",
        [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA",
        [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.KeyCode.One] = "1",
        [Enum.KeyCode.Two] = "2",
        [Enum.KeyCode.Three] = "3",
        [Enum.KeyCode.Four] = "4",
        [Enum.KeyCode.Five] = "5",
        [Enum.KeyCode.Six] = "6",
        [Enum.KeyCode.Seven] = "7",
        [Enum.KeyCode.Eight] = "8",
        [Enum.KeyCode.Nine] = "9",
        [Enum.KeyCode.Zero] = "0",
        [Enum.KeyCode.KeypadOne] = "Num1",
        [Enum.KeyCode.KeypadTwo] = "Num2",
        [Enum.KeyCode.KeypadThree] = "Num3",
        [Enum.KeyCode.KeypadFour] = "Num4",
        [Enum.KeyCode.KeypadFive] = "Num5",
        [Enum.KeyCode.KeypadSix] = "Num6",
        [Enum.KeyCode.KeypadSeven] = "Num7",
        [Enum.KeyCode.KeypadEight] = "Num8",
        [Enum.KeyCode.KeypadNine] = "Num9",
        [Enum.KeyCode.KeypadZero] = "Num0",
        [Enum.KeyCode.Minus] = "-",
        [Enum.KeyCode.Equals] = "=",
        [Enum.KeyCode.Tilde] = "~",
        [Enum.KeyCode.LeftBracket] = "[",
        [Enum.KeyCode.RightBracket] = "]",
        [Enum.KeyCode.RightParenthesis] = ")",
        [Enum.KeyCode.LeftParenthesis] = "(",
        [Enum.KeyCode.Semicolon] = ",",
        [Enum.KeyCode.Quote] = "'",
        [Enum.KeyCode.BackSlash] = "\\",
        [Enum.KeyCode.Comma] = ",",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Slash] = "/",
        [Enum.KeyCode.Asterisk] = "*",
        [Enum.KeyCode.Plus] = "+",
        [Enum.KeyCode.Period] = ".",
        [Enum.KeyCode.Backquote] = "`",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
    }
        
    library.__index = library

    for _, path in next, library.folders do 
        makefolder(library.directory .. path)
    end

    local flags = library.flags 
    local config_flags = library.config_flags
    local notifications = library.notifications 

    -- same typeface as Hirimi (Roblox cloud font - no download / getcustomasset needed any more)
    -- weights follow Hirimi: bold = window title / category / page header / section / notification title,
    -- font (SemiBold) = element names + slider value, small (Medium) = sidebar tabs, info text, values,
    -- dropdown options, inputs
    local hirimi_font = "rbxassetid://12187365364"
    local fonts = {
        small = Font.new(hirimi_font, Enum.FontWeight.Medium, Enum.FontStyle.Normal);
        font = Font.new(hirimi_font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
        bold = Font.new(hirimi_font, Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    }
--

-- Library functions 
    -- Misc functions
        function library:tween(obj, properties, easing_style, time) 
            -- hardcoded base colors in element code -> active theme
            for prop, value in properties do
                if typeof(value) == "Color3" then properties[prop] = theme_color(value) end
            end

            local tween = tween_service:Create(obj, TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0), properties)
            tween:Play()
                
            return tween
        end

        -- mouse or touch (mobile executors) - drag/slider/resize all accept both
        local function is_press(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        end
        local function is_move(input)
            return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
        end
        library.is_press = is_press
        library.is_move = is_move

        -- position (offset inside library.items) just below an element - popups (dropdown, keybind mode,
        -- colorpicker, settings) used magic numbers (+45/+60/+80/+90) that only matched one topbar inset
        function library:below(element, gap)
            local root = library[ "items" ]
            local origin = root and root.AbsolutePosition or vec2(0, 0)
            local pos = element.AbsolutePosition - origin
            return dim_offset(pos.X, pos.Y + element.AbsoluteSize.Y + (gap or 4))
        end

        function library:resizify(frame) 
            local Frame = Instance.new("TextButton")
            Frame.Position = dim2(1, -10, 1, -10)
            Frame.BorderColor3 = rgb(0, 0, 0)
            Frame.Size = dim2(0, 10, 0, 10)
            Frame.BorderSizePixel = 0
            Frame.BackgroundColor3 = rgb(255, 255, 255)
            Frame.Parent = frame
            Frame.BackgroundTransparency = 1 
            Frame.Text = ""

            local resizing = false 
            local start_size 
            local start 
            -- smallest size = 520x380 (or the start size if that is already smaller)
            local og_size = dim2(0, min(frame.Size.X.Offset, 520), 0, min(frame.Size.Y.Offset, 380))

            Frame.InputBegan:Connect(function(input)
                if is_press(input) then
                    resizing = true
                    start = input.Position
                    start_size = frame.Size
                end
            end)

            Frame.InputEnded:Connect(function(input)
                if is_press(input) then
                    resizing = false
                end
            end)

            library:connection(uis.InputChanged, function(input, game_event) 
                if resizing and is_move(input) then
                    local viewport_x = camera.ViewportSize.X
                    local viewport_y = camera.ViewportSize.Y

                    local current_size = dim2(
                        start_size.X.Scale,
                        math.clamp(
                            start_size.X.Offset + (input.Position.X - start.X),
                            og_size.X.Offset,
                            viewport_x
                        ),
                        start_size.Y.Scale,
                        math.clamp(
                            start_size.Y.Offset + (input.Position.Y - start.Y),
                            og_size.Y.Offset,
                            viewport_y
                        )
                    )

                    library:tween(frame, {Size = current_size}, Enum.EasingStyle.Linear, 0.05)
                end
            end)
        end 

        function fag(tbl)
            local Size = 0
            
            for _ in tbl do
                Size = Size + 1
            end
        
            return Size
        end
        
        function library:next_flag()
            local index = fag(library.flags) + 1;
            local str = string.format("flagnumber%s", index)
            
            return str;
        end 

        function library:mouse_in_frame(uiobject)
            local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
            local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X

            return (y_cond and x_cond)
        end

        function library:draggify(frame)
            local dragging = false 
            local start_size = frame.Position
            local start 

            frame.InputBegan:Connect(function(input)
                if is_press(input) then
                    dragging = true
                    start = input.Position
                    start_size = frame.Position
                end
            end)

            frame.InputEnded:Connect(function(input)
                if is_press(input) then
                    dragging = false
                end
            end)

            library:connection(uis.InputChanged, function(input, game_event) 
                if dragging and is_move(input) then
                    local viewport_x = camera.ViewportSize.X
                    local viewport_y = camera.ViewportSize.Y

                    local current_position = dim2(
                        0,
                        clamp(
                            start_size.X.Offset + (input.Position.X - start.X),
                            0,
                            max(0, viewport_x - frame.AbsoluteSize.X)
                        ),
                        0,
                        math.clamp(
                            start_size.Y.Offset + (input.Position.Y - start.Y),
                            0,
                            max(0, viewport_y - frame.AbsoluteSize.Y)
                        )
                    )

                    library:tween(frame, {Position = current_position}, Enum.EasingStyle.Linear, 0.05)
                    library:close_element()
                end
            end)
        end 

        function library:convert(str)
            local values = {}

            for value in string.gmatch(str, "[^,]+") do
                insert(values, tonumber(value))
            end
            
            if #values == 4 then              
                return unpack(values)
            else 
                return
            end
        end
        
        function library:convert_enum(enum)
            local enum_parts = {}
        
            for part in string.gmatch(enum, "[%w_]+") do
                insert(enum_parts, part)
            end
        
            local enum_table = Enum
            for i = 2, #enum_parts do
                local enum_item = enum_table[enum_parts[i]]
        
                enum_table = enum_item
            end
        
            return enum_table
        end

        local config_holder;
        function library:update_config_list() 
            if not config_holder then 
                return 
            end
            
            local list = {}
            
            for idx, file in listfiles(library.directory .. "/configs") do
                local name = file:gsub(library.directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(library.directory .. "\\configs\\", "")
                list[#list + 1] = name
            end

            config_holder.refresh_options(list)
        end 

        function library:get_config()
            local Config = {}
            
            for _, v in next, flags do
                if type(v) == "table" and v.key then
                    Config[_] = {active = v.active, mode = v.mode, key = tostring(v.key)}
                elseif type(v) == "table" and v["Transparency"] and v["Color"] then
                    Config[_] = {Transparency = v["Transparency"], Color = v["Color"]:ToHex()}
                else
                    Config[_] = v
                end
            end 
            
            return http_service:JSONEncode(Config)
        end

        function library:load_config(config_json) 
            local config = http_service:JSONDecode(config_json)
            
            for _, v in config do 
                local function_set = library.config_flags[_]
                
                if _ == "config_name_list" then 
                    continue 
                end

                if function_set then 
                    if type(v) == "table" and v["Transparency"] and v["Color"] then
                        function_set(hex(v["Color"]), v["Transparency"])
                    elseif type(v) == "table" and v["active"] then 
                        function_set(v)
                    else
                        function_set(v)
                    end
                end 
            end 
        end 
        
        function library:round(number, float) 
            local multiplier = 1 / (float or 1)

            return floor(number * multiplier + 0.5) / multiplier
        end 

        function library:apply_theme(instance, theme, property) 
            insert(themes.utility[theme][property], instance)
        end

        -- every object the library created (weak registry filled by library:create) - walking the gui
        -- missed tabs that are not open: their pages sit unparented (library.cache = nil) until selected,
        -- so an ON toggle on another tab kept the old accent after a theme switch
        local function each_object(callback)
            for object in all_objects do
                callback(object)
            end
        end

        -- repaint from one palette to another: color that belongs to a role in the old palette
        -- becomes that role's color in the new palette (works for any state - on/off/hovered)
        local function repaint(old, new)
            local lookup = build_lookup(old)
            each_object(function(object)
                if object:IsA("UIStroke") then
                    local role = lookup[color_key(object.Color)]
                    if role and new[role] then object.Color = new[role] end
                    return
                end
                if not object:IsA("GuiObject") then return end
                for _, prop in color_props do
                    local ok, value = pcall(function() return object[prop] end)
                    if ok and typeof(value) == "Color3" then
                        local role = lookup[color_key(value)]
                        if role and new[role] then object[prop] = new[role] end
                    end
                end
            end)
        end

        function library:update_theme(theme, color)
            local old = {}
            for role, value in themes.preset do old[role] = value end

            themes.preset[theme] = color
            repaint({ [theme] = old[theme] }, { [theme] = color })
        end

        function library:set_theme(name)
            local preset = theme_presets[name]
            if not preset then return end

            local old = {}
            for role, value in themes.preset do old[role] = value end
            for role, value in preset do themes.preset[role] = value end
            themes.current_name = name

            repaint(old, themes.preset)
            for _, callback in library.theme_callbacks do pcall(callback, name) end
        end
        library.theme_callbacks = {}

        function library:get_theme()
            return themes.current_name, themes.preset
        end

        function library:add_translations(lang, dict)
            languages[lang] = languages[lang] or {}
            for key, value in dict do languages[lang][key] = value end
            if library.language == lang then library:set_language(lang) end
        end

        function library:set_language(lang)
            if not languages[lang] then return end
            local previous = library.language
            local previous_dict = languages[previous] or {}
            library.language = lang
            for object, original in i18n_registry do
                -- only labels still showing their caption; code that rewrote Text (values, key
                -- names, "..." while binding) owns that label now - drop it from the registry
                local shown = previous_dict[original] or original
                if object.Text == shown or object.Text == original then
                    object.Text = translate(original)
                else
                    i18n_registry[object] = nil
                end
            end
            for _, callback in library.language_callbacks do pcall(callback, lang) end
        end
        library.language_callbacks = {}

        -- search index for the sidebar search box: every element registers its caption + where it lives
        -- (section -> column -> page), settings popups (sanity) are skipped
        library.search_index = {}
        function library:searchable(section, text, root)
            if type(text) ~= "string" or text == "" or type(section) ~= "table" or section.sanity then return end
            insert(library.search_index, { text = text, section = section, root = root })
        end

        -- text that must not be translated (values, option names, key names)
        function library:no_translate(object)
            i18n_registry[object] = nil
            return object
        end 

        function library:connection(signal, callback)
            local connection = signal:Connect(callback)
            
            insert(library.connections, connection)

            return connection 
        end

        function library:close_element(new_path) 
            local open_element = library.current_open

            if open_element and new_path ~= open_element then
                open_element.set_visible(false)
                open_element.open = false;
            end 

            if new_path ~= open_element then 
                library.current_open = new_path or nil;
            end
        end 

        function library:create(instance, options)
            local ins = Instance.new(instance) 
            local parent = options.Parent
            
            for prop, value in options do 
                if prop ~= "Parent" then
                    if typeof(value) == "Color3" and (prop ~= "BorderColor3") then value = theme_color(value) end
                    -- Milenium sizes -> Hirimi sizes (16 -> 10 title, 14 -> 8 small) x text_scale
                    if prop == "TextSize" and type(value) == "number" then
                        value = max(6, floor((text_size_map[value] or value * 0.625) * (library.text_scale or 1) + 0.5))
                    end
                    ins[prop] = value
                end
            end

            -- label / button captions follow library:set_language (TextBox input is never translated)
            if (instance == "TextLabel" or instance == "TextButton") and type(options.Text) == "string"
                and options.Text ~= "" and not options.RichText then
                i18n_registry[ins] = options.Text
                ins.Text = translate(options.Text)
            end

            if parent then ins.Parent = parent end
            if ins:IsA("GuiObject") or ins:IsA("UIStroke") then all_objects[ins] = true end
            
            return ins 
        end

        function library:unload_menu() 
            if library[ "items" ] then 
                library[ "items" ]:Destroy()
            end

            if library[ "other" ] then 
                library[ "other" ]:Destroy()
            end 

            if library[ "mobile" ] then 
                library[ "mobile" ]:Destroy()
            end 
            
            for index, connection in library.connections do 
                connection:Disconnect() 
                connection = nil 
            end
            
            library = nil 
        end 
    --
    
    -- Library element functions
        function library:window(properties)
            local cfg = { 
                suffix = properties.suffix or properties.Suffix or "tech";
                name = properties.name or properties.Name or "nebula";
                game_name = properties.gameInfo or properties.game_info or properties.GameInfo or "Milenium for Counter-Strike: Global Offensive";
                -- same on-screen size as Hirimi's window (640x400, sidebar 150): the window is drawn at
                -- Hirimi size x text_scale (1.2) and UIScale = Hirimi's fit / 1.2
                size = properties.size or properties.Size or dim2(0, 768, 0, 480);
                side_width = properties.side_width or properties.SideWidth or 180;
                auto_scale = properties.auto_scale ~= false and properties.AutoScale ~= false;
                text_scale = properties.text_scale or properties.TextScale;
                -- bottom-left profile card like Hirimi: { avatar = "rbxthumb://...", name = "...", desc = "..." }
                profile = properties.profile or properties.Profile;
                -- sidebar search box (searches every element on every tab) - search = false hides it
                search = properties.search ~= false;
                search_placeholder = properties.search_placeholder or "Search...";
                selected_tab;
                items = {};

                tween;
            }
            
            if cfg.text_scale then library.text_scale = cfg.text_scale end

            library[ "items" ] = library:create( "ScreenGui" , {
                Parent = coregui;
                Name = "\0";
                Enabled = true;
                ZIndexBehavior = Enum.ZIndexBehavior.Global;
                IgnoreGuiInset = true;
            });
            
            library[ "other" ] = library:create( "ScreenGui" , {
                Parent = coregui;
                Name = "\0";
                Enabled = false;
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
                IgnoreGuiInset = true;
            }); 

            -- separate gui for the floating open/close button (stays visible while the menu is hidden)
            library[ "mobile" ] = library:create( "ScreenGui" , {
                Parent = coregui;
                Name = "\0";
                Enabled = true;
                ZIndexBehavior = Enum.ZIndexBehavior.Global;
                IgnoreGuiInset = true;
                DisplayOrder = 10;
            });

            local items = cfg.items; do
                items[ "main" ] = library:create( "Frame" , {
                    Parent = library[ "items" ];
                    Size = cfg.size;
                    Name = "\0";
                    Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16)
                }); items[ "main" ].Position = dim2(0, items[ "main" ].AbsolutePosition.X, 0, items[ "main" ].AbsolutePosition.Y)
                
                library:create( "UICorner" , {
                    Parent = items[ "main" ];
                    CornerRadius = dim(0, 10)
                });
                
                library:create( "UIStroke" , {
                    Color = rgb(23, 23, 29);
                    Parent = items[ "main" ];
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });
                
                items[ "side_frame" ] = library:create( "Frame" , {
                    Parent = items[ "main" ];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, cfg.side_width, 1, -25);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16)
                });
                
                library:create( "Frame" , {
                    AnchorPoint = vec2(1, 0);
                    Parent = items[ "side_frame" ];
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 1, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(21, 21, 23)
                });
                
                -- sidebar scrolls when there are more tabs than fit
                items[ "button_holder" ] = library:create( "ScrollingFrame" , {
                    Parent = items[ "side_frame" ];
                    Name = "\0";
                    Active = true;
                    BackgroundTransparency = 1;
                    Position = dim2(0, 0, 0, cfg.search and 82 or 46);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 1, -((cfg.search and 82 or 46) + (cfg.profile and 52 or 0)));
                    BorderSizePixel = 0;
                    ClipsDescendants = true;
                    CanvasSize = dim2(0, 0, 0, 0);
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollingDirection = Enum.ScrollingDirection.Y;
                    ScrollBarThickness = 2;
                    ScrollBarImageColor3 = rgb(44, 44, 46);
                    BackgroundColor3 = rgb(255, 255, 255)
                }); cfg.button_holder = items[ "button_holder" ];
                
                library:create( "UIListLayout" , {
                    Parent = items[ "button_holder" ];
                    Padding = dim(0, 5);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                
                library:create( "UIPadding" , {
                    PaddingTop = dim(0, 6);
                    PaddingBottom = dim(0, 8);
                    Parent = items[ "button_holder" ];
                    PaddingRight = dim(0, 11);
                    PaddingLeft = dim(0, 10)
                });

                local accent = themes.preset.accent
                items[ "title" ] = library:create( "TextLabel" , {
                    FontFace = fonts.bold;
                    BorderColor3 = rgb(0, 0, 0);
                    Text = name;
                    Parent = items[ "side_frame" ];
                    Name = "\0";
                    Text = string.format('<u>%s</u><font color = "rgb(255, 255, 255)">%s</font>', cfg.name, cfg.suffix);
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 46);
                    TextColor3 = themes.preset.accent;
                    BorderSizePixel = 0;
                    RichText = true;
                    TextSize = 26;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items[ "title" ], "accent", "TextColor3");

                -- search box (Hirimi style) - typing swaps the tab list for a list of matching elements
                if cfg.search then
                    items[ "search" ] = library:create( "TextBox" , {
                        Parent = items[ "side_frame" ];
                        Name = "\0";
                        FontFace = fonts.small;
                        Text = "";
                        PlaceholderText = translate(cfg.search_placeholder);
                        PlaceholderColor3 = rgb(86, 86, 87);
                        TextColor3 = rgb(245, 245, 245);
                        TextSize = 14;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        ClearTextOnFocus = false;
                        Position = dim2(0, 10, 0, 48);
                        Size = dim2(1, -21, 0, 28);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(22, 22, 24);
                    });

                    library:create( "UICorner" , { Parent = items[ "search" ]; CornerRadius = dim(0, 6) });
                    library:create( "UIStroke" , { Parent = items[ "search" ]; Color = rgb(23, 23, 29); ApplyStrokeMode = Enum.ApplyStrokeMode.Border });
                    library:create( "UIPadding" , { Parent = items[ "search" ]; PaddingLeft = dim(0, 28); PaddingRight = dim(0, 8) });

                    library:create( "ImageLabel" , {
                        Parent = items[ "search" ];
                        Name = "\0";
                        Image = "rbxassetid://6031154871";
                        ImageColor3 = rgb(86, 86, 87);
                        BackgroundTransparency = 1;
                        AnchorPoint = vec2(0, 0.5);
                        Position = dim2(0, -20, 0.5, 0);
                        Size = dim2(0, 13, 0, 13);
                    });

                    items[ "search_results" ] = library:create( "ScrollingFrame" , {
                        Parent = items[ "side_frame" ];
                        Name = "\0";
                        Visible = false;
                        Active = true;
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        ClipsDescendants = true;
                        Position = items[ "button_holder" ].Position;
                        Size = items[ "button_holder" ].Size;
                        CanvasSize = dim2(0, 0, 0, 0);
                        AutomaticCanvasSize = Enum.AutomaticSize.Y;
                        ScrollingDirection = Enum.ScrollingDirection.Y;
                        ScrollBarThickness = 2;
                        ScrollBarImageColor3 = rgb(44, 44, 46);
                    });

                    library:create( "UIListLayout" , {
                        Parent = items[ "search_results" ];
                        Padding = dim(0, 4);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });

                    library:create( "UIPadding" , {
                        Parent = items[ "search_results" ];
                        PaddingTop = dim(0, 6);
                        PaddingBottom = dim(0, 8);
                        PaddingRight = dim(0, 11);
                        PaddingLeft = dim(0, 10)
                    });
                end

                -- profile card at the bottom of the sidebar (Hirimi's userProfile)
                if cfg.profile then
                    items[ "profile" ] = library:create( "Frame" , {
                        Parent = items[ "side_frame" ];
                        Name = "\0";
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        AnchorPoint = vec2(0, 1);
                        Position = dim2(0, 0, 1, 0);
                        Size = dim2(1, -1, 0, 52);
                    });

                    library:create( "Frame" , {
                        Parent = items[ "profile" ];
                        Name = "\0";
                        BorderSizePixel = 0;
                        Position = dim2(0, 10, 0, 0);
                        Size = dim2(1, -20, 0, 1);
                        BackgroundColor3 = rgb(21, 21, 23)
                    });

                    items[ "avatar" ] = library:create( "ImageLabel" , {
                        Parent = items[ "profile" ];
                        Name = "\0";
                        Image = cfg.profile.avatar or "";
                        BackgroundColor3 = rgb(33, 33, 35);
                        BorderSizePixel = 0;
                        AnchorPoint = vec2(0, 0.5);
                        Position = dim2(0, 12, 0.5, 0);
                        Size = dim2(0, 30, 0, 30);
                    });
                    library:create( "UICorner" , { Parent = items[ "avatar" ]; CornerRadius = dim(1, 0) });
                    library:create( "UIStroke" , { Parent = items[ "avatar" ]; Color = themes.preset.accent; Thickness = 1; Transparency = 0.4 });

                    items[ "profile_name" ] = library:no_translate(library:create( "TextLabel" , {
                        Parent = items[ "profile" ];
                        Name = "\0";
                        FontFace = fonts.bold;
                        Text = cfg.profile.name or lp.DisplayName;
                        TextColor3 = rgb(245, 245, 245);
                        TextSize = 16;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BackgroundTransparency = 1;
                        Position = dim2(0, 50, 0.5, -13);
                        Size = dim2(1, -58, 0, 14);
                    }));

                    items[ "profile_desc" ] = library:no_translate(library:create( "TextLabel" , {
                        Parent = items[ "profile" ];
                        Name = "\0";
                        FontFace = fonts.small;
                        Text = cfg.profile.desc or ("@" .. lp.Name);
                        TextColor3 = rgb(130, 130, 130);
                        TextSize = 14;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BackgroundTransparency = 1;
                        Position = dim2(0, 50, 0.5, 2);
                        Size = dim2(1, -58, 0, 12);
                    }));
                end
                
                items[ "multi_holder" ] = library:create( "Frame" , {
                    Parent = items[ "main" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, cfg.side_width, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -cfg.side_width, 0, 40);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); cfg.multi_holder = items[ "multi_holder" ];
                
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = items[ "multi_holder" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(21, 21, 23)
                });
                
                items[ "shadow" ] = library:create( "ImageLabel" , {
                    ImageColor3 = rgb(0, 0, 0);
                    ScaleType = Enum.ScaleType.Slice;
                    Parent = items[ "main" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Name = "\0";
                    BackgroundColor3 = rgb(255, 255, 255);
                    Size = dim2(1, 75, 1, 75);
                    AnchorPoint = vec2(0.5, 0.5);
                    Image = "rbxassetid://112971167999062";
                    BackgroundTransparency = 1;
                    Position = dim2(0.5, 0, 0.5, 0);
                    SliceScale = 0.75;
                    ZIndex = -100;
                    BorderSizePixel = 0;
                    SliceCenter = rect(vec2(112, 112), vec2(147, 147))
                });
                
                items[ "global_fade" ] = library:create( "Frame" , {
                    Parent = items[ "main" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, cfg.side_width, 0, 40);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -cfg.side_width, 1, -65);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(14, 14, 16);
                    ZIndex = 2;
                });                

                library:create( "UICorner" , {
                    Parent = items[ "shadow" ];
                    CornerRadius = dim(0, 5)
                });
                
                items[ "info" ] = library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = items[ "main" ];
                    Name = "\0";
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 25);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(23, 23, 25)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "info" ];
                    CornerRadius = dim(0, 10)
                });
                
                items[ "grey_fill" ] = library:create( "Frame" , {
                    Name = "\0";
                    Parent = items[ "info" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 6);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(23, 23, 25)
                });
                
                items[ "game" ] = library:create( "TextLabel" , {
                    FontFace = fonts.small;
                    Parent = items[ "info" ];
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.game_name;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    AnchorPoint = vec2(0, 0.5);
                    Position = dim2(0, 10, 0.5, -1);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); 
                
                items[ "other_info" ] = library:create( "TextLabel" , {
                    Parent = items[ "info" ];
                    RichText = true;
                    Name = "\0";
                    TextColor3 = themes.preset.accent;
                    BorderColor3 = rgb(0, 0, 0);
                    Text = properties.info_text or properties.InfoText or (cfg.name .. cfg.suffix);
                    Size = dim2(1, 0, 0, 0);
                    Position = dim2(0, -10, 0.5, -1);
                    AnchorPoint = vec2(0, 0.5);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    FontFace = fonts.small;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items[ "other_info" ], "accent", "TextColor3");        
            end 

            do -- Other
                library:draggify(items[ "main" ])
                library:resizify(items[ "main" ])

                -- fit to screen: scale the whole window down when the viewport is smaller than it
                items[ "scale" ] = library:create( "UIScale" , {
                    Parent = items[ "main" ];
                    Scale = 1;
                })
                cfg.user_scale = 1

                function cfg.update_scale()
                    local viewport = camera.ViewportSize
                    local fit = 1
                    if cfg.auto_scale then
                        -- Hirimi's rule (640x400 base, 75% of the screen, max 1.35) / text_scale, then
                        -- never bigger than the screen itself
                        local hirimi_fit = min(viewport.X * 0.75 / 640, viewport.Y * 0.75 / 400, 1.35)
                        fit = hirimi_fit / (library.text_scale or 1)
                        fit = min(fit, (viewport.X - 40) / cfg.size.X.Offset, (viewport.Y - 40) / cfg.size.Y.Offset)
                    end
                    local scale = clamp(fit * cfg.user_scale, 0.45, 1.5)
                    items[ "scale" ].Scale = scale
                    library.current_scale = scale

                    -- keep the window on screen after a resize / rescale
                    local main = items[ "main" ]
                    local width, height = main.AbsoluteSize.X, main.AbsoluteSize.Y
                    main.Position = dim_offset(
                        clamp(main.Position.X.Offset, 0, max(0, viewport.X - width)),
                        clamp(main.Position.Y.Offset, 0, max(0, viewport.Y - height))
                    )
                end

                function cfg.set_scale(value)
                    cfg.user_scale = value
                    cfg.update_scale()
                end

                library:connection(camera:GetPropertyChangedSignal("ViewportSize"), cfg.update_scale)
                cfg.update_scale()

                -- center after scaling (position was computed for the unscaled size)
                local viewport = camera.ViewportSize
                items[ "main" ].Position = dim_offset(
                    floor((viewport.X - items[ "main" ].AbsoluteSize.X) / 2),
                    floor((viewport.Y - items[ "main" ].AbsoluteSize.Y) / 2)
                )

                -- floating button to open/close the menu (touch devices have no keybind)
                items[ "mobile_button" ] = library:create( "TextButton" , {
                    Parent = library[ "mobile" ];
                    Name = "\0";
                    Text = "";
                    AutoButtonColor = false;
                    Size = dim2(0, 46, 0, 46);
                    Position = dim2(0, 20, 0.5, -23);
                    BackgroundColor3 = rgb(14, 14, 16);
                    BorderSizePixel = 0;
                    Visible = properties.mobile_button == true or (properties.mobile_button == nil and uis.TouchEnabled and not uis.KeyboardEnabled);
                })
                library:create( "UICorner" , { Parent = items[ "mobile_button" ]; CornerRadius = dim(0, 12) })
                library:create( "UIStroke" , { Parent = items[ "mobile_button" ]; Color = themes.preset.accent; Thickness = 1.5; ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
                library:create( "TextLabel" , {
                    Parent = items[ "mobile_button" ];
                    Name = "\0";
                    Size = dim2(1, 0, 1, 0);
                    BackgroundTransparency = 1;
                    FontFace = fonts.font;
                    RichText = true;
                    Text = string.sub(cfg.name, 1, 1);
                    TextSize = 22;
                    TextColor3 = themes.preset.accent;
                })

                do
                    local moved, start, start_pos = false, nil, nil
                    items[ "mobile_button" ].InputBegan:Connect(function(input)
                        if is_press(input) then
                            moved, start, start_pos = false, input.Position, items[ "mobile_button" ].Position
                        end
                    end)
                    library:connection(uis.InputChanged, function(input)
                        if start and is_move(input) then
                            local delta = input.Position - start
                            if delta.Magnitude > 6 then moved = true end
                            if moved then
                                items[ "mobile_button" ].Position = dim2(
                                    start_pos.X.Scale, start_pos.X.Offset + delta.X,
                                    start_pos.Y.Scale, start_pos.Y.Offset + delta.Y
                                )
                            end
                        end
                    end)
                    library:connection(uis.InputEnded, function(input)
                        if start and is_press(input) then
                            start = nil
                            if not moved then cfg.toggle_menu(not library[ "items" ].Enabled) end
                        end
                    end)
                end

                function cfg.set_mobile_button(bool)
                    items[ "mobile_button" ].Visible = bool
                end
            end 

            -- sidebar search: results replace the tab list while the box has text, click = open that
            -- tab, scroll the section to the element and flash its caption in the accent color
            if cfg.search then
                local result_buttons = {}

                local function clear_results()
                    for _, object in result_buttons do object:Destroy() end
                    table.clear(result_buttons)
                end

                local function go_to(entry)
                    local section = entry.section
                    local page = section.column and section.column.page
                    items[ "search" ].Text = ""
                    items[ "search" ]:ReleaseFocus()
                    if page and page.open_tab then page.open_tab() end

                    task.delay(0.1, function()
                        local root = entry.root
                        local scrolling = section.items and section.items[ "scrolling" ]
                        local elements = section.items and section.items[ "elements" ]
                        if not (root and root.Parent) then return end

                        if scrolling and scrolling:IsA("ScrollingFrame") and elements then
                            local offset = root.AbsolutePosition.Y - elements.AbsolutePosition.Y
                            scrolling.CanvasPosition = vec2(0, max(0, offset - 10))
                        end

                        local caption = root:IsA("TextLabel") and root or root:FindFirstChildWhichIsA("TextLabel", true)
                        if caption then
                            local original = caption.TextColor3
                            caption.TextColor3 = themes.preset.accent
                            task.delay(0.9, function()
                                if caption.Parent then library:tween(caption, {TextColor3 = original}, Enum.EasingStyle.Quad, 0.4) end
                            end)
                        end
                    end)
                end

                local function result_button(entry, order)
                    local section = entry.section
                    local page = section.column and section.column.page
                    local where = (page and page.tab_name and translate(page.tab_name) or "?") .. "  ›  " .. translate(section.name or "")

                    local button = library:create( "TextButton" , {
                        Parent = items[ "search_results" ];
                        Name = "\0";
                        Text = "";
                        AutoButtonColor = false;
                        LayoutOrder = order;
                        Size = dim2(1, 0, 0, 34);
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(29, 29, 29);
                    })
                    library:create( "UICorner" , { Parent = button; CornerRadius = dim(0, 7) })
                    library:create( "UIPadding" , { Parent = button; PaddingLeft = dim(0, 8); PaddingRight = dim(0, 6) })

                    library:no_translate(library:create( "TextLabel" , {
                        Parent = button;
                        Name = "\0";
                        FontFace = fonts.font;
                        Text = translate(entry.text);
                        TextColor3 = rgb(245, 245, 245);
                        TextSize = 16;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 0, 4);
                        Size = dim2(1, 0, 0, 14);
                    }))

                    library:no_translate(library:create( "TextLabel" , {
                        Parent = button;
                        Name = "\0";
                        FontFace = fonts.small;
                        Text = where;
                        TextColor3 = rgb(130, 130, 130);
                        TextSize = 14;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 0, 19);
                        Size = dim2(1, 0, 0, 12);
                    }))

                    button.MouseEnter:Connect(function() library:tween(button, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad, 0.15) end)
                    button.MouseLeave:Connect(function() library:tween(button, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.15) end)
                    button.MouseButton1Click:Connect(function() go_to(entry) end)

                    insert(result_buttons, button)
                end

                local function run_search()
                    clear_results()
                    local query = string.lower(items[ "search" ].Text)

                    if query == "" then
                        items[ "search_results" ].Visible = false
                        items[ "button_holder" ].Visible = true
                        return
                    end

                    items[ "search_results" ].Visible = true
                    items[ "button_holder" ].Visible = false
                    items[ "search_results" ].CanvasPosition = vec2(0, 0)

                    local shown = 0
                    for _, entry in library.search_index do
                        local root = entry.root
                        if root and root.Parent then
                            local caption = string.lower(translate(entry.text))
                            if string.find(caption, query, 1, true) or string.find(string.lower(entry.text), query, 1, true) then
                                shown += 1
                                result_button(entry, shown)
                                if shown >= 50 then break end
                            end
                        end
                    end

                    if shown == 0 then
                        insert(result_buttons, library:create( "TextLabel" , {
                            Parent = items[ "search_results" ];
                            Name = "\0";
                            FontFace = fonts.small;
                            Text = "No results";
                            TextColor3 = rgb(72, 72, 73);
                            TextSize = 14;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            BackgroundTransparency = 1;
                            Size = dim2(1, 0, 0, 20);
                        }))
                    end
                end

                items[ "search" ]:GetPropertyChangedSignal("Text"):Connect(run_search)
                library.language_callbacks[#library.language_callbacks + 1] = function()
                    items[ "search" ].PlaceholderText = translate(cfg.search_placeholder)
                end
            end

            function cfg.toggle_menu(bool) 
                -- WIP 
                -- if cfg.tween then 
                --     cfg.tween:Cancel()
                -- end 

                -- items[ "main" ].Size = dim2(items[ "main" ].Size.Scale.X, items[ "main" ].Size.Offset.X - 20, items[ "main" ].Size.Scale.Y, items[ "main" ].Size.Offset.Y - 20)
                -- library:tween(items[ "tab_holder" ], {Size = dim2(1, -196, 1, -81)}, Enum.EasingStyle.Quad, 0.4)
                -- cfg.tween = 
                
                library[ "items" ].Enabled = bool
            end 
                
            return setmetatable(cfg, library)
        end 

        function library:tab(properties)
            local cfg = {
                name = properties.name or properties.Name or "visuals"; 
                icon = properties.icon or properties.Icon or "http://www.roblox.com/asset/?id=6034767608";
                
                -- extra pages: tabs = {"Main", "Misc."} -> "Misc." becomes its own sidebar entry
                -- (header "Farm  ›  Misc.") - the top sub-tab bar was removed to match Hirimi
                tabs = properties.tabs or properties.Tabs or {"Main"};
                parent_name = properties.parent_name;
                header = properties.header;
                pages = {}; -- data store for multi sections
                current_multi; 
                
                items = {};
            } 

            local items = cfg.items; do 
                items[ "tab_holder" ] = library:create( "Frame" , {
                    Parent = library.cache;
                    Name = "\0";
                    Visible = false;
                    BackgroundTransparency = 1;
                    Position = dim2(0, self.side_width, 0, 40);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -self.side_width - 20, 1, -85);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                -- Tab buttons 
                    items[ "button" ] = library:create( "TextButton" , {
                        FontFace = fonts.font;
                        TextColor3 = rgb(255, 255, 255);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = self.items[ "button_holder" ];
                        AutoButtonColor = false;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Size = dim2(1, 0, 0, 28);
                        BorderSizePixel = 0;
                        TextSize = 16;
                        BackgroundColor3 = rgb(29, 29, 29)
                    });
                    
                    items[ "icon" ] = library:create( "ImageLabel" , {
                        ImageColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = items[ "button" ];
                        AnchorPoint = vec2(0, 0.5);
                        Image = cfg.icon;
                        BackgroundTransparency = 1;
                        Position = dim2(0, 9, 0.5, 0);
                        Name = "\0";
                        Size = dim2(0, 16, 0, 16);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    }); library:apply_theme(items[ "icon" ], "accent", "ImageColor3");
                    
                    items[ "name" ] = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = cfg.name;
                        Parent = items[ "button" ];
                        Name = "\0";
                        Size = dim2(0, 0, 1, 0);
                        Position = dim2(0, 30, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.X;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIPadding" , {
                        Parent = items[ "name" ];
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "button" ];
                        CornerRadius = dim(0, 7)
                    });
                    
                    library:create( "UIStroke" , {
                        Color = rgb(23, 23, 29);
                        Parent = items[ "button" ];
                        Enabled = false;
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    });
                -- 

                -- Header (same as Hirimi): no sub-tab buttons - the top bar just shows where you are
                -- ("Farm", or "Farm  ›  Misc." for extra pages, see the end of this function)
                    items[ "multi_section_button_holder" ] = library:create( "Frame" , {
                        Parent = library.cache;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Visible = false;
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIListLayout" , {
                        Parent = items[ "multi_section_button_holder" ];
                        Padding = dim(0, 6);
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        FillDirection = Enum.FillDirection.Horizontal;
                        VerticalAlignment = Enum.VerticalAlignment.Center
                    });
                    
                    library:create( "UIPadding" , {
                        Parent = items[ "multi_section_button_holder" ];
                        PaddingRight = dim(0, 16);
                        PaddingLeft = dim(0, 16)
                    });

                    local function header_label(text, order, dim_text)
                        return library:create( "TextLabel" , {
                            FontFace = fonts.bold;
                            TextColor3 = dim_text and rgb(72, 72, 73) or rgb(255, 255, 255);
                            BorderColor3 = rgb(0, 0, 0);
                            Text = text;
                            Parent = items[ "multi_section_button_holder" ];
                            Name = "\0";
                            LayoutOrder = order;
                            Size = dim2(0, 0, 1, 0);
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.X;
                            TextSize = 16;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                    end

                    if cfg.parent_name then
                        items[ "header_parent" ] = header_label(cfg.parent_name, 1, true)
                        library:no_translate(header_label("›", 2, true))
                    end
                    items[ "header_title" ] = header_label(cfg.header or cfg.name, 3, false)

                    -- the one page of this tab
                    local data = {items = {}}
                    data.page = library:create( "Frame" , {
                        Parent = library.cache;
                        BackgroundTransparency = 1;
                        Name = "\0";
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        Visible = false;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    data.items[ "tab" ] = data.page

                    library:create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Vertical;
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = data.page;
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        VerticalFlex = Enum.UIFlexAlignment.Fill
                    });
                    
                    library:create( "UIPadding" , {
                        PaddingTop = dim(0, 7);
                        PaddingBottom = dim(0, 7);
                        Parent = data.page;
                        PaddingRight = dim(0, 7);
                        PaddingLeft = dim(0, 7)
                    });

                    data.parent = setmetatable(data, library):sub_tab({}).items[ "tab_parent" ]
                    data.tab_name = cfg.name

                    function data.open_page()
                        data.page.Visible = true
                        data.page.Parent = items[ "tab_holder" ]
                        cfg.current_multi = data
                    end

                    cfg.pages[1] = setmetatable(data, library)
                    data.open_page()
                --
            end 

            function cfg.open_tab() 
                local selected_tab = self.selected_tab
                
                if selected_tab then 
                    if selected_tab[ 4 ] ~= items[ "tab_holder" ] then 
                        self.items[ "global_fade" ].BackgroundTransparency = 0
                        
                        library:tween(self.items[ "global_fade" ], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.4)
                        selected_tab[ 4 ].Size = dim2(1, -self.side_width - 20, 1, -85)
                    end

                    library:tween(selected_tab[ 1 ], {BackgroundTransparency = 1})
                    library:tween(selected_tab[ 2 ], {ImageColor3 = rgb(72, 72, 73)})
                    library:tween(selected_tab[ 3 ], {TextColor3 = rgb(72, 72, 73)})

                    selected_tab[ 4 ].Visible = false
                    selected_tab[ 4 ].Parent = library[ "cache" ]
                    selected_tab[ 5 ].Visible = false
                    selected_tab[ 5 ].Parent = library[ "cache" ]
                end

                library:tween(items[ "button" ], {BackgroundTransparency = 0})
                library:tween(items[ "icon" ], {ImageColor3 = themes.preset.accent})
                library:tween(items[ "name" ], {TextColor3 = rgb(255, 255, 255)})
                library:tween(items[ "tab_holder" ], {Size = dim2(1, -self.side_width, 1, -65)}, Enum.EasingStyle.Quad, 0.4)
                
                items[ "tab_holder" ].Visible = true 
                items[ "tab_holder" ].Parent = self.items[ "main" ]
                items[ "multi_section_button_holder" ].Visible = true 
                items[ "multi_section_button_holder" ].Parent = self.items[ "multi_holder" ]

                self.selected_tab = {
                    items[ "button" ];
                    items[ "icon" ];
                    items[ "name" ];
                    items[ "tab_holder" ];
                    items[ "multi_section_button_holder" ];
                }

                library:close_element()
            end

            items[ "button" ].MouseButton1Down:Connect(function()
                cfg.open_tab()
            end)

            -- page:open_tab() selects this tab from code
            cfg.pages[1].open_tab = cfg.open_tab
            
            if not self.selected_tab then 
                cfg.open_tab(true) 
            end

            -- extra pages -> their own sidebar tabs, created after this one so order/selection stay right
            if #cfg.tabs > 1 then
                for index = 2, #cfg.tabs do
                    local extra = self:tab({
                        name = cfg.tabs[index],
                        icon = cfg.icon,
                        parent_name = cfg.name,
                        tabs = { cfg.tabs[index] },
                    })
                    cfg.pages[index] = extra
                end
            end

            return unpack(cfg.pages)
        end

        function library:seperator(properties)
            local cfg = {items = {}, name = properties.Name or properties.name or "General"}

            local items = cfg.items do 
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.bold;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = self.items[ "button_holder" ];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    Position = dim2(0, 40, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0; 
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIPadding" , {
                    Parent = items[ "name" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });                
            end;    

            return setmetatable(cfg, library)
        end 

        -- Miscellaneous 
            -- column({ scroll = true }) = scrolling column for auto-height sections (section({ auto = true }))
            function library:column(properties) 
                local cfg = {items = {}, size = properties.size or 1, scroll = properties.scroll or false, page = self}

                local items = cfg.items; do     
                    if cfg.scroll then
                        items[ "column" ] = library:create( "ScrollingFrame" , {
                            Parent = self[ "parent" ] or self.items["tab_parent"];
                            BackgroundTransparency = 1;
                            Name = "\0";
                            Active = true;
                            BorderSizePixel = 0;
                            Size = dim2(0, 0, cfg.size, 0);
                            CanvasSize = dim2(0, 0, 0, 0);
                            AutomaticCanvasSize = Enum.AutomaticSize.Y;
                            ScrollingDirection = Enum.ScrollingDirection.Y;
                            ScrollBarThickness = 2;
                            ScrollBarImageColor3 = rgb(44, 44, 46);
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                    else
                    items[ "column" ] = library:create( "Frame" , {
                        Parent = self[ "parent" ] or self.items["tab_parent"];
                        BackgroundTransparency = 1;
                        Name = "\0";
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 0, cfg.size, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    end
                    
                    library:create( "UIPadding" , {
                        PaddingBottom = dim(0, 10);
                        Parent = items[ "column" ]
                    });
                    
                    library:create( "UIListLayout" , {
                        Parent = items[ "column" ];
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        Padding = dim(0, 10);
                        FillDirection = Enum.FillDirection.Vertical;
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                end 

                return setmetatable(cfg, library)
            end 

            function library:sub_tab(properties) 
                local cfg = {items = {}, order = properties.order or 0; size = properties.size or 1}

                local items = cfg.items; do 
                    items[ "tab_parent" ] = library:create( "Frame" , {
                        Parent = self.items[ "tab" ];
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Size = dim2(0,0,cfg.size,0);
                        BorderColor3 = rgb(0, 0, 0);
                        BorderSizePixel = 0;
                        Visible = true;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Horizontal;
                        HorizontalFlex = Enum.UIFlexAlignment.Fill;
                        VerticalFlex = Enum.UIFlexAlignment.Fill;
                        Parent = items[ "tab_parent" ];
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder;
                    });
                end

                return setmetatable(cfg, library)
            end 
        --

        function library:section(properties)
            local cfg = {
                name = properties.name or properties.Name or "section"; 
                side = properties.side or properties.Side or "left";
                default = properties.default or properties.Default or false;
                size = properties.size or properties.Size or self.size or 0.5; 
                icon = properties.icon or properties.Icon or "http://www.roblox.com/asset/?id=6022668898";
                fading_toggle = properties.fading or properties.Fading or false;
                -- auto = box grows with its elements (no inner scroll) - put it in a column({ scroll = true })
                auto = properties.auto or properties.Auto or false;
                column = self;
                items = {};
            };
            
            local items = cfg.items; do 
                items[ "outline" ] = library:create( "Frame" , {
                    Name = "\0";
                    Parent = self.items[ "column" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, cfg.size, -3);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(25, 25, 29)
                });

                library:create( "UICorner" , {
                    Parent = items[ "outline" ];
                    CornerRadius = dim(0, 7)
                });
                
                items[ "inline" ] = library:create( "Frame" , {
                    Parent = items[ "outline" ];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -2, 1, -2);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "inline" ];
                    CornerRadius = dim(0, 7)
                });
                
                items[ "scrolling" ] = library:create( "ScrollingFrame" , {
                    ScrollBarImageColor3 = rgb(44, 44, 46);
                    Active = true;
                    AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    ScrollBarThickness = 2;
                    Parent = items[ "inline" ];
                    Name = "\0";
                    Size = dim2(1, 0, 1, -33);
                    BackgroundTransparency = 1;
                    Position = dim2(0, 0, 0, 28);
                    BackgroundColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    CanvasSize = dim2(0, 0, 0, 0)
                });
                
                items[ "elements" ] = library:create( "Frame" , {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items[ "scrolling" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 10, 0, 10);
                    Size = dim2(1, -20, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    Parent = items[ "elements" ];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                
                library:create( "UIPadding" , {
                    PaddingBottom = dim(0, 15);
                    Parent = items[ "elements" ]
                });
                
                items[ "button" ] = library:create( "TextButton" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    Parent = items[ "outline" ];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    Size = dim2(1, -2, 0, 28);
                    BorderSizePixel = 0;
                    TextSize = 16;
                    BackgroundColor3 = rgb(19, 19, 21)
                });
                
                library:create( "UIStroke" , {
                    Color = rgb(23, 23, 29);
                    Parent = items[ "button" ];
                    Enabled = false;
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "button" ];
                    CornerRadius = dim(0, 7)
                });
                
                items[ "Icon" ] = library:create( "ImageLabel" , {
                    ImageColor3 = themes.preset.accent;
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items[ "button" ];
                    AnchorPoint = vec2(0, 0.5);
                    Image = cfg.icon;
                    BackgroundTransparency = 1;
                    Position = dim2(0, 9, 0.5, 0);
                    Name = "\0";
                    Size = dim2(0, 16, 0, 16);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items[ "Icon" ], "accent", "ImageColor3");
                
                items[ "section_title" ] = library:create( "TextLabel" , {
                    FontFace = fonts.bold;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "button" ];
                    Name = "\0";
                    Size = dim2(0, 0, 1, 0);
                    Position = dim2(0, 30, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.X;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = items[ "button" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
                
                if cfg.fading_toggle then 
                    items[ "toggle" ] = library:create( "TextButton" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        AutoButtonColor = false;
                        Text = "";
                        AnchorPoint = vec2(1, 0.5);
                        Parent = items[ "button" ];
                        Name = "\0";
                        Position = dim2(1, -9, 0.5, 0);
                        Size = dim2(0, 36, 0, 18);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(58, 58, 62)
                    });  library:apply_theme(items[ "toggle" ], "accent", "BackgroundColor3");
                    
                    library:create( "UICorner" , {
                        Parent = items[ "toggle" ];
                        CornerRadius = dim(0, 999)
                    });
                    
                    items[ "toggle_outline" ] = library:create( "Frame" , {
                        Parent = items[ "toggle" ];
                        Size = dim2(1, -2, 1, -2);
                        Name = "\0";
                        BorderMode = Enum.BorderMode.Inset;
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(50, 50, 50)
                    });  library:apply_theme(items[ "toggle_outline" ], "accent", "BackgroundColor3");
                    
                    library:create( "UICorner" , {
                        Parent = items[ "toggle_outline" ];
                        CornerRadius = dim(0, 999)
                    });
                    
                    library:create( "UIGradient" , {
                        Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                        Parent = items[ "toggle_outline" ]
                    });
                    
                    items[ "toggle_circle" ] = library:create( "Frame" , {
                        Parent = items[ "toggle_outline" ];
                        Name = "\0";
                        Position = dim2(0, 2, 0, 2);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 12, 0, 12);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(86, 86, 88)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "toggle_circle" ];
                        CornerRadius = dim(0, 999)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "outline" ];
                        CornerRadius = dim(0, 7)
                    });
                
                    items[ "fade" ] = library:create( "Frame" , {
                        Parent = items[ "outline" ];
                        BackgroundTransparency = 0.800000011920929;
                        Name = "\0";
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "fade" ];
                        CornerRadius = dim(0, 7)
                    });
                end 
            end;

            if cfg.auto then
                items[ "outline" ].Size = dim2(1, 0, 0, 0)
                items[ "outline" ].AutomaticSize = Enum.AutomaticSize.Y
                items[ "inline" ].Size = dim2(1, -2, 0, 0)
                items[ "inline" ].AutomaticSize = Enum.AutomaticSize.Y

                library:create( "UIPadding" , {
                    Parent = items[ "outline" ];
                    PaddingBottom = dim(0, 1)
                });

                -- plain auto-sized holder instead of the fixed-height ScrollingFrame
                local holder = library:create( "Frame" , {
                    Parent = items[ "inline" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    Position = dim2(0, 0, 0, 28);
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                });
                items[ "elements" ].Parent = holder
                items[ "scrolling" ]:Destroy()
                items[ "scrolling" ] = holder
            end

            if cfg.fading_toggle then
                items[ "button" ].MouseButton1Click:Connect(function()
                    cfg.default = not cfg.default 
                    cfg.toggle_section(cfg.default) 
                end)

                function cfg.toggle_section(bool)
                    library:tween(items[ "toggle" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, Enum.EasingStyle.Quad)
                    library:tween(items[ "toggle_outline" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, Enum.EasingStyle.Quad)
                    library:tween(items[ "toggle_circle" ], {BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88), Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)}, Enum.EasingStyle.Quad)
                    library:tween(items[ "fade" ], {BackgroundTransparency = bool and 1 or 0.8}, Enum.EasingStyle.Quad)
                end 
            end 

            return setmetatable(cfg, library)
        end  

        function library:toggle(options) 
            local cfg = {
                enabled = options.enabled or nil,
                name = options.name or "Toggle",
                info = options.info or nil,
                flag = options.flag or library:next_flag(),
                
                -- "toggle" / "checkbox" (original picked one at random when not given)
                type = options.type and string.lower(options.type) or library.default_toggle_type or "toggle";

                default = options.default or false,
                folding = options.folding or false, 
                callback = options.callback or function() end,

                items = {};
                seperator = options.seperator or options.Seperator or false;
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items[ "toggle" ] = library:create( "TextButton" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "toggle" ];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then 
                    items[ "info" ] = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items[ "toggle" ];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 22);
                        LineHeight = 1.15;
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end 
                
                library:create( "UIPadding" , {
                    Parent = items[ "name" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
                
                items[ "right_components" ] = library:create( "Frame" , {
                    Parent = items[ "toggle" ];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items[ "right_components" ];
                    Padding = dim(0, 9);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                
                -- Toggle
                    if cfg.type == "checkbox" then 
                        items[ "toggle_button" ] = library:create( "TextButton" , {
                            FontFace = fonts.small;
                            TextColor3 = rgb(0, 0, 0);
                            BorderColor3 = rgb(0, 0, 0);
                            Text = "";
                            LayoutOrder = 2;
                            AutoButtonColor = false;
                            AnchorPoint = vec2(1, 0);
                            Parent = items[ "right_components" ];
                            Name = "\0";
                            Position = dim2(1, 0, 0, 0);
                            Size = dim2(0, 16, 0, 16);
                            BorderSizePixel = 0;
                            TextSize = 14;
                            BackgroundColor3 = rgb(67, 67, 68)
                        }); library:apply_theme(items[ "toggle_button" ], "accent", "BackgroundColor3");
                        
                        library:create( "UICorner" , {
                            Parent = items[ "toggle_button" ];
                            CornerRadius = dim(0, 4)
                        });
                        
                        items[ "outline" ] = library:create( "Frame" , {
                            Parent = items[ "toggle_button" ];
                            Size = dim2(1, -2, 1, -2);
                            Name = "\0";
                            BorderMode = Enum.BorderMode.Inset;
                            BorderColor3 = rgb(0, 0, 0);
                            Position = dim2(0, 1, 0, 1);
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(22, 22, 24)
                        }); library:apply_theme(items[ "outline" ], "accent", "BackgroundColor3");
                        
                        items[ "tick" ] = library:create( "ImageLabel" , {
                            ImageTransparency = 1;
                            BorderColor3 = rgb(0, 0, 0);
                            Image = "rbxassetid://111862698467575";
                            BackgroundTransparency = 1;
                            Position = dim2(0, -1, 0, 0);
                            Parent = items[ "outline" ];
                            Size = dim2(1, 2, 1, 2);
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255);
                            ZIndex = 1;
                        });

                        library:create( "UICorner" , {
                            Parent = items[ "outline" ];
                            CornerRadius = dim(0, 4)
                        });
                        
                        library:create( "UIGradient" , {
                            Enabled = false;
                            Parent = items[ "outline" ];
                            Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))}
                        });  
                    else 
                        items[ "toggle_button" ] = library:create( "TextButton" , {
                            FontFace = fonts.font;
                            TextColor3 = rgb(0, 0, 0);
                            BorderColor3 = rgb(0, 0, 0);
                            Text = "";
                            LayoutOrder = 2;
                            AnchorPoint = vec2(1, 0.5);
                            Parent = items[ "right_components" ];
                            Name = "\0";
                            Position = dim2(1, -9, 0.5, 0);
                            Size = dim2(0, 36, 0, 18);
                            BorderSizePixel = 0;
                            TextSize = 14;
                            BackgroundColor3 = themes.preset.accent
                        }); library:apply_theme(items[ "toggle_button" ], "accent", "BackgroundColor3");
                        
                        library:create( "UICorner" , {
                            Parent = items[ "toggle_button" ];
                            CornerRadius = dim(0, 999)
                        });
                        
                        items[ "inline" ] = library:create( "Frame" , {
                            Parent = items[ "toggle_button" ];
                            Size = dim2(1, -2, 1, -2);
                            Name = "\0";
                            BorderMode = Enum.BorderMode.Inset;
                            BorderColor3 = rgb(0, 0, 0);
                            Position = dim2(0, 1, 0, 1);
                            BorderSizePixel = 0;
                            BackgroundColor3 = themes.preset.accent
                        }); library:apply_theme(items[ "inline" ], "accent", "BackgroundColor3");
                        
                        library:create( "UICorner" , {
                            Parent = items[ "inline" ];
                            CornerRadius = dim(0, 999)
                        });
                        
                        library:create( "UIGradient" , {
                            Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                            Parent = items[ "inline" ]
                        });
                        
                        items[ "circle" ] = library:create( "Frame" , {
                            Parent = items[ "inline" ];
                            Name = "\0";
                            Position = dim2(1, -14, 0, 2);
                            BorderColor3 = rgb(0, 0, 0);
                            Size = dim2(0, 12, 0, 12);
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                        
                        library:create( "UICorner" , {
                            Parent = items[ "circle" ];
                            CornerRadius = dim(0, 999)
                        });                        
                    end 
                --                
            end;
            
            function cfg.set(bool)
                if cfg.type == "checkbox" then 
                    library:tween(items[ "tick" ], {Rotation = bool and 0 or 45, ImageTransparency = bool and 0 or 1})
                    library:tween(items[ "toggle_button" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(67, 67, 68)})
                    library:tween(items[ "outline" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(22, 22, 24)})
                else
                    library:tween(items[ "toggle_button" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(58, 58, 62)}, Enum.EasingStyle.Quad)
                    library:tween(items[ "inline" ], {BackgroundColor3 = bool and themes.preset.accent or rgb(50, 50, 50)}, Enum.EasingStyle.Quad)
                    library:tween(items[ "circle" ], {BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(86, 86, 88), Position = bool and dim2(1, -14, 0, 2) or dim2(0, 2, 0, 2)}, Enum.EasingStyle.Quad)
                end

                cfg.callback(bool)

                if cfg.folding then 
                    elements.Visible = bool
                end

                flags[cfg.flag] = bool
            end 
            
            items[ "toggle" ].MouseButton1Click:Connect(function()
                cfg.enabled = not cfg.enabled 
                cfg.set(cfg.enabled)
            end)

            items[ "toggle_button" ].MouseButton1Click:Connect(function()
                cfg.enabled = not cfg.enabled 
                cfg.set(cfg.enabled)
            end)
            
            if cfg.seperator then -- ok bro my lua either sucks or this was a pain in the ass to make (simple if statement aswell 💔)
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items[ "elements" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            -- clicking flips cfg.enabled - start it at the default (was nil, first click on a
            -- default-on toggle did nothing)
            cfg.enabled = cfg.default and true or false
            cfg.set(cfg.default)

            config_flags[cfg.flag] = function(value)
                cfg.enabled = value and true or false
                cfg.set(cfg.enabled)
            end

            library:searchable(self, cfg.name, items[ "toggle" ])
            return setmetatable(cfg, library)
        end 
        
        function library:slider(options) 
            local cfg = {
                name = options.name or nil,
                suffix = options.suffix or "",
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end, 
                info = options.info or nil; 

                -- value settings
                min = options.min or options.minimum or 0,
                max = options.max or options.maximum or 100,
                intervals = options.interval or options.decimal or 1,
                default = options.default or 10,
                value = options.default or 10, 
                seperator = (function() local v = options.seperator; if v == nil then v = options.Seperator end; if v == nil then v = true end; return v end)();

                dragging = false,
                items = {}
            } 

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                items[ "slider_object" ] = library:create( "TextButton" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "slider_object" ];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                if cfg.info then 
                    items[ "info" ] = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items[ "slider_object" ];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 42);
                        LineHeight = 1.15;
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end 

                library:create( "UIPadding" , {
                    Parent = items[ "name" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
                
                items[ "right_components" ] = library:create( "Frame" , {
                    Parent = items[ "slider_object" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 4, 0, 23);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    Parent = items[ "right_components" ];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    FillDirection = Enum.FillDirection.Horizontal
                });
                
                items[ "slider" ] = library:create( "TextButton" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = items[ "right_components" ];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(1, -4, 0, 4);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "slider" ];
                    CornerRadius = dim(0, 999)
                });
                
                items[ "fill" ] = library:create( "Frame" , {
                    Name = "\0";
                    Parent = items[ "slider" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0.5, 0, 0, 4);
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent
                });  library:apply_theme(items[ "fill" ], "accent", "BackgroundColor3");
                
                library:create( "UICorner" , {
                    Parent = items[ "fill" ];
                    CornerRadius = dim(0, 999)
                });
                
                items[ "circle" ] = library:create( "Frame" , {
                    AnchorPoint = vec2(0.5, 0.5);
                    Parent = items[ "fill" ];
                    Name = "\0";
                    Position = dim2(1, 0, 0.5, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 12, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(244, 244, 244)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "circle" ];
                    CornerRadius = dim(0, 999)
                });
                
                library:create( "UIPadding" , {
                    Parent = items[ "right_components" ];
                    PaddingTop = dim(0, 4)
                });
                
                -- value is a TextBox: click it and type a number (the suffix is hidden while typing)
                items[ "value" ] = library:create( "TextBox" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    PlaceholderText = "";
                    ClearTextOnFocus = false;
                    Parent = items[ "slider_object" ];
                    Name = "\0";
                    AnchorPoint = vec2(1, 0);
                    Size = dim2(0, 0, 0, 0);
                    Position = dim2(1, 6, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Right;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIPadding" , {
                    Parent = items[ "value" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });                
            end 

            function cfg.set(value)
                cfg.value = clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)

                library:tween(items[ "fill" ], {Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), cfg.value == cfg.min and 0 or -4, 0, 2)}, Enum.EasingStyle.Linear, 0.05)
                -- while the box is being typed in, leave the text alone (no suffix, no overwrite)
                if not items[ "value" ]:IsFocused() then
                    items[ "value" ].Text = tostring(cfg.value) .. cfg.suffix
                end

                flags[cfg.flag] = cfg.value
                cfg.callback(flags[cfg.flag])
            end

            local function set_from_x(x)
                local size_x = clamp((x - items[ "slider" ].AbsolutePosition.X) / items[ "slider" ].AbsoluteSize.X, 0, 1)
                cfg.set(((cfg.max - cfg.min) * size_x) + cfg.min)
            end

            -- the 4px track is hard to hit (worse on touch) - grab from the whole row under the title
            items[ "right_components" ].Active = true
            items[ "right_components" ].InputBegan:Connect(function(input)
                if is_press(input) then
                    cfg.dragging = true
                    set_from_x(input.Position.X)
                    library:tween(items[ "value" ], {TextColor3 = rgb(255, 255, 255)}, Enum.EasingStyle.Quad, 0.2)
                end
            end)

            items[ "slider" ].MouseButton1Down:Connect(function(x)
                cfg.dragging = true
                set_from_x(x)
                library:tween(items[ "value" ], {TextColor3 = rgb(255, 255, 255)}, Enum.EasingStyle.Quad, 0.2)
            end)

            library:connection(uis.InputChanged, function(input)
                if cfg.dragging and is_move(input) then 
                    set_from_x(input.Position.X)
                end
            end)

            -- typed value: show the bare number while editing, Enter / click away = apply (clamped +
            -- rounded to the interval by cfg.set), anything that is not a number = keep the old value
            items[ "value" ].Focused:Connect(function()
                items[ "value" ].Text = tostring(cfg.value)
                items[ "value" ].CursorPosition = #items[ "value" ].Text + 1
                items[ "value" ].SelectionStart = 1
                library:tween(items[ "value" ], {TextColor3 = rgb(255, 255, 255)}, Enum.EasingStyle.Quad, 0.2)
            end)

            items[ "value" ].FocusLost:Connect(function()
                local number = tonumber((items[ "value" ].Text:gsub(",", "."):match("%-?%d+%.?%d*")))
                library:tween(items[ "value" ], {TextColor3 = rgb(72, 72, 73)}, Enum.EasingStyle.Quad, 0.2)
                if number then
                    cfg.set(number)
                else
                    items[ "value" ].Text = tostring(cfg.value) .. cfg.suffix
                end
            end)

            library:connection(uis.InputEnded, function(input)
                if cfg.dragging and is_press(input) then
                    cfg.dragging = false
                    library:tween(items[ "value" ], {TextColor3 = rgb(72, 72, 73)}, Enum.EasingStyle.Quad, 0.2) 
                end 
            end)

            if cfg.seperator then 
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items[ "elements" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end 

            cfg.set(cfg.default)
            config_flags[cfg.flag] = cfg.set

            library:searchable(self, cfg.name, items[ "slider_object" ])
            return setmetatable(cfg, library)
        end 

        function library:dropdown(options)
            local cfg = {
                name = options.name or nil;
                info = options.info or nil;
                flag = options.flag or library:next_flag();
                options = options.items or options.options or {""};
                callback = options.callback or function() end;
                multi = options.multi or false;
                scrolling = options.scrolling or false;
                -- search box on top of the list (options.search = false hides it)
                search = options.search ~= false;
                max_height = options.max_height or 170;

                width = options.width or 130;

                -- Ignore these
                open = false;
                option_instances = {};
                multi_items = {};
                ignore = options.ignore or false;
                items = {};
                seperator = (function() local v = options.seperator; if v == nil then v = options.Seperator end; if v == nil then v = true end; return v end)();
            }

            local option_height = 18
            local option_gap = 2
            local search_height = cfg.search and 24 or 0

            if options.default ~= nil then
                cfg.default = options.default
            elseif cfg.multi then
                cfg.default = {}
            else
                cfg.default = cfg.options[1]
            end
            flags[cfg.flag] = cfg.default

            local items = cfg.items; do
                -- Element
                    items[ "dropdown_object" ] = library:create( "TextButton" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = self.items[ "elements" ];
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.Y;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    items[ "name" ] = library:create( "TextLabel" , {
                        FontFace = fonts.font;
                        TextColor3 = rgb(245, 245, 245);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = cfg.name or "Dropdown";
                        Parent = items[ "dropdown_object" ];
                        Name = "\0";
                        Size = dim2(1, -(cfg.width + 8), 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.Y;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    if cfg.info then
                        items[ "info" ] = library:create( "TextLabel" , {
                            FontFace = fonts.small;
                            TextColor3 = rgb(130, 130, 130);
                            BorderColor3 = rgb(0, 0, 0);
                            TextWrapped = true;
                            Text = cfg.info;
                            Parent = items[ "dropdown_object" ];
                            Name = "\0";
                            Position = dim2(0, 5, 0, 22);
                            LineHeight = 1.15;
                            Size = dim2(1, -10, 0, 0);
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.XY;
                            TextSize = 16;
                            BackgroundColor3 = rgb(255, 255, 255)
                        });
                    end

                    library:create( "UIPadding" , {
                        Parent = items[ "name" ];
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });

                    items[ "right_components" ] = library:create( "Frame" , {
                        Parent = items[ "dropdown_object" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });

                    library:create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Horizontal;
                        HorizontalAlignment = Enum.HorizontalAlignment.Right;
                        Parent = items[ "right_components" ];
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });

                    items[ "dropdown" ] = library:create( "TextButton" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Parent = items[ "right_components" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        Size = dim2(0, cfg.width, 0, 18);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(33, 33, 35)
                    });

                    library:create( "UICorner" , {
                        Parent = items[ "dropdown" ];
                        CornerRadius = dim(0, 4)
                    });

                    items[ "dropdown_stroke" ] = library:create( "UIStroke" , {
                        Parent = items[ "dropdown" ];
                        Color = themes.preset.accent;
                        Transparency = 1;
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    });

                    items[ "sub_text" ] = library:no_translate(library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(86, 86, 87);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = items[ "dropdown" ];
                        Name = "\0";
                        Size = dim2(1, -16, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    }));

                    library:create( "UIPadding" , {
                        Parent = items[ "sub_text" ];
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });

                    items[ "indicator" ] = library:create( "ImageLabel" , {
                        ImageColor3 = rgb(86, 86, 87);
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = items[ "dropdown" ];
                        AnchorPoint = vec2(1, 0.5);
                        Image = "rbxassetid://101025591575185";
                        BackgroundTransparency = 1;
                        Position = dim2(1, -5, 0.5, 0);
                        Name = "\0";
                        Size = dim2(0, 12, 0, 12);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                --

                -- Element Holder (popup, lives in the root gui so the section's clipping does not cut it)
                    items[ "dropdown_holder" ] = library:create( "Frame" , {
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = library[ "items" ];
                        Name = "\0";
                        Visible = false;
                        BackgroundTransparency = 1;
                        Size = dim2(0, 0, 0, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0);
                        ZIndex = 10;
                    });

                    items[ "holder_scale" ] = library:create( "UIScale" , {
                        Parent = items[ "dropdown_holder" ];
                        Scale = 1;
                    });

                    items[ "outline" ] = library:create( "Frame" , {
                        Parent = items[ "dropdown_holder" ];
                        Size = dim2(1, 0, 1, 0);
                        ClipsDescendants = true;
                        BorderColor3 = rgb(0, 0, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(33, 33, 35);
                        ZIndex = 10;
                    });

                    library:create( "UICorner" , {
                        Parent = items[ "outline" ];
                        CornerRadius = dim(0, 4)
                    });

                    library:create( "UIStroke" , {
                        Parent = items[ "outline" ];
                        Color = rgb(23, 23, 29);
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    });

                    if cfg.search then
                        items[ "search" ] = library:create( "TextBox" , {
                            Parent = items[ "outline" ];
                            Name = "\0";
                            FontFace = fonts.small;
                            Text = "";
                            PlaceholderText = translate("Search...");
                            PlaceholderColor3 = rgb(86, 86, 87);
                            TextColor3 = rgb(245, 245, 245);
                            TextSize = 14;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            TextTruncate = Enum.TextTruncate.AtEnd;
                            ClearTextOnFocus = false;
                            Position = dim2(0, 4, 0, 4);
                            Size = dim2(1, -8, 0, search_height - 6);
                            BorderSizePixel = 0;
                            BackgroundColor3 = rgb(22, 22, 24);
                            ZIndex = 11;
                        });

                        library:create( "UICorner" , {
                            Parent = items[ "search" ];
                            CornerRadius = dim(0, 3)
                        });

                        library:create( "UIPadding" , {
                            Parent = items[ "search" ];
                            PaddingLeft = dim(0, 22);
                            PaddingRight = dim(0, 5)
                        });

                        library:create( "ImageLabel" , {
                            Parent = items[ "search" ];
                            Name = "\0";
                            Image = "rbxassetid://6031154871";
                            ImageColor3 = rgb(86, 86, 87);
                            BackgroundTransparency = 1;
                            AnchorPoint = vec2(0, 0.5);
                            Position = dim2(0, -17, 0.5, 0);
                            Size = dim2(0, 12, 0, 12);
                            ZIndex = 11;
                        });
                    end

                    items[ "list" ] = library:create( "ScrollingFrame" , {
                        Parent = items[ "outline" ];
                        Name = "\0";
                        Active = true;
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        Position = dim2(0, 0, 0, search_height);
                        Size = dim2(1, 0, 1, -search_height);
                        CanvasSize = dim2(0, 0, 0, 0);
                        AutomaticCanvasSize = Enum.AutomaticSize.Y;
                        ScrollBarThickness = 2;
                        ScrollBarImageColor3 = rgb(44, 44, 46);
                        ScrollingDirection = Enum.ScrollingDirection.Y;
                        ZIndex = 10;
                    });

                    library:create( "UIPadding" , {
                        PaddingBottom = dim(0, 4);
                        PaddingTop = dim(0, 3);
                        PaddingLeft = dim(0, 3);
                        PaddingRight = dim(0, 4);
                        Parent = items[ "list" ]
                    });

                    library:create( "UIListLayout" , {
                        Parent = items[ "list" ];
                        Padding = dim(0, option_gap);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });

                    items[ "empty" ] = library:create( "TextLabel" , {
                        Parent = items[ "list" ];
                        Name = "\0";
                        FontFace = fonts.small;
                        Text = "No results";
                        TextColor3 = rgb(72, 72, 73);
                        TextSize = 14;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, option_height);
                        LayoutOrder = 1e6;
                        Visible = false;
                        ZIndex = 10;
                    });

                    library:create( "UIPadding" , {
                        Parent = items[ "empty" ];
                        PaddingLeft = dim(0, 5)
                    });
                --
            end

            function cfg.render_option(text)
                local button = library:no_translate(library:create( "TextButton" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(72, 72, 73);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = tostring(text);
                    Parent = items[ "list" ];
                    Name = "\0";
                    AutoButtonColor = false;
                    Size = dim2(1, 0, 0, option_height);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(22, 22, 24);
                    ZIndex = 10;
                })); library:apply_theme(button, "accent", "TextColor3");

                library:create( "UICorner" , {
                    Parent = button;
                    CornerRadius = dim(0, 3)
                });

                library:create( "UIPadding" , {
                    Parent = button;
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });

                button.MouseEnter:Connect(function()
                    library:tween(button, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad, 0.15)
                end)
                button.MouseLeave:Connect(function()
                    library:tween(button, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.15)
                end)

                return button
            end

            -- selected = accent, rest dim (no callback - used after refresh / by set)
            local function is_selected(text)
                local value = flags[cfg.flag]
                if type(value) == "table" then return find(value, text) ~= nil end
                return value == text
            end

            local function paint()
                for _, option in cfg.option_instances do
                    option.TextColor3 = is_selected(option.Text) and themes.preset.accent or theme_color(rgb(72, 72, 73))
                end
            end

            -- filter by the search text, then size the popup to the visible rows (capped at max_height)
            local function content_height()
                local query = items[ "search" ] and string.lower(items[ "search" ].Text) or ""
                local shown = 0

                for _, option in cfg.option_instances do
                    local visible = query == "" or string.find(string.lower(option.Text), query, 1, true) ~= nil
                    option.Visible = visible
                    if visible then shown += 1 end
                end

                items[ "empty" ].Visible = shown == 0
                local rows = max(shown, 1)
                return search_height + min(rows * (option_height + option_gap) + 7, cfg.max_height)
            end

            local follow = nil

            local function place()
                local window_scale = library.current_scale or 1
                items[ "holder_scale" ].Scale = window_scale
                items[ "dropdown_holder" ].Position = library:below(items[ "dropdown" ], 3)
            end

            function cfg.set_visible(bool)
                if follow then follow:Disconnect() follow = nil end

                if bool then
                    if items[ "search" ] then
                        items[ "search" ].Text = ""
                        items[ "search" ].PlaceholderText = translate("Search...")
                    end
                    place()

                    local window_scale = library.current_scale or 1
                    local width = max(items[ "dropdown" ].AbsoluteSize.X / window_scale, 120)
                    items[ "dropdown_holder" ].Visible = true
                    items[ "dropdown_holder" ].Size = dim_offset(width, 0)
                    library:tween(items[ "dropdown_holder" ], {Size = dim_offset(width, content_height())}, Enum.EasingStyle.Quad, 0.2)
                    library:tween(items[ "dropdown_stroke" ], {Transparency = 0.4}, Enum.EasingStyle.Quad, 0.2)
                    library:tween(items[ "indicator" ], {Rotation = 180}, Enum.EasingStyle.Quad, 0.2)

                    -- follow the element while open (section scrolling / window dragging)
                    follow = run.RenderStepped:Connect(function()
                        if not items[ "dropdown" ].Parent then return end
                        place()
                    end)
                else
                    library:tween(items[ "dropdown_holder" ], {Size = dim_offset(items[ "dropdown_holder" ].Size.X.Offset, 0)}, Enum.EasingStyle.Quad, 0.15)
                    library:tween(items[ "dropdown_stroke" ], {Transparency = 1}, Enum.EasingStyle.Quad, 0.2)
                    library:tween(items[ "indicator" ], {Rotation = 0}, Enum.EasingStyle.Quad, 0.2)
                    task.delay(0.16, function()
                        if not cfg.open then items[ "dropdown_holder" ].Visible = false end
                    end)
                    if items[ "search" ] and items[ "search" ]:IsFocused() then items[ "search" ]:ReleaseFocus() end
                end

                -- opening closes whatever popup was open; closing just clears ourselves
                -- (close_element(nil) here would call back into set_visible(false) forever)
                if bool then
                    if not (self.sanity and library.current_open == self) then
                        library:close_element(cfg)
                    end
                elseif library.current_open == cfg then
                    library.current_open = nil
                end
            end

            function cfg.set(value)
                local selected = {}
                local isTable = type(value) == "table"

                for _, option in cfg.option_instances do
                    if option.Text == value or (isTable and find(value, option.Text)) then
                        insert(selected, option.Text)
                    end
                end

                if cfg.multi then cfg.multi_items = selected end

                -- nothing picked -> "..." (empty box looked broken)
                local shown = isTable and concat(selected, ", ") or selected[1] or ""
                items[ "sub_text" ].Text = shown ~= "" and shown or "..."
                flags[cfg.flag] = isTable and selected or selected[1]
                paint()

                cfg.callback(flags[cfg.flag])
            end

            function cfg.get()
                return flags[cfg.flag]
            end

            -- refresh_options(list [, value]) - keeps the current selection when it is still in the list
            function cfg.refresh_options(list, value)
                for _, option in cfg.option_instances do
                    option:Destroy()
                end

                cfg.option_instances = {}
                cfg.options = list

                for index, option in list do
                    local button = cfg.render_option(option)
                    button.LayoutOrder = index
                    insert(cfg.option_instances, button)

                    button.MouseButton1Click:Connect(function()
                        if cfg.multi then
                            local current = type(flags[cfg.flag]) == "table" and table.clone(flags[cfg.flag]) or {}
                            local selected_index = find(current, button.Text)

                            if selected_index then
                                remove(current, selected_index)
                            else
                                insert(current, button.Text)
                            end

                            cfg.set(current)
                        else
                            cfg.open = false
                            cfg.set_visible(false)

                            cfg.set(button.Text)
                        end
                    end)
                end

                if value ~= nil then
                    cfg.set(value)
                else
                    paint()
                    if cfg.open then
                        items[ "dropdown_holder" ].Size = dim_offset(items[ "dropdown_holder" ].Size.X.Offset, content_height())
                    end
                end
            end
            cfg.refresh = cfg.refresh_options

            if items[ "search" ] then
                items[ "search" ]:GetPropertyChangedSignal("Text"):Connect(function()
                    if not cfg.open then return end
                    items[ "dropdown_holder" ].Size = dim_offset(items[ "dropdown_holder" ].Size.X.Offset, content_height())
                    items[ "list" ].CanvasPosition = vec2(0, 0)
                end)

                -- Enter = pick the first match (single select)
                items[ "search" ].FocusLost:Connect(function(enter)
                    if not (enter and cfg.open and not cfg.multi) then return end
                    for _, option in cfg.option_instances do
                        if option.Visible then
                            cfg.open = false
                            cfg.set_visible(false)
                            cfg.set(option.Text)
                            return
                        end
                    end
                end)
            end

            items[ "dropdown" ].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            items[ "dropdown" ].MouseEnter:Connect(function()
                if not cfg.open then library:tween(items[ "dropdown_stroke" ], {Transparency = 0.75}, Enum.EasingStyle.Quad, 0.15) end
            end)
            items[ "dropdown" ].MouseLeave:Connect(function()
                if not cfg.open then library:tween(items[ "dropdown_stroke" ], {Transparency = 1}, Enum.EasingStyle.Quad, 0.15) end
            end)

            if cfg.seperator then
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items[ "elements" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end

            config_flags[cfg.flag] = cfg.set

            cfg.refresh_options(cfg.options)
            cfg.set(cfg.default)

            library:searchable(self, cfg.name, items[ "dropdown_object" ])
            return setmetatable(cfg, library)
        end

        -- paragraph({ title, desc, color }) - card with a colored bar on the left, title + wrapped text
        -- (status cards / how-to guides). set_title / set_desc / set_color / set_visible
        function library:paragraph(options)
            local cfg = {
                title = options.title or options.name or "Paragraph";
                desc = options.desc or options.info or "";
                items = {};
            }

            local items = cfg.items; do
                items[ "holder" ] = library:create( "Frame" , {
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BorderSizePixel = 0;
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(33, 33, 35)
                });

                library:create( "UICorner" , {
                    Parent = items[ "holder" ];
                    CornerRadius = dim(0, 5)
                });

                items[ "bar" ] = library:create( "Frame" , {
                    Parent = items[ "holder" ];
                    Name = "\0";
                    BorderSizePixel = 0;
                    Position = dim2(0, 5, 0, 6);
                    Size = dim2(0, 3, 1, -12);
                    BackgroundColor3 = options.color or themes.preset.accent
                });

                library:create( "UICorner" , {
                    Parent = items[ "bar" ];
                    CornerRadius = dim(0, 999)
                });

                items[ "content" ] = library:create( "Frame" , {
                    Parent = items[ "holder" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                });

                library:create( "UIListLayout" , {
                    Parent = items[ "content" ];
                    Padding = dim(0, 3);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });

                library:create( "UIPadding" , {
                    Parent = items[ "content" ];
                    PaddingTop = dim(0, 6);
                    PaddingBottom = dim(0, 7);
                    PaddingLeft = dim(0, 15);
                    PaddingRight = dim(0, 8)
                });

                items[ "title" ] = library:create( "TextLabel" , {
                    Parent = items[ "content" ];
                    Name = "\0";
                    FontFace = fonts.font;
                    Text = cfg.title;
                    TextColor3 = rgb(245, 245, 245);
                    TextSize = 16;
                    TextWrapped = true;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    LayoutOrder = 1;
                });

                items[ "desc" ] = library:create( "TextLabel" , {
                    Parent = items[ "content" ];
                    Name = "\0";
                    FontFace = fonts.small;
                    Text = cfg.desc;
                    TextColor3 = rgb(130, 130, 130);
                    TextSize = 14;
                    TextWrapped = true;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextYAlignment = Enum.TextYAlignment.Top;
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    LayoutOrder = 2;
                });
            end

            function cfg.set_title(text)
                items[ "title" ].Text = tostring(text)
            end

            function cfg.set_desc(text)
                items[ "desc" ].Text = tostring(text)
                items[ "desc" ].Visible = tostring(text) ~= ""
            end

            function cfg.set_color(color)
                items[ "bar" ].BackgroundColor3 = color
            end

            function cfg.set_visible(bool)
                items[ "holder" ].Visible = bool and true or false
            end

            cfg.set_desc(cfg.desc)

            library:searchable(self, cfg.title, items[ "holder" ])
            return setmetatable(cfg, library)
        end

        function library:label(options)
            local cfg = {
                enabled = options.enabled or nil,
                name = options.name or "Toggle",
                seperator = options.seperator or options.Seperator or false;
                info = options.info or nil; 

                items = {};
            }

            local items = cfg.items; do 
                items[ "label" ] = library:create( "TextButton" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "label" ];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });

                if cfg.info then 
                    items[ "info" ] = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(130, 130, 130);
                        BorderColor3 = rgb(0, 0, 0);
                        TextWrapped = true;
                        Text = cfg.info;
                        Parent = items[ "label" ];
                        Name = "\0";
                        Position = dim2(0, 5, 0, 22);
                        LineHeight = 1.15;
                        Size = dim2(1, -10, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                end 
                
                library:create( "UIPadding" , {
                    Parent = items[ "name" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
                
                items[ "right_components" ] = library:create( "Frame" , {
                    Parent = items[ "label" ];
                    Name = "\0";
                    Position = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 1, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Right;
                    Parent = items[ "right_components" ];
                    Padding = dim(0, 9);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });                
            end 

            if cfg.seperator then 
                library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = self.items[ "elements" ];
                    Position = dim2(0, 0, 1, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 1, 0, 1);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(36, 36, 37)
                });
            end 

            library:searchable(self, cfg.name, items[ "label" ])
            return setmetatable(cfg, library)
        end 
        
        function library:colorpicker(options) 
            local cfg = {
                name = options.name or "Color", 
                flag = options.flag or library:next_flag(),

                color = options.color or color(1, 1, 1), -- Default to white color if not provided
                alpha = options.alpha and 1 - options.alpha or 0,
                
                open = false, 
                callback = options.callback or function() end,
                items = {};

                seperator = options.seperator or options.Seperator or false;
            }

            local dragging_sat = false 
            local dragging_hue = false 
            local dragging_alpha = false 

            local h, s, v = cfg.color:ToHSV() 
            local a = cfg.alpha 

            flags[cfg.flag] = {Color = cfg.color, Transparency = cfg.alpha}

            local label; 
            if not self.items.right_components then 
                label = self:label({name = cfg.name, seperator = cfg.seperator})
            end

            local items = cfg.items; do 
                -- Component
                    items[ "colorpicker" ] = library:create( "TextButton" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Parent = label and label.items.right_components or self.items[ "right_components" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        Size = dim2(0, 16, 0, 16);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(54, 31, 184)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "colorpicker" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    items[ "colorpicker_inline" ] = library:create( "Frame" , {
                        Parent = items[ "colorpicker" ];
                        Size = dim2(1, -2, 1, -2);
                        Name = "\0";
                        BorderMode = Enum.BorderMode.Inset;
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(0, 1, 0, 1);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(54, 31, 184)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "colorpicker_inline" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    library:create( "UIGradient" , {
                        Color = rgbseq{rgbkey(0, rgb(211, 211, 211)), rgbkey(1, rgb(211, 211, 211))};
                        Parent = items[ "colorpicker_inline" ]
                    });         
                --
                
                -- Colorpicker
                    items[ "colorpicker_holder" ] = library:create( "Frame" , {
                        Parent = library[ "other" ];
                        Name = "\0";
                        Position = dim2(0.20000000298023224, 20, 0.296999990940094, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 166, 0, 197);
                        BorderSizePixel = 0;
                        Visible = true;
                        BackgroundColor3 = rgb(25, 25, 29)
                    });

                    items[ "colorpicker_fade" ] = library:create( "Frame" , {
                        Parent = items[ "colorpicker_holder" ];
                        Name = "\0";
                        BackgroundTransparency = 0;
                        Position = dim2(0, 0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        ZIndex = 100;
                        BackgroundColor3 = rgb(25, 25, 29)
                    });
                    
                    items[ "colorpicker_components" ] = library:create( "Frame" , {
                        Parent = items[ "colorpicker_holder" ];
                        Name = "\0";
                        Position = dim2(0, 1, 0, 1);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -2, 1, -2);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(22, 22, 24)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "colorpicker_components" ];
                        CornerRadius = dim(0, 6)
                    });
                    
                    items[ "saturation_holder" ] = library:create( "Frame" , {
                        Parent = items[ "colorpicker_components" ];
                        Name = "\0";
                        Position = dim2(0, 7, 0, 7);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -14, 1, -80);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 39, 39)
                    });
                    
                    items[ "sat" ] = library:create( "TextButton" , {
                        Parent = items[ "saturation_holder" ];
                        Name = "\0";
                        Size = dim2(1, 0, 1, 0);
                        Text = "";
                        AutoButtonColor = false;
                        BorderColor3 = rgb(0, 0, 0);
                        ZIndex = 2;
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "sat" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    library:create( "UIGradient" , {
                        Rotation = 270;
                        Transparency = numseq{numkey(0, 0), numkey(1, 1)};
                        Parent = items[ "sat" ];
                        Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(0, 0, 0))}
                    });
                    
                    items[ "val" ] = library:create( "Frame" , {
                        Name = "\0";
                        Parent = items[ "saturation_holder" ];
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIGradient" , {
                        Parent = items[ "val" ];
                        Transparency = numseq{numkey(0, 0), numkey(1, 1)}
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "val" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "saturation_holder" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    items[ "satvalpicker" ] = library:create( "TextButton" , {
                        BorderColor3 = rgb(0, 0, 0);
                        AutoButtonColor = false;
                        Text = "";
                        AnchorPoint = vec2(0, 1);
                        Parent = items[ "saturation_holder" ];
                        Name = "\0";
                        Position = dim2(0, 0, 4, 0);
                        Size = dim2(0, 8, 0, 8);
                        ZIndex = 5;
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 0, 0)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "satvalpicker" ];
                        CornerRadius = dim(0, 9999)
                    });
                    
                    library:create( "UIStroke" , {
                        Color = rgb(255, 255, 255);
                        Parent = items[ "satvalpicker" ];
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                    });
                    
                    items[ "hue_gradient" ] = library:create( "TextButton" , {
                        Parent = items[ "colorpicker_components" ];
                        Name = "\0";
                        Position = dim2(0, 10, 1, -64);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -20, 0, 8);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255);
                        AutoButtonColor = false;
                        Text = "";
                    });
                    
                    library:create( "UIGradient" , {
                        Color = rgbseq{rgbkey(0, rgb(255, 0, 0)), rgbkey(0.17, rgb(255, 255, 0)), rgbkey(0.33, rgb(0, 255, 0)), rgbkey(0.5, rgb(0, 255, 255)), rgbkey(0.67, rgb(0, 0, 255)), rgbkey(0.83, rgb(255, 0, 255)), rgbkey(1, rgb(255, 0, 0))};
                        Parent = items[ "hue_gradient" ]
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "hue_gradient" ];
                        CornerRadius = dim(0, 6)
                    });
                    
                    items[ "hue_picker" ] = library:create( "TextButton" , {
                        BorderColor3 = rgb(0, 0, 0);
                        AutoButtonColor = false;
                        Text = "";
                        AnchorPoint = vec2(0, 0.5);
                        Parent = items[ "hue_gradient" ];
                        Name = "\0";
                        Position = dim2(0, 0, 0.5, 0);
                        Size = dim2(0, 8, 0, 8);
                        ZIndex = 5;
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 0, 0)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "hue_picker" ];
                        CornerRadius = dim(0, 9999)
                    });
                    
                    library:create( "UIStroke" , {
                        Color = rgb(255, 255, 255);
                        Parent = items[ "hue_picker" ];
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                    });
                    
                    items[ "alpha_gradient" ] = library:create( "TextButton" , {
                        Parent = items[ "colorpicker_components" ];
                        Name = "\0";
                        Position = dim2(0, 10, 1, -46);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(1, -20, 0, 8);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(25, 25, 29);
                        AutoButtonColor = false;
                        Text = "";
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "alpha_gradient" ];
                        CornerRadius = dim(0, 6)
                    });
                    
                    items[ "alpha_picker" ] = library:create( "TextButton" , {
                        BorderColor3 = rgb(0, 0, 0);
                        AutoButtonColor = false;
                        Text = "";
                        AnchorPoint = vec2(0, 0.5);
                        Parent = items[ "alpha_gradient" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0.5, 0);
                        Size = dim2(0, 8, 0, 8);
                        ZIndex = 5;
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 0, 0)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "alpha_picker" ];
                        CornerRadius = dim(0, 9999)
                    });
                    
                    library:create( "UIStroke" , {
                        Color = rgb(255, 255, 255);
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                        Parent = items[ "alpha_picker" ]
                    });
                    
                    library:create( "UIGradient" , {
                        Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(255, 255, 255))};
                        Parent = items[ "alpha_gradient" ]
                    });
                    
                    items[ "alpha_indicator" ] = library:create( "ImageLabel" , {
                        ScaleType = Enum.ScaleType.Tile;
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = items[ "alpha_gradient" ];
                        Image = "rbxassetid://18274452449";
                        BackgroundTransparency = 1;
                        Name = "\0";
                        Size = dim2(1, 0, 1, 0);
                        TileSize = dim2(0, 6, 0, 6);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });
                    
                    library:create( "UIGradient" , {
                        Color = rgbseq{rgbkey(0, rgb(112, 112, 112)), rgbkey(1, rgb(255, 0, 0))};
                        Transparency = numseq{numkey(0, 0.8062499761581421), numkey(1, 0)};
                        Parent = items[ "alpha_indicator" ]
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "alpha_indicator" ];
                        CornerRadius = dim(0, 6)
                    });
                    
                    library:create( "UIGradient" , {
                        Rotation = 90;
                        Parent = items[ "colorpicker_components" ];
                        Color = rgbseq{rgbkey(0, rgb(255, 255, 255)), rgbkey(1, rgb(66, 66, 66))}
                    });

                    items[ "input" ] = library:create( "TextBox" , {
                        FontFace = fonts.small;
                        AnchorPoint = vec2(1, 1);
                        Text = "";
                        Parent = items[ "colorpicker_components" ];
                        Name = "\0";
                        TextTruncate = Enum.TextTruncate.AtEnd;
                        BorderSizePixel = 0;
                        PlaceholderColor3 = rgb(255, 255, 255);
                        CursorPosition = -1;
                        ClearTextOnFocus = false;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255);
                        TextColor3 = rgb(72, 72, 72);
                        BorderColor3 = rgb(0, 0, 0);
                        Position = dim2(1, -8, 1, -11);
                        Size = dim2(1, -16, 0, 18);
                        BackgroundColor3 = rgb(33, 33, 35)
                    }); 
                    
                    library:create( "UICorner" , {
                        Parent = items[ "input" ];
                        CornerRadius = dim(0, 3)
                    });
                    
                    items[ "UICorenr" ] = library:create( "UICorner" , { -- fire misstypo (im not fixing this RAWR)
                        Parent = items[ "colorpicker_holder" ];
                        Name = "\0";
                        CornerRadius = dim(0, 4)
                    });
                --                  
            end;

            function cfg.set_visible(bool)
                items[ "colorpicker_fade" ].BackgroundTransparency = 0
                items[ "colorpicker_holder" ].Parent = bool and library[ "items" ] or library[ "other" ]
                items[ "colorpicker_holder" ].Position = library:below(items[ "colorpicker" ], -14)

                library:tween(items[ "colorpicker_fade" ], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.4)
                library:tween(items[ "colorpicker_holder" ], {Position = library:below(items[ "colorpicker" ], 6)})
                
                if not (self.sanity and library.current_open == self and self.open) then 
                    library:close_element(cfg)
                end
            end

            function cfg.set(color, alpha)
                if type(color) == "boolean" then 
                    return
                end 

                if color then 
                    h, s, v = color:ToHSV()
                end
                
                if alpha then 
                    a = alpha
                end 
                
                local Color = hsv(h, s, v)

                -- Ok so quick story, should I cache any of this? no...?? anyways I know this code is very bad but its your fault for buying a ui with animations (on a serious note im too lazy to make this look nice)
                -- Also further note, yeah I kind of did this scale_factor * size-valuesize.plane because then I would have to do tomfoolery to make it clip properly.
                library:tween(items[ "hue_picker" ], {Position = dim2(0, (items[ "hue_gradient" ].AbsoluteSize.X - items[ "hue_picker" ].AbsoluteSize.X) * h, 0.5, 0)}, Enum.EasingStyle.Linear, 0.05)
                library:tween(items[ "alpha_picker" ], {Position = dim2(0, (items[ "alpha_gradient" ].AbsoluteSize.X - items[ "alpha_picker" ].AbsoluteSize.X) * (1 - a), 0.5, 0)}, Enum.EasingStyle.Linear, 0.05)
                library:tween(items[ "satvalpicker" ], {Position = dim2(0, s * (items[ "saturation_holder" ].AbsoluteSize.X - items[ "satvalpicker" ].AbsoluteSize.X), 1, 1 - v * (items[ "saturation_holder" ].AbsoluteSize.Y - items[ "satvalpicker" ].AbsoluteSize.Y))}, Enum.EasingStyle.Linear, 0.05)

                items[ "alpha_indicator" ]:FindFirstChildOfClass("UIGradient").Color = rgbseq{rgbkey(0, rgb(112, 112, 112)), rgbkey(1, hsv(h, 1, 1))}; -- shit code
                
                items[ "colorpicker" ].BackgroundColor3 = Color
                items[ "colorpicker_inline" ].BackgroundColor3 = Color
                items[ "saturation_holder" ].BackgroundColor3 = hsv(h, 1, 1)

                items[ "hue_picker" ].BackgroundColor3 = hsv(h, 1, 1)
                items[ "alpha_picker" ].BackgroundColor3 = hsv(h, 1, 1 - a)
                items[ "satvalpicker" ].BackgroundColor3 = hsv(h, s, v)

                flags[cfg.flag] = {
                    Color = Color;
                    Transparency = a 
                }
                
                local color = items[ "colorpicker" ].BackgroundColor3
                items[ "input" ].Text = string.format("%s, %s, %s, ", library:round(color.R * 255), library:round(color.G * 255), library:round(color.B * 255))
                items[ "input" ].Text ..= library:round(1 - a, 0.01)
                
                cfg.callback(Color, a)
            end
            
            function cfg.update_color() 
                local mouse = uis:GetMouseLocation() 
                local offset = vec2(mouse.X, mouse.Y - gui_offset) 

                if dragging_sat then	
                    s = math.clamp((offset - items["sat"].AbsolutePosition).X / items["sat"].AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((offset - items["sat"].AbsolutePosition).Y / items["sat"].AbsoluteSize.Y, 0, 1)
                elseif dragging_hue then
                    h = math.clamp((offset - items[ "hue_gradient" ].AbsolutePosition).X / items[ "hue_gradient" ].AbsoluteSize.X, 0, 1)
                elseif dragging_alpha then
                    a = 1 - math.clamp((offset - items[ "alpha_gradient" ].AbsolutePosition).X / items[ "alpha_gradient" ].AbsoluteSize.X, 0, 1)
                end

                cfg.set()
            end

            items[ "colorpicker" ].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open 

                cfg.set_visible(cfg.open)            
            end)

            library:connection(uis.InputChanged, function(input)
                if (dragging_sat or dragging_hue or dragging_alpha) and is_move(input) then
                    cfg.update_color() 
                end
            end)

            library:connection(uis.InputEnded, function(input)
                if is_press(input) then
                    dragging_sat = false
                    dragging_hue = false
                    dragging_alpha = false
                end
            end)    

            items[ "alpha_gradient" ].MouseButton1Down:Connect(function()
                dragging_alpha = true 
            end)
            
            items[ "hue_gradient" ].MouseButton1Down:Connect(function()
                dragging_hue = true 
            end)
            
            items[ "sat" ].MouseButton1Down:Connect(function()
                dragging_sat = true  
            end)

            items[ "input" ].FocusLost:Connect(function()
                local text = items[ "input" ].Text
                local r, g, b, a = library:convert(text)
                
                if r and g and b and a then 
                    cfg.set(rgb(r, g, b), 1 - a)
                end 
            end)

            items[ "input" ].Focused:Connect(function()
                library:tween(items[ "input" ], {TextColor3 = rgb(245, 245, 245)})
            end)

            items[ "input" ].FocusLost:Connect(function()
                library:tween(items[ "input" ], {TextColor3 = rgb(72, 72, 72)})
            end)
            
            cfg.set(cfg.color, cfg.alpha)
            config_flags[cfg.flag] = cfg.set

            return setmetatable(cfg, library)
        end 

        function library:textbox(options) 
            local cfg = {
                name = options.name or "TextBox",
                placeholder = options.placeholder or options.placeholdertext or options.holder or options.holdertext or "type here...",
                default = options.default or "",
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                visible = options.visible or true,
                items = {};
            }

            flags[cfg.flag] = cfg.default

            local items = cfg.items; do 
                items[ "textbox" ] = library:create( "TextButton" , {
                    LayoutOrder = -1;
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "textbox" ];
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 16;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIPadding" , {
                    Parent = items[ "name" ];
                    PaddingRight = dim(0, 5);
                    PaddingLeft = dim(0, 5)
                });
                
                items[ "right_components" ] = library:create( "Frame" , {
                    Parent = items[ "textbox" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 4, 0, 19);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, 0, 0, 12);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    Parent = items[ "right_components" ];
                    Padding = dim(0, 7);
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    FillDirection = Enum.FillDirection.Horizontal
                });
                
                items[ "input" ] = library:create( "TextBox" , {
                    FontFace = fonts.small;
                    Text = "";
                    PlaceholderText = cfg.placeholder;
                    Parent = items[ "right_components" ];
                    Name = "\0";
                    TextTruncate = Enum.TextTruncate.AtEnd;
                    BorderSizePixel = 0;
                    PlaceholderColor3 = rgb(100, 100, 104);
                    CursorPosition = -1;
                    ClearTextOnFocus = false;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255);
                    TextColor3 = rgb(72, 72, 72);
                    BorderColor3 = rgb(0, 0, 0);
                    Position = dim2(1, 0, 0, 0);
                    Size = dim2(1, -4, 0, 30);
                    BackgroundColor3 = rgb(33, 33, 35)
                }); 

                library:create( "UICorner" , {
                    Parent = items[ "input" ];
                    CornerRadius = dim(0, 3)
                });                
                
                library:create( "UIPadding" , {
                    Parent = items[ "right_components" ];
                    PaddingTop = dim(0, 4);
                    PaddingRight = dim(0, 4)
                });
            end 
            
            function cfg.set(text) 
                flags[cfg.flag] = text

                items[ "input" ].Text = text

                cfg.callback(text)
            end 
            
            items[ "input" ]:GetPropertyChangedSignal("Text"):Connect(function()
                cfg.set(items[ "input" ].Text) 
            end)

            items[ "input" ].Focused:Connect(function()
                library:tween(items[ "input" ], {TextColor3 = rgb(245, 245, 245)})
            end)

            items[ "input" ].FocusLost:Connect(function()
                library:tween(items[ "input" ], {TextColor3 = rgb(72, 72, 72)})
            end)
                
            if cfg.default then 
                cfg.set(cfg.default) 
            end

            config_flags[cfg.flag] = cfg.set

            library:searchable(self, cfg.name, items[ "textbox" ])
            return setmetatable(cfg, library)
        end

        function library:keybind(options) 
            local cfg = {
                flag = options.flag or library:next_flag(),
                callback = options.callback or function() end,
                name = options.name or nil, 
                ignore_key = options.ignore or false, 

                key = options.key or nil, 
                mode = options.mode or "Toggle",
                active = options.default or false, 

                open = false,
                binding = nil, 

                hold_instances = {},
                items = {};
            }

            flags[cfg.flag] = {
                mode = cfg.mode,
                key = cfg.key, 
                active = cfg.active
            }

            local items = cfg.items; do 
                -- Component
                    items[ "keybind_element" ] = library:create( "TextButton" , {
                        FontFace = fonts.font;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = self.items[ "elements" ];
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.Y;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    items[ "name" ] = library:create( "TextLabel" , {
                        FontFace = fonts.font;
                        TextColor3 = rgb(245, 245, 245);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = cfg.name;
                        Parent = items[ "keybind_element" ];
                        Name = "\0";
                        Size = dim2(1, 0, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 16;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIPadding" , {
                        Parent = items[ "name" ];
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });
                    
                    items[ "right_components" ] = library:create( "Frame" , {
                        Parent = items[ "keybind_element" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Size = dim2(0, 0, 1, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIListLayout" , {
                        FillDirection = Enum.FillDirection.Horizontal;
                        HorizontalAlignment = Enum.HorizontalAlignment.Right;
                        Parent = items[ "right_components" ];
                        Padding = dim(0, 7);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                    
                    items[ "keybind_holder" ] = library:create( "TextButton" , {
                        FontFace = fonts.font;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        Parent = items[ "right_components" ];
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Size = dim2(0, 0, 0, 16);
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.X;
                        TextSize = 14;
                        BackgroundColor3 = rgb(33, 33, 35)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "keybind_holder" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    items[ "key" ] = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(86, 86, 87);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "NONE";
                        Parent = items[ "keybind_holder" ];
                        Name = "\0";
                        Size = dim2(1, -12, 0, 0);
                        BackgroundTransparency = 1;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UIPadding" , {
                        Parent = items[ "key" ];
                        PaddingTop = dim(0, 1);
                        PaddingRight = dim(0, 5);
                        PaddingLeft = dim(0, 5)
                    });                                  
                -- 
                
                -- Mode Holder
                    items[ "dropdown" ] = library:create( "Frame" , {
                        BorderColor3 = rgb(0, 0, 0);
                        Parent = library.items;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Position = dim2(0, 0, 0, 0);
                        Size = dim2(0, 0, 0, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.X;
                        BackgroundColor3 = rgb(0, 0, 0)
                    });
                    
                    items[ "inline" ] = library:create( "Frame" , {
                        Parent = items[ "dropdown" ];
                        Size = dim2(1, 0, 1, 0);
                        Name = "\0";
                        ClipsDescendants = true;
                        BorderColor3 = rgb(0, 0, 0);
                        BorderSizePixel = 0;
                        BackgroundColor3 = rgb(22, 22, 24)
                    });
                    
                    library:create( "UIPadding" , {
                        PaddingBottom = dim(0, 6);
                        PaddingTop = dim(0, 3);
                        PaddingLeft = dim(0, 3);
                        Parent = items[ "inline" ]
                    });
                    
                    library:create( "UIListLayout" , {
                        Parent = items[ "inline" ];
                        Padding = dim(0, 5);
                        SortOrder = Enum.SortOrder.LayoutOrder
                    });
                    
                    library:create( "UICorner" , {
                        Parent = items[ "inline" ];
                        CornerRadius = dim(0, 4)
                    });
                    
                    local options = {"Hold", "Toggle", "Always"}
                    
                    cfg.y_size = 20
                    for _, option in options do                        
                        local name = library:create( "TextButton" , {
                            FontFace = fonts.small;
                            TextColor3 = rgb(72, 72, 73);
                            BorderColor3 = rgb(0, 0, 0);
                            Text = option;
                            Parent = items[ "inline" ];
                            Name = "\0";
                            Size = dim2(0, 0, 0, 0);
                            BackgroundTransparency = 1;
                            TextXAlignment = Enum.TextXAlignment.Left;
                            BorderSizePixel = 0;
                            AutomaticSize = Enum.AutomaticSize.XY;
                            TextSize = 14;
                            BackgroundColor3 = rgb(255, 255, 255)
                        }); cfg.hold_instances[option] = name
                        library:apply_theme(name, "accent", "TextColor3")
                        
                        cfg.y_size += name.AbsoluteSize.Y

                        library:create( "UIPadding" , {
                            Parent = name;
                            PaddingTop = dim(0, 1);
                            PaddingRight = dim(0, 5);
                            PaddingLeft = dim(0, 5)
                        });

                        name.MouseButton1Click:Connect(function()
                            cfg.set(option)

                            cfg.set_visible(false)

                            cfg.open = false
                        end)
                    end
                -- 
            end 
            
            function cfg.modify_mode_color(path) -- ts so frikin tuff 💀
                for _, v in cfg.hold_instances do 
                    v.TextColor3 = rgb(72, 72, 72)
                end 

                cfg.hold_instances[path].TextColor3 = themes.preset.accent
            end

            function cfg.set_mode(mode) 
                cfg.mode = mode 

                if mode == "Always" then
                    cfg.set(true)
                elseif mode == "Hold" then
                    cfg.set(false)
                end

                flags[cfg.flag]["mode"] = mode
                cfg.modify_mode_color(mode)
            end 

            function cfg.set(input)
                if type(input) == "boolean" then 
                    cfg.active = input

                    if cfg.mode == "Always" then 
                        cfg.active = true
                    end
                elseif tostring(input):find("Enum") then 
                    input = input.Name == "Escape" and "NONE" or input
                    
                    cfg.key = input or "NONE"	
                elseif find({"Toggle", "Hold", "Always"}, input) then 
                    if input == "Always" then 
                        cfg.active = true 
                    end 

                    cfg.mode = input
                    cfg.set_mode(cfg.mode) 
                elseif type(input) == "table" then 
                    input.key = type(input.key) == "string" and input.key ~= "NONE" and library:convert_enum(input.key) or input.key
                    input.key = input.key == Enum.KeyCode.Escape and "NONE" or input.key

                    cfg.key = input.key or "NONE"
                    cfg.mode = input.mode or "Toggle"

                    if input.active then
                        cfg.active = input.active
                    end

                    cfg.set_mode(cfg.mode) 
                end 

                cfg.callback(cfg.active)

                local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
                local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
                
                items[ "key" ].Text = __text

                flags[cfg.flag] = {
                    mode = cfg.mode,
                    key = cfg.key, 
                    active = cfg.active
                }
            end

            function cfg.set_visible(bool)
                local size = bool and cfg.y_size or 0
                library:tween(items[ "dropdown" ], {Size = dim_offset(items[ "keybind_holder" ].AbsoluteSize.X, size)})

                items[ "dropdown" ].Position = library:below(items[ "keybind_holder" ], 3)
            end
        
            items[ "keybind_holder" ].MouseButton1Down:Connect(function()
                task.wait()
                items[ "key" ].Text = "..."	

                cfg.binding = library:connection(uis.InputBegan, function(keycode, game_event)  
                    cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
                    
                    cfg.binding:Disconnect() 
                    cfg.binding = nil
                end)
            end)

            items[ "keybind_holder" ].MouseButton2Down:Connect(function()
                cfg.open = not cfg.open 

                cfg.set_visible(cfg.open)
            end)

            library:connection(uis.InputBegan, function(input, game_event) 
                if not game_event then
                    local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

                    if selected_key == cfg.key then 
                        if cfg.mode == "Toggle" then 
                            cfg.active = not cfg.active
                            cfg.set(cfg.active)
                        elseif cfg.mode == "Hold" then 
                            cfg.set(true)
                        end
                    end
                end
            end)    

            library:connection(uis.InputEnded, function(input, game_event) 
                if game_event then 
                    return 
                end 

                local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
    
                if selected_key == cfg.key then
                    if cfg.mode == "Hold" then 
                        cfg.set(false)
                    end
                end
            end)
            
            cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})           
            config_flags[cfg.flag] = cfg.set

            library:searchable(self, cfg.name, items[ "keybind_element" ])
            return setmetatable(cfg, library)
        end

        function library:button(options) 
            local cfg = {
                name = options.name or "TextBox",
                callback = options.callback or function() end,
                items = {};
            }
            
            local items = cfg.items; do 
                items[ "button_element" ] = library:create( "Frame" , {
                    Parent = self.items[ "elements" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                items[ "button" ] = library:create( "TextButton" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = "";
                    AutoButtonColor = false;
                    AnchorPoint = vec2(1, 0);
                    Parent = items[ "button_element" ];
                    Name = "\0";
                    Position = dim2(1, -4, 0, 0);
                    Size = dim2(1, -8, 0, 30);
                    BorderSizePixel = 0;
                    TextSize = 14;
                    BackgroundColor3 = rgb(33, 33, 35)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "button" ];
                    CornerRadius = dim(0, 3)
                });
                
                items[ "name" ] = library:create( "TextLabel" , {
                    FontFace = fonts.font;
                    TextColor3 = rgb(245, 245, 245);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "button" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Size = dim2(1, 0, 1, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                }); library:apply_theme(items[ "name" ], "accent", "BackgroundColor3");                            
            end 

            items[ "button" ].MouseButton1Click:Connect(function()
                cfg.callback()

                items[ "name" ].TextColor3 = themes.preset.accent 
                library:tween(items[ "name" ], {TextColor3 = rgb(245, 245, 245)})
            end)
            
            library:searchable(self, cfg.name, items[ "button_element" ])
            return setmetatable(cfg, library)
        end 

        function library:settings(options)  
            local cfg = {
                open = false; 
                items = {}; 
                sanity = true; -- made this for my own sanity.
            }

            local items = cfg.items; do 
                items[ "outline" ] = library:create( "Frame" , {
                    Name = "\0";
                    Visible = true;
                    Parent = library[ "items" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 0, 0);
                    ClipsDescendants = true;
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(25, 25, 29)
                });
                
                items[ "inline" ] = library:create( "Frame" , {
                    Parent = items[ "outline" ];
                    Name = "\0";
                    Position = dim2(0, 1, 0, 1);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(1, -2, 1, -2);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(22, 22, 24)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "inline" ];
                    CornerRadius = dim(0, 7)
                });
                
                items[ "elements" ] = library:create( "Frame" , {
                    BorderColor3 = rgb(0, 0, 0);
                    Parent = items[ "inline" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 10, 0, 10);
                    Size = dim2(1, -20, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    Parent = items[ "elements" ];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                
                library:create( "UIPadding" , {
                    PaddingBottom = dim(0, 15);
                    Parent = items[ "elements" ]
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "outline" ];
                    CornerRadius = dim(0, 7)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "fade" ];
                    CornerRadius = dim(0, 7)
                });
                
                items[ "tick" ] = library:create( "ImageButton" , {
                    Image = "rbxassetid://128797200442698";
                    Name = "\0";
                    AutoButtonColor = false;
                    Parent = self.items[ "right_components" ];
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 16, 0, 16);
                    BorderSizePixel = 0;
                    BackgroundColor3 = rgb(255, 255, 255)
                });                
            end 

            function cfg.set_visible(bool)                 
                library:tween(items[ "outline" ], {Size = dim_offset(bool and 240 or 0, 0)})
                items[ "outline" ].Position = library:below(items[ "tick" ], 4)
                library:close_element(cfg)
            end
            
            items[ "tick" ].MouseButton1Click:Connect(function()
                cfg.open = not cfg.open

                cfg.set_visible(cfg.open)
            end)

            return setmetatable(cfg, library)
        end 

        function library:list(properties) 
            local cfg = {
                items = {};
                options = properties.options or {"1", "2", "3"};
                flag = properties.flag or library:next_flag();    
                callback = properties.callback or function() end;
                data_store = {};        
                current_element;
            }

            local items = cfg.items; do
                items[ "list" ] = library:create( "Frame" , {
                    Parent = self.items[ "elements" ];
                    BackgroundTransparency = 1;
                    Name = "\0";
                    Size = dim2(1, 0, 0, 0);
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIListLayout" , {
                    Parent = items[ "list" ];
                    Padding = dim(0, 10);
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                
                library:create( "UIPadding" , {
                    Parent = items[ "list" ];
                    PaddingRight = dim(0, 4);
                    PaddingLeft = dim(0, 4)
                });
            end 

            function cfg.refresh_options(options_to_refresh) -- ignore goofy parameter
                for _,option in cfg.data_store do 
                    option:Destroy()
                end

                for _, option_data in options_to_refresh do -- haha u skids no next >_<
                    local button = library:create( "TextButton" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(0, 0, 0);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = "";
                        AutoButtonColor = false;
                        AnchorPoint = vec2(1, 0);
                        Parent = items[ "list" ];
                        Name = "\0";
                        Position = dim2(1, 0, 0, 0);
                        Size = dim2(1, 0, 0, 30);
                        BorderSizePixel = 0;
                        TextSize = 14;
                        BackgroundColor3 = rgb(33, 33, 35)
                    }); cfg.data_store[#cfg.data_store + 1] = button;

                    local name = library:create( "TextLabel" , {
                        FontFace = fonts.small;
                        TextColor3 = rgb(72, 72, 73);
                        BorderColor3 = rgb(0, 0, 0);
                        Text = option_data;
                        Parent = button;
                        Name = "\0";
                        BackgroundTransparency = 1;
                        Size = dim2(1, 0, 1, 0);
                        BorderSizePixel = 0;
                        AutomaticSize = Enum.AutomaticSize.XY;
                        TextSize = 14;
                        BackgroundColor3 = rgb(255, 255, 255)
                    });
                    
                    library:create( "UICorner" , {
                        Parent = button;
                        CornerRadius = dim(0, 3)
                    });     

                    button.MouseButton1Click:Connect(function()
                        local current = cfg.current_element 
                        if current and current ~= name then 
                            library:tween(current, {TextColor3 = rgb(72, 72, 72)})
                        end

                        flags[cfg.flag] = option_data
                        cfg.callback(option_data)
                        library:tween(name, {TextColor3 = rgb(245, 245, 245)})
                        cfg.current_element = name
                    end)

                    name.MouseEnter:Connect(function()
                        if cfg.current_element == name then 
                            return 
                        end 

                        library:tween(name, {TextColor3 = rgb(140, 140, 140)})
                    end)

                    name.MouseLeave:Connect(function()
                        if cfg.current_element == name then 
                            return 
                        end 

                        library:tween(name, {TextColor3 = rgb(72, 72, 72)})
                    end)
                end
            end

            cfg.refresh_options(cfg.options)

            return setmetatable(cfg, library)
        end 

        -- interface prefs (theme / language / scale / mobile button) survive re-executes
        local interface_file = library.directory .. "/interface.json"

        function library:load_interface()
            local ok, data = pcall(function() return http_service:JSONDecode(readfile(interface_file)) end)
            return ok and type(data) == "table" and data or {}
        end

        function library:save_interface(data)
            pcall(writefile, interface_file, http_service:JSONEncode(data))
        end

        function library:init_config(window) 
            local prefs = library:load_interface()
            local function remember(key, value)
                prefs[key] = value
                library:save_interface(prefs)
            end

            -- apply saved look before building the settings page (so its own elements come out themed)
            if prefs.theme and theme_presets[prefs.theme] then library:set_theme(prefs.theme) end
            if prefs.language and languages[prefs.language] then library:set_language(prefs.language) end
            if type(prefs.scale) == "number" and window.set_scale then window.set_scale(prefs.scale) end
            if type(prefs.mobile_button) == "boolean" and window.set_mobile_button then window.set_mobile_button(prefs.mobile_button) end

            window:seperator({name = "Settings"})
            local main = window:tab({name = "Configs", tabs = {"Main"}, icon = "rbxassetid://139628202576511"})
            
            local column = main:column({})
            local section = column:section({name = "Configs", size = 1, default = true, icon = "rbxassetid://139628202576511"})
            config_holder = section:list({options = {}, callback = function(option) end, flag = "config_name_list"}); library:update_config_list()

            local function config_name()
                local typed = flags["config_name_text"]
                if type(typed) == "string" and typed ~= "" then return typed end
                return flags["config_name_list"]
            end

            local function config_path(name)
                return library.directory .. "/configs/" .. tostring(name) .. ".cfg"
            end
            
            local column = main:column({})
            local section = column:section({name = "Settings", side = "right", size = 1, default = true, icon = "rbxassetid://129380150574313"})
            section:textbox({name = "Config name:", flag = "config_name_text"})
            section:button({name = "Save", callback = function()
                local name = config_name()
                if not name then return end
                writefile(config_path(name), library:get_config())
                library:update_config_list()
                notifications:create_notification({name = translate("Configs"), info = translate("Saved config to:") .. "\n" .. name})
            end}) 
            section:button({name = "Load", callback = function()
                local name = flags["config_name_list"]
                if not (name and isfile(config_path(name))) then return end
                library:load_config(readfile(config_path(name)))
                library:update_config_list()
                notifications:create_notification({name = translate("Configs"), info = translate("Loaded config:") .. "\n" .. name})
            end})
            section:button({name = "Delete", callback = function()
                local name = flags["config_name_list"]
                if not (name and isfile(config_path(name))) then return end
                delfile(config_path(name))
                library:update_config_list()
                notifications:create_notification({name = translate("Configs"), info = translate("Deleted config:") .. "\n" .. name})
            end})
            section:button({name = "Refresh", callback = function() library:update_config_list() end})

            -- Interface
            local ui = window:tab({name = "Interface", tabs = {"Main"}, icon = "rbxassetid://129380150574313"})
            local column = ui:column({})
            local section = column:section({name = "Interface", size = 1, default = true, icon = "rbxassetid://129380150574313"})

            section:dropdown({name = "Theme", flag = "ui_theme", items = theme_order, default = themes.current_name, search = false, callback = function(name)
                if type(name) ~= "string" or name == themes.current_name then return end
                library:set_theme(name)
                remember("theme", name)
            end})

            local language_names = { en = "English", th = "ภาษาไทย" }
            local language_items, language_by_name = {}, {}
            for code in languages do
                local label = language_names[code] or code
                insert(language_items, label)
                language_by_name[label] = code
            end
            table.sort(language_items)

            section:dropdown({name = "Language", flag = "ui_language", items = language_items, default = language_names[library.language] or library.language, search = false, callback = function(label)
                local code = language_by_name[label]
                if not code or code == library.language then return end
                library:set_language(code)
                remember("language", code)
            end})

            section:slider({name = "UI Scale", flag = "ui_scale", min = 50, max = 150, default = floor((prefs.scale or 1) * 100), interval = 5, suffix = "%", callback = function(value)
                if window.set_scale then window.set_scale(value / 100) end
                if value / 100 ~= prefs.scale then remember("scale", value / 100) end
            end})

            section:toggle({name = "Mobile Button", flag = "ui_mobile_button", default = window.items and window.items[ "mobile_button" ] and window.items[ "mobile_button" ].Visible or false, callback = function(bool)
                if window.set_mobile_button then window.set_mobile_button(bool) end
                if prefs.mobile_button ~= bool then remember("mobile_button", bool) end
            end})

            section:colorpicker({name = "Menu Accent", callback = function(color, alpha) library:update_theme("accent", color) end, color = themes.preset.accent})
            section:keybind({name = "Menu Bind", key = Enum.KeyCode.RightShift, callback = function(bool) window.toggle_menu(bool) end, default = true})
        end
    --

    -- Notification Library
        function notifications:refresh_notifs() 
            local offset = 50

            for i, v in notifications.notifs do
                local Position = vec2(20, offset)
                library:tween(v, {Position = dim_offset(Position.X, Position.Y)}, Enum.EasingStyle.Quad, 0.4)
                offset += (v.AbsoluteSize.Y + 10)
            end

            return offset
        end
        
        function notifications:fade(path, is_fading)
            local fading = is_fading and 1 or 0 
            
            library:tween(path, {BackgroundTransparency = fading}, Enum.EasingStyle.Quad, 1)

            for _, instance in path:GetDescendants() do 
                if not instance:IsA("GuiObject") then 
                    if instance:IsA("UIStroke") then
                        library:tween(instance, {Transparency = fading}, Enum.EasingStyle.Quad, 1)
                    end
        
                    continue
                end 
        
                if instance:IsA("TextLabel") then
                    library:tween(instance, {TextTransparency = fading})
                elseif instance:IsA("Frame") then
                    library:tween(instance, {BackgroundTransparency = instance.Transparency and 0.6 and is_fading and 1 or 0.6}, Enum.EasingStyle.Quad, 1)
                end
            end
        end 
        
        function notifications:create_notification(options)
            local cfg = {
                name = options.name or "This is a title!";
                info = options.info or "This is extra info!";
                lifetime = options.lifetime or 3;
                items = {};
                outline;
            }

            local items = cfg.items; do 
                items[ "notification" ] = library:create( "Frame" , {
                    Parent = library[ "items" ];
                    Size = dim2(0, 210, 0, 53);
                    Name = "\0";
                    BorderColor3 = rgb(0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    AnchorPoint = vec2(1, 0);
                    AutomaticSize = Enum.AutomaticSize.Y;
                    BackgroundColor3 = rgb(14, 14, 16)
                });
                
                library:create( "UIStroke" , {
                    Color = rgb(23, 23, 29);
                    Parent = items[ "notification" ];
                    Transparency = 1;
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                });
                
                items[ "title" ] = library:create( "TextLabel" , {
                    FontFace = fonts.bold;
                    TextColor3 = rgb(255, 255, 255);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.name;
                    Parent = items[ "notification" ];
                    Name = "\0";
                    BackgroundTransparency = 1;
                    Position = dim2(0, 7, 0, 6);
                    BorderSizePixel = 0;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "notification" ];
                    CornerRadius = dim(0, 3)
                });
                
                items[ "info" ] = library:create( "TextLabel" , {
                    FontFace = fonts.small;
                    TextColor3 = rgb(145, 145, 145);
                    BorderColor3 = rgb(0, 0, 0);
                    Text = cfg.info;
                    Parent = items[ "notification" ];
                    Name = "\0";
                    Position = dim2(0, 9, 0, 22);
                    BorderSizePixel = 0;
                    BackgroundTransparency = 1;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextWrapped = true;
                    AutomaticSize = Enum.AutomaticSize.XY;
                    TextSize = 14;
                    BackgroundColor3 = rgb(255, 255, 255)
                });
                
                library:create( "UIPadding" , {
                    PaddingBottom = dim(0, 17);
                    PaddingRight = dim(0, 8);
                    Parent = items[ "info" ]
                });
                
                items[ "bar" ] = library:create( "Frame" , {
                    AnchorPoint = vec2(0, 1);
                    Parent = items[ "notification" ];
                    Name = "\0";
                    Position = dim2(0, 8, 1, -6);
                    BorderColor3 = rgb(0, 0, 0);
                    Size = dim2(0, 0, 0, 5);
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    BackgroundColor3 = themes.preset.accent
                });
                
                library:create( "UICorner" , {
                    Parent = items[ "bar" ];
                    CornerRadius = dim(0, 999)
                });
                
                library:create( "UIPadding" , {
                    PaddingRight = dim(0, 8);
                    Parent = items[ "notification" ]
                });
            end
            
            local index = #notifications.notifs + 1
            notifications.notifs[index] = items[ "notification" ]

            notifications:fade(items[ "notification" ], false)
            
            local offset = notifications:refresh_notifs()

            items[ "notification" ].Position = dim_offset(20, offset)

            library:tween(items[ "notification" ], {AnchorPoint = vec2(0, 0)}, Enum.EasingStyle.Quad, 1)
            library:tween(items[ "bar" ], {Size = dim2(1, -8, 0, 5)}, Enum.EasingStyle.Quad, cfg.lifetime)

            task.spawn(function()
                task.wait(cfg.lifetime)
                
                notifications.notifs[index] = nil
                
                notifications:fade(items[ "notification" ], true)
                
                library:tween(items[ "notification" ], {AnchorPoint = vec2(1, 0)}, Enum.EasingStyle.Quad, 1)

                task.wait(1)
        
                items[ "notification" ]:Destroy() 
            end)
        end
    --
-- 

return library