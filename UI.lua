-- cobble hills UI (HUSH CLEAN REWRITE)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Cheat = getgenv().HushCheat
if not Cheat then return end
local Config = Cheat.Config
local LP = Players.LocalPlayer
local CAM = workspace.CurrentCamera
local GETHUI = (gethui and gethui()) or CoreGui

local T = {
    BG = Color3.fromRGB(20, 22, 26), Panel = Color3.fromRGB(26, 28, 34),
    Element = Color3.fromRGB(30, 33, 40), ElementHi = Color3.fromRGB(38, 42, 52),
    Stroke = Color3.fromRGB(38, 42, 52), StrokeHi = Color3.fromRGB(48, 53, 64),
    Accent = Color3.fromRGB(0, 185, 255), Success = Color3.fromRGB(60, 210, 120),
    Warning = Color3.fromRGB(255, 198, 55), Danger = Color3.fromRGB(255, 80, 80),
    Orange = Color3.fromRGB(255, 155, 60), Purple = Color3.fromRGB(160, 90, 255),
    Text = Color3.fromRGB(240, 244, 255), TextDim = Color3.fromRGB(150, 160, 180),
    TextMuted = Color3.fromRGB(90, 100, 120),
}

local function mk(class, props, children)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do inst[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end
local function corner(r, parent) return mk("UICorner", {CornerRadius = UDim.new(0, r), Parent = parent}) end
local function stroke(color, thickness, parent) return mk("UIStroke", {Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent}) end
local function pad(t, r, b, l, parent) r = r or t; b = b or t; l = l or r or t; return mk("UIPadding", {PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), Parent = parent}) end
local function tw(inst, dur, props, style, dir) local t = TweenService:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props); t:Play(); return t end

local UI = {}
UI.__index = UI

local function buildWindow(opts)
    local self = setmetatable({}, UI)
    self._flags = {}; self._elements = {}; self._connections = {}; self._tabs = {}; self._activeTab = nil
    self._minimized = false; self._dragging = false

    local win = mk("Frame", { Name = opts.Title or "Cheat", Size = opts.Size or UDim2.fromOffset(560, 420), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.BG, BorderSizePixel = 0, Active = true, ClipsDescendants = true }, {GETHUI})
    corner(10, win); local winStroke = stroke(T.Stroke, 1, win)
    self.Frame = win

    local header = mk("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Active = true }, {win})
    corner(10, header)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, {header})
    local glow = mk("Frame", { Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 1, -2), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, {header})
    mk("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = glow })
    mk("TextLabel", { Size = UDim2.new(1, -120, 0, 24), Position = UDim2.new(0, 20, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = opts.Title or "Cheat", TextSize = 15, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left }, {header})
    mk("TextLabel", { Size = UDim2.new(1, -120, 0, 14), Position = UDim2.new(0, 20, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Subtitle or "v1.0", TextSize = 10, TextColor3 = T.TextMuted, TextXAlignment = Enum.TextXAlignment.Left }, {header})

    local close = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0, 10), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "×", TextSize = 16, TextColor3 = T.TextDim, AutoButtonColor = false }, {header})
    corner(6, close); local closeStroke = stroke(T.Stroke, 1, close)
    close.MouseEnter:Connect(function() tw(close, 0.1, {BackgroundColor3 = T.Danger, TextColor3 = T.Text}); tw(closeStroke, 0.1, {Color = T.Danger}) end)
    close.MouseLeave:Connect(function() tw(close, 0.1, {BackgroundColor3 = T.Element, TextColor3 = T.TextDim}); tw(closeStroke, 0.1, {Color = T.Stroke}) end)
    close.MouseButton1Click:Connect(function() if self._OnClose then self._OnClose() end end)

    local minimize = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -72, 0, 10), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = "—", TextSize = 14, TextColor3 = T.TextDim, AutoButtonColor = false }, {header})
    corner(6, minimize); local minStroke = stroke(T.Stroke, 1, minimize)
    minimize.MouseEnter:Connect(function() tw(minimize, 0.1, {BackgroundColor3 = T.ElementHi, TextColor3 = T.Text}); tw(minStroke, 0.1, {Color = T.StrokeHi}) end)
    minimize.MouseLeave:Connect(function() tw(minimize, 0.1, {BackgroundColor3 = T.Element, TextColor3 = T.TextDim}); tw(minStroke, 0.1, {Color = T.Stroke}) end)
    minimize.MouseButton1Click:Connect(function() self._minimized = not self._minimized; local newSize = self._minimized and UDim2.new(self.Frame.Size.X.Scale, self.Frame.Size.X.Offset, 0, 48) or (opts.Size or UDim2.fromOffset(560, 420)); tw(self.Frame, 0.2, {Size = newSize}); self._content.Visible = not self._minimized; self._tabBar.Visible = not self._minimized end)

    local tabBar = mk("Frame", { Name = "TabBar", Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, 56), BackgroundColor3 = T.Panel, BorderSizePixel = 0 }, {win})
    corner(8, tabBar); stroke(T.Stroke, 1, tabBar)
    mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Left, SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabBar })
    pad(0, 6, 0, 6, tabBar); self._tabBar = tabBar

    local content = mk("Frame", { Name = "Content", Size = UDim2.new(1, -24, 1, -152), Position = UDim2.new(0, 12, 0, 96), BackgroundTransparency = 1, ClipsDescendants = true }, {win})
    self._content = content

    header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then self._dragging = true; self._dragStart = input.Position; self._winStart = self.Frame.Position end end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) if not self._dragging then return end; if input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - self._dragStart; self.Frame.Position = UDim2.new(self._winStart.X.Scale, self._winStart.X.Offset + delta.X, self._winStart.Y.Scale, self._winStart.Y.Offset + delta.Y) end end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then self._dragging = false end end))

    return self
end

function UI:Tab(name, icon)
    local self_tab = {name = name, elements = {}}
    local tabBtn = mk("TextButton", { Size = UDim2.new(0, 0, 1, -8), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamSemibold, Text = name, TextSize = 11, TextColor3 = T.TextMuted, AutoButtonColor = false }, {self._tabBar})
    corner(6, tabBtn); pad(6, 12, 6, 12, tabBtn); local tabStroke = stroke(T.Stroke, 1, tabBtn)

    local page = mk("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = T.Stroke, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, {self._content})
    mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    pad(0, 4, 0, 4, page)

    table.insert(self._tabs, {button = tabBtn, page = page, name = name})

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(self._tabs) do t.page.Visible = false; tw(t.button, 0.15, {BackgroundColor3 = T.Element, TextColor3 = T.TextMuted}); tw(t.button:FindFirstChildOfClass("UIStroke"), 0.15, {Color = T.Stroke}) end
        page.Visible = true; self._activeTab = name
        tw(tabBtn, 0.15, {BackgroundColor3 = T.ElementHi, TextColor3 = T.Accent}); tw(tabStroke, 0.15, {Color = T.Accent})
    end)
    tabBtn.MouseEnter:Connect(function() if self._activeTab ~= name then tw(tabBtn, 0.1, {BackgroundColor3 = T.ElementHi, TextColor3 = T.TextDim}) end end)
    tabBtn.MouseLeave:Connect(function() if self._activeTab ~= name then tw(tabBtn, 0.1, {BackgroundColor3 = T.Element, TextColor3 = T.TextMuted}) end end)

    local tabObj = setmetatable({_self = self, _page = page, _name = name}, {__index = {
        Section = function(t, title)
            local section = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = #t._page:GetChildren() }, {t._page})
            mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = title:upper(), TextSize = 10, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Left }, {section})
            mk("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Stroke, BorderSizePixel = 0 }, {section})
            
            local sectionObj = setmetatable({_parent = self, _frame = section, _page = t._page}, {__index = nil})
            sectionObj.Toggle = function(s, opts) return self:_makeToggle(s, opts) end
            sectionObj.Slider = function(s, opts) return self:_makeSlider(s, opts) end
            sectionObj.Dropdown = function(s, opts) return self:_makeDropdown(s, opts) end
            sectionObj.Keybind = function(s, opts) return self:_makeKeybind(s, opts) end
            sectionObj.ColorPicker = function(s, opts) return self:_makeColor(s, opts) end
            sectionObj.Button = function(s, opts) return self:_makeButton(s, opts) end
            sectionObj.Label = function(s, text, color) return self:_makeLabel(s, text, color) end
            return sectionObj
        end
    }})

    if #self._tabs == 1 then tabBtn.MouseButton1Click:Connect(function() end); for _, t in ipairs(self._tabs) do t.page.Visible = true end; self._activeTab = name; tw(tabBtn, 0.15, {BackgroundColor3 = T.ElementHi, TextColor3 = T.Accent}); tw(tabStroke, 0.15, {Color = T.Accent}) end
    return tabObj
end

function UI:_makeToggle(section, opts)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Element, BorderSizePixel = 0 }, {section._page}); corner(6, row); stroke(T.Stroke, 1, row); pad(0, 10, 0, 10, row)
    mk("TextLabel", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Name, TextSize = 12, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left }, {row})
    local track = mk("Frame", { Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -38, 0.5, -10), BackgroundColor3 = T.ElementHi, BorderSizePixel = 0 }, {row}); corner(10, track); local trackStroke = stroke(T.Stroke, 1, track)
    local knob = mk("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = T.TextDim, BorderSizePixel = 0 }, {track}); corner(7, knob)
    local hitBtn = mk("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, {row})
    local state = opts.Default or false
    local function render(animated) local dur = animated and 0.15 or 0; if state then tw(track, dur, {BackgroundColor3 = T.Accent}); tw(trackStroke, dur, {Color = T.Accent}); tw(knob, dur, {Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = T.Text}) else tw(track, dur, {BackgroundColor3 = T.ElementHi}); tw(trackStroke, dur, {Color = T.Stroke}); tw(knob, dur, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = T.TextDim}) end end
    render(false)
    hitBtn.MouseButton1Click:Connect(function() state = not state; render(true); if opts.Callback then pcall(opts.Callback, state) end end)
    hitBtn.MouseEnter:Connect(function() tw(row, 0.1, {BackgroundColor3 = T.ElementHi}) end)
    hitBtn.MouseLeave:Connect(function() tw(row, 0.1, {BackgroundColor3 = T.Element}) end)
    return {Get = function() return state end, Set = function(v) state = v; render(true); if opts.Callback then pcall(opts.Callback, state) end end}
end

function UI:_makeSlider(section, opts)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = T.Element, BorderSizePixel = 0 }, {section._page}); corner(6, row); stroke(T.Stroke, 1, row); pad(0, 10, 0, 10, row)
    mk("TextLabel", { Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Name, TextSize = 12, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left }, {row})
    local valLabel = mk("TextLabel", { Size = UDim2.new(0.3, 0, 0, 20), Position = UDim2.new(0.7, -10, 0, 4), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = tostring(opts.Default or opts.Min), TextSize = 12, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right }, {row})
    local trackBg = mk("Frame", { Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 1, -14), BackgroundColor3 = T.Stroke, BorderSizePixel = 0 }, {row}); corner(2, trackBg)
    local range = (opts.Max - opts.Min); local function pct(v) return math.clamp((v - opts.Min) / range, 0, 1) end
    local fill = mk("Frame", { Size = UDim2.new(pct(opts.Default or opts.Min), 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, {trackBg}); corner(2, fill)
    local knob = mk("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(pct(opts.Default or opts.Min), -6, 0.5, -6), BackgroundColor3 = T.Text, BorderSizePixel = 0 }, {trackBg}); corner(6, knob)
    local grab = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, {row})
    local value = opts.Default or opts.Min; local dragging = false; local step = opts.Step or 1
    local function setValue(v, fire) v = math.clamp(v, opts.Min, opts.Max); v = math.floor(v / step + 0.5) * step; v = math.floor(v * 1000 + 0.5) / 1000; value = v; valLabel.Text = tostring(v); local p = pct(v); tw(fill, 0.08, {Size = UDim2.new(p, 0, 1, 0)}); tw(knob, 0.08, {Position = UDim2.new(p, -6, 0.5, -6)}); if fire and opts.Callback then pcall(opts.Callback, v) end end
    grab.MouseButton1Down:Connect(function() dragging = true; local relX = UserInputService:GetMouseLocation().X - trackBg.AbsolutePosition.X; setValue(opts.Min + (relX / trackBg.AbsoluteSize.X) * range, true) end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input) if not dragging then return end; if input.UserInputType == Enum.UserInputType.MouseMovement then local relX = UserInputService:GetMouseLocation().X - trackBg.AbsolutePosition.X; setValue(opts.Min + (relX / trackBg.AbsoluteSize.X) * range, true) end end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
    return {Get = function() return value end, Set = function(v) setValue(v, true) end}
end

function UI:_makeDropdown(section, opts)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5 }, {section._page}); corner(6, row); stroke(T.Stroke, 1, row); pad(0, 10, 0, 10, row)
    mk("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Name, TextSize = 12, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left }, {row})
    local current = opts.Default or opts.Options[1]
    local valueLabel = mk("TextLabel", { Size = UDim2.new(0.55, -20, 1, 0), Position = UDim2.new(0.4, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = tostring(current), TextSize = 12, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right }, {row})
    local arrow = mk("TextLabel", { Size = UDim2.fromOffset(16, 30), Position = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "▼", TextSize = 8, TextColor3 = T.TextMuted }, {row})
    local clickArea = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "" }, {row})
    local optionsFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, #opts.Options * 24), Position = UDim2.new(0, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 6 }, {row})
    mk("UIListLayout", { Padding = UDim.new(0, 2), Parent = optionsFrame })
    for i, option in ipairs(opts.Options) do
        local item = mk("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = "  " .. tostring(option), TextSize = 11, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 7 }, {optionsFrame}); corner(4, item)
        item.MouseEnter:Connect(function() tw(item, 0.1, {BackgroundColor3 = T.ElementHi, TextColor3 = T.Text}) end)
        item.MouseLeave:Connect(function() tw(item, 0.1, {BackgroundColor3 = T.Panel, TextColor3 = T.TextDim}) end)
        item.MouseButton1Click:Connect(function() current = option; valueLabel.Text = tostring(option); row.Size = UDim2.new(1, 0, 0, 30); arrow.Text = "▼"; if opts.Callback then pcall(opts.Callback, option) end end)
    end
    local expanded = false
    clickArea.MouseButton1Click:Connect(function() expanded = not expanded; row.Size = UDim2.new(1, 0, 0, expanded and (34 + #opts.Options * 24) or 30); arrow.Text = expanded and "▲" or "▼"; tw(row, 0.15, {Size = UDim2.new(1, 0, 0, expanded and (34 + #opts.Options * 24) or 30)}) end)
    return {Get = function() return current end, Set = function(v) current = v; valueLabel.Text = tostring(v); if opts.Callback then pcall(opts.Callback, v) end end}
end

function UI:_makeKeybind(section, opts)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BorderSizePixel = 0 }, {section._page}); corner(6, row); stroke(T.Stroke, 1, row); pad(0, 10, 0, 10, row)
    mk("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Name, TextSize = 12, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left }, {row})
    local keyValue = opts.Default or Enum.KeyCode.Unknown; local labelText = keyValue ~= Enum.KeyCode.Unknown and tostring(keyValue.Name) or "[Nenhum]"
    local btn = mk("TextButton", { Size = UDim2.new(0.35, 0, 0, 22), Position = UDim2.new(0.65, 0, 0.5, -11), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamSemibold, Text = labelText, TextSize = 11, TextColor3 = T.Accent, AutoButtonColor = false }, {row}); corner(4, btn); local btnStroke = stroke(T.Stroke, 1, btn)
    local capturing = false
    btn.MouseButton1Click:Connect(function() if capturing then return end; capturing = true; btn.Text = "[...]"; btn.TextColor3 = T.Warning; tw(btnStroke, 0.1, {Color = T.Warning}); table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end; if input.UserInputType == Enum.UserInputType.Keyboard then keyValue = input.KeyCode else return end; capturing = false; btn.Text = tostring(keyValue.Name); btn.TextColor3 = T.Accent; tw(btnStroke, 0.1, {Color = T.Stroke}); if opts.Callback then pcall(opts.Callback, keyValue) end end)) end)
    return {Get = function() return keyValue end, Set = function(v) keyValue = v; btn.Text = tostring(v.Name) end}
end

function UI:_makeColor(section, opts)
    local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BorderSizePixel = 0 }, {section._page}); corner(6, row); stroke(T.Stroke, 1, row); pad(0, 10, 0, 10, row)
    mk("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opts.Name, TextSize = 12, TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left }, {row})
    local current = opts.Default or T.Accent
    local btn = mk("TextButton", { Size = UDim2.new(0.35, 0, 0, 22), Position = UDim2.new(0.65, 0, 0.5, -11), BackgroundColor3 = current, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, {row}); corner(4, btn); stroke(T.Stroke, 1, btn)
    return {Get = function() return current end, Set = function(c) current = c; btn.BackgroundColor3 = c; if opts.Callback then pcall(opts.Callback, c) end end}
end

function UI:_makeButton(section, opts)
    local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BorderSizePixel = 0, Font = Enum.Font.GothamSemibold, Text = opts.Name, TextSize = 12, TextColor3 = T.Text, AutoButtonColor = false }, {section._page}); corner(6, btn); local st = stroke(T.Stroke, 1, btn)
    btn.MouseEnter:Connect(function() tw(btn, 0.1, {BackgroundColor3 = T.ElementHi}); tw(st, 0.1, {Color = T.Accent}) end)
    btn.MouseLeave:Connect(function() tw(btn, 0.1, {BackgroundColor3 = T.Element}); tw(st, 0.1, {Color = T.Stroke}) end)
    btn.MouseButton1Click:Connect(function() if opts.Callback then pcall(opts.Callback) end end)
    return btn
end

function UI:_makeLabel(section, text, color)
    return mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = text, TextSize = 11, TextColor3 = color or T.TextMuted, TextXAlignment = Enum.TextXAlignment.Left }, {section._page})
end

function UI:Destroy() for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end; if self.Frame then self.Frame:Destroy() end end

--== INICIALIZAÇÃO DA JANELA ==--
local Window = buildWindow({ Title = "HUSH Client", Subtitle = "v1.0", Size = UDim2.fromOffset(560, 420) })
getgenv().Cobble_UI_Loaded = Window
Window._OnClose = function() Window.Frame.Visible = false end

--== ABA AIMBOT ==--
local aimTab = Window:Tab("Aimbot")
local aimSec = aimTab:Section("Aiming")
aimSec:Toggle({ Name = "Enable Aimbot", Default = Config.Aim.Enabled, Callback = function(v) Config.Aim.Enabled = v end })
aimSec:Keybind({ Name = "Activation Key", Default = Config.Aim.Key, Callback = function(k) Config.Aim.Key = k end })
aimSec:Slider({ Name = "FOV Radius", Min = 50, Max = 500, Default = Config.Aim.FOV, Step = 10, Callback = function(v) Config.Aim.FOV = v end })
aimSec:Slider({ Name = "Smoothness", Min = 1, Max = 30, Default = Config.Aim.Smooth, Step = 1, Callback = function(v) Config.Aim.Smooth = v end })
aimSec:Dropdown({ Name = "Aim Part", Options = {"Head", "Torso"}, Default = Config.Aim.AimPart, Callback = function(v) Config.Aim.AimPart = v end })
local predSec = aimTab:Section("Prediction")
predSec:Toggle({ Name = "Enable Prediction", Default = Config.Aim.Predict, Callback = function(v) Config.Aim.Predict = v end })
predSec:Slider({ Name = "Prediction Scale", Min = 0.1, Max = 2.5, Default = Config.Aim.PredictScale, Step = 0.1, Callback = function(v) Config.Aim.PredictScale = v end })
predSec:Toggle({ Name = "Ping Compensation", Default = Config.Aim.PingComp, Callback = function(v) Config.Aim.PingComp = v end })
predSec:Toggle({ Name = "Gravity Compensation", Default = Config.Aim.GravityComp, Callback = function(v) Config.Aim.GravityComp = v end })
local filterSec = aimTab:Section("Filters")
filterSec:Toggle({ Name = "Visible Only", Default = Config.Aim.VisibleOnly, Callback = function(v) Config.Aim.VisibleOnly = v end })
filterSec:Toggle({ Name = "Team Check", Default = Config.Aim.TeamCheck, Callback = function(v) Config.Aim.TeamCheck = v end })
local trigSec = aimTab:Section("Triggerbot")
trigSec:Toggle({ Name = "Enable Triggerbot", Default = Config.Aim.Trigger, Callback = function(v) Config.Aim.Trigger = v end })
trigSec:Slider({ Name = "Trigger Delay (ms)", Min = 0, Max = 300, Default = Config.Aim.TriggerDelay, Step = 10, Callback = function(v) Config.Aim.TriggerDelay = v end })
trigSec:Toggle({ Name = "Show FOV Circle", Default = Config.Aim.FOVCircle, Callback = function(v) Config.Aim.FOVCircle = v end })

--== ABA ESP ==--
local espTab = Window:Tab("ESP")
local espSec = espTab:Section("Players")
espSec:Toggle({ Name = "Player ESP", Default = Config.ESP.Players.Enabled, Callback = function(v) Config.ESP.Players.Enabled = v end })
espSec:Toggle({ Name = "Show Names", Default = Config.ESP.Players.Names, Callback = function(v) Config.ESP.Players.Names = v end })
espSec:Toggle({ Name = "Show Health", Default = Config.ESP.Players.Health, Callback = function(v) Config.ESP.Players.Health = v end })
espSec:Toggle({ Name = "Show Distance", Default = Config.ESP.Players.Distance, Callback = function(v) Config.ESP.Players.Distance = v end })
espSec:Slider({ Name = "Range", Min = 100, Max = 5000, Default = Config.ESP.Players.Range, Step = 100, Callback = function(v) Config.ESP.Players.Range = v end })
local objSec = espTab:Section("Objects")
objSec:Toggle({ Name = "Walkers (Monsters)", Default = Config.ESP.Walkers.Enabled, Callback = function(v) Config.ESP.Walkers.Enabled = v end })
objSec:Toggle({ Name = "Extract (Exits)", Default = Config.ESP.Extract.Enabled, Callback = function(v) Config.ESP.Extract.Enabled = v end })
local colorSec = espTab:Section("Colors")
colorSec:ColorPicker({ Name = "Player Color", Default = Config.ESP.Players.Color, Callback = function(c) Config.ESP.Players.Color = c end })
colorSec:ColorPicker({ Name = "Walker Color", Default = Config.ESP.Walkers.Color, Callback = function(c) Config.ESP.Walkers.Color = c end })
colorSec:ColorPicker({ Name = "Extract Color", Default = Config.ESP.Extract.Color, Callback = function(c) Config.ESP.Extract.Color = c end })

--== ABA MODULES ==--
local modTab = Window:Tab("Modules")
local patchSec = modTab:Section("Game Patches")
patchSec:Toggle({ Name = "No Recoil", Default = Config.Modules.NoRecoil, Callback = function(v) Config.Modules.NoRecoil = v; if getgenv().HushCheat then getgenv().HushCheat.ApplyPatches() end end })
patchSec:Toggle({ Name = "No Spread", Default = Config.Modules.NoSpread, Callback = function(v) Config.Modules.NoSpread = v; if getgenv().HushCheat then getgenv().HushCheat.ApplyPatches() end end })

--== ABA MISC ==--
local miscTab = Window:Tab("Misc")
local miscSec = miscTab:Section("Character")
miscSec:Toggle({ Name = "Anti-AFK", Default = Config.Misc.AntiAFK, Callback = function(v) Config.Misc.AntiAFK = v end })
local panicSec = miscTab:Section("Panic")
panicSec:Keybind({ Name = "Panic Key (Unload)", Default = Config.Misc.PanicKey, Callback = function(k) Config.Misc.PanicKey = k end })
miscSec:Button({ Name = "UNLOAD CHEAT", Callback = function() if getgenv().HushCheat then getgenv().HushCheat.Unload() end end })
