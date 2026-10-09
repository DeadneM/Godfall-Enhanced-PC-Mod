-- Godfall Enhanced V0.6H31 Native UI Catalog Focus / F1 overlay TEST
-- No hooks. No loadout/session mutation. No entitlement changes.
-- METHOD_A = apply Hinterclaw MacrosCosmetic material overrides
-- METHOD_B = restore materials captured before apply
-- METHOD_C = dump current material slots 0..3

local LOG_PATH = "../GodfallEnhancedBridge.log"
local CMD_PATHS = {
    "Mods/GodfallEnhancedBridge/bridge_command.txt",
    "ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt",
    "../ue4ss/Mods/GodfallEnhancedBridge/bridge_command.txt"
}

local MATERIALS = {
    {pkg="/Game/Aperion/Characters/Macros/Materials/MI_Macros_lower", name="MI_Macros_lower"},
    {pkg="/Game/Aperion/Characters/Macros/Materials/MI_Macros_Fur", name="MI_Macros_Fur"},
    {pkg="/Game/Aperion/Characters/Macros/Materials/MI_MAcros_Cloth", name="MI_Macros_Cloth"},
    {pkg="/Game/Aperion/Characters/Macros/Materials/MI_Macros_Upper", name="MI_Macros_Upper"},
}

local saved_mesh_name = nil
local saved_materials = nil
local VERBOSE_VERIFICATION = true

-- Optional diagnostic setting; verification always runs regardless of INI.
for _,path in ipairs({
    "GodfallEnhanced.ini",
    "../GodfallEnhanced.ini",
    "ue4ss/Mods/GodfallEnhancedBridge/GodfallEnhanced.ini",
    "../ue4ss/Mods/GodfallEnhancedBridge/GodfallEnhanced.ini"
}) do
    local f = io.open(path, "r")
    if f then
        for line in f:lines() do
            local key, value = line:match("^%s*([%w_]+)%s*=%s*([%w_]+)")
            if key == "VerboseVerification" then
                VERBOSE_VERIFICATION = (value ~= "0")
                break
            end
        end
        f:close()
        break
    end
end

local fn_get_material = nil
local fn_set_material = nil

local function log(msg)
    local line = "[GodfallEnhancedBridge] " .. tostring(msg)
    print(line .. "\n")
    local f = io.open(LOG_PATH, "a")
    if f then f:write(line, "\n"); f:close() end
end

local function full(obj)
    if obj == nil then return "<nil>" end
    local ok, s = pcall(function() return obj:GetFullName() end)
    if ok and s ~= nil then return tostring(s) end
    return tostring(obj)
end

local function object_ok(obj)
    if obj == nil then return false end
    local ok, s = pcall(function() return obj:GetFullName() end)
    return ok and s ~= nil and tostring(s) ~= ""
end

local function unwrap(v)
    if v == nil then return nil end
    local ok, t = pcall(function() return v:type() end)
    if ok and (t == "LocalUnrealParam" or t == "RemoteUnrealParam") then
        local okg, got = pcall(function() return v:get() end)
        if okg then return got end
    end
    return v
end

local function resolve_material_functions(mesh)
    if object_ok(fn_get_material) and object_ok(fn_set_material) then return true end
    if not object_ok(mesh) then return false end

    local okc, cls = pcall(function() return mesh:GetClass() end)
    if not okc or not object_ok(cls) then
        log("H23_RESOLVE_NO_CLASS")
        return false
    end

    local depth = 0
    while object_ok(cls) and depth < 16 do
        log("H23_CLASS[" .. tostring(depth) .. "]=" .. full(cls))
        local oke, err = pcall(function()
            cls:ForEachFunction(function(fn)
                if fn == nil then return end
                local n = full(fn)
                local suffix_get = ":GetMaterial"
                local suffix_set = ":SetMaterial"
                if not object_ok(fn_get_material) and #n >= #suffix_get and n:sub(-#suffix_get) == suffix_get then
                    fn_get_material = fn
                    log("H23_FOUND_GETMATERIAL=" .. n)
                elseif n:find(":GetMaterial", 1, true) then
                    log("H23_SKIP_GET_CANDIDATE=" .. n)
                end
                if not object_ok(fn_set_material) and #n >= #suffix_set and n:sub(-#suffix_set) == suffix_set then
                    fn_set_material = fn
                    log("H23_FOUND_SETMATERIAL=" .. n)
                elseif n:find(":SetMaterial", 1, true) then
                    log("H23_SKIP_SET_CANDIDATE=" .. n)
                end
            end)
        end)
        if not oke then log("H23_FOREACHFUNCTION_ERROR depth=" .. tostring(depth) .. " err=" .. tostring(err)) end
        if object_ok(fn_get_material) and object_ok(fn_set_material) then break end

        local oks, sup = pcall(function() return cls:GetSuperStruct() end)
        if not oks or not object_ok(sup) or full(sup) == full(cls) then break end
        cls = sup
        depth = depth + 1
    end

    log("H23_GETMATERIAL_FN=" .. full(fn_get_material))
    log("H23_SETMATERIAL_FN=" .. full(fn_set_material))
    return object_ok(fn_get_material) and object_ok(fn_set_material)
end

local function try_direct_get(mesh, index)
    local packed = table.pack(pcall(function() return mesh:GetMaterial(index) end))
    if not packed[1] then
        log("H23_DIRECT_GET_ERROR slot=" .. tostring(index) .. " err=" .. tostring(packed[2]))
        return nil
    end
    for i=2,packed.n do
        local v = unwrap(packed[i])
        if v ~= nil and object_ok(v) then return v end
    end
    return nil
end

local function try_direct_set(mesh, index, mat)
    local ok, err = pcall(function() mesh:SetMaterial(index, mat) end)
    if not ok then
        log("H23_DIRECT_SET_ERROR slot=" .. tostring(index) .. " err=" .. tostring(err))
        return false
    end
    log("H23_DIRECT_SET_OK slot=" .. tostring(index))
    return true
end

local function find_live_hinterclaw_mesh()
    local found = nil
    ForEachUObject(function(obj)
        if found ~= nil or obj == nil then return end
        local ok, s = pcall(function() return obj:GetFullName() end)
        if not ok or s == nil then return end
        local n = tostring(s)
        if n:find("SkeletalMeshComponent ", 1, true)
            and n:find("PersistentLevel.BP_Hinterclaw", 1, true)
            and n:find("CharacterMesh0", 1, true)
            and not n:find("Default__", 1, true) then
            found = obj
        end
    end)
    log("H23_LIVE_MESH=" .. full(found))
    return found
end

local function find_loaded_material(item)
    local direct_paths = {
        item.pkg .. "." .. item.name,
        "MaterialInstanceConstant " .. item.pkg .. "." .. item.name,
    }
    for _, p in ipairs(direct_paths) do
        local ok, obj = pcall(function() return StaticFindObject(p) end)
        if ok and object_ok(obj) then return obj end
    end

    local found = nil
    ForEachUObject(function(obj)
        if found ~= nil or obj == nil then return end
        local ok, s = pcall(function() return obj:GetFullName() end)
        if ok and s ~= nil then
            local n = tostring(s)
            if n:find(item.pkg, 1, true) and n:find("." .. item.name, 1, true) then found = obj end
        end
    end)
    return found
end

local function load_material(item)
    local ok, err = pcall(function() LoadAsset(item.pkg) end)
    if not ok then log("H23_LOADASSET_ERROR " .. item.name .. " " .. tostring(err)) end
    local mat = find_loaded_material(item)
    log("H23_MATERIAL " .. item.name .. " = " .. full(mat))
    return mat
end

local function get_material(mesh, index)
    local direct = try_direct_get(mesh, index)
    if direct ~= nil then
        log("H23_GET_DIRECT_OK slot=" .. tostring(index) .. " mat=" .. full(direct))
        return direct
    end

    if not resolve_material_functions(mesh) or not object_ok(fn_get_material) then
        log("H23_GET_REFUSED no exact GetMaterial")
        return nil
    end

    local packed = table.pack(pcall(function() return fn_get_material(mesh, index) end))
    if not packed[1] then
        log("H23_GET_ERROR slot=" .. tostring(index) .. " err=" .. tostring(packed[2]))
        return nil
    end
    for i=2,packed.n do
        local v = unwrap(packed[i])
        if v ~= nil and object_ok(v) then
            log("H23_GET_REFLECT_OK slot=" .. tostring(index) .. " mat=" .. full(v))
            return v
        end
    end
    log("H23_GET_EMPTY slot=" .. tostring(index))
    return nil
end

local function set_material(mesh, index, mat)
    if try_direct_set(mesh, index, mat) then
        log("H23_SET_DIRECT_OK slot=" .. tostring(index) .. " mat=" .. full(mat))
        return true
    end

    if not resolve_material_functions(mesh) or not object_ok(fn_set_material) then
        log("H23_SET_REFUSED no exact SetMaterial")
        return false
    end
    local ok, err = pcall(function() fn_set_material(mesh, index, mat) end)
    if not ok then
        log("H23_SET_ERROR slot=" .. tostring(index) .. " err=" .. tostring(err))
        return false
    end
    log("H23_SET_REFLECT_OK slot=" .. tostring(index) .. " mat=" .. full(mat))
    return true
end

local function dump_materials()
    local mesh = find_live_hinterclaw_mesh()
    if not object_ok(mesh) then log("H23_DUMP_REFUSED no live Hinterclaw CharacterMesh0"); return end
    local okp, arr = pcall(function() return mesh:GetPropertyValue("OverrideMaterials") end)
    if okp then
        arr = unwrap(arr)
        log("H23_OVERRIDE_MATERIALS=" .. tostring(arr))
        if arr ~= nil then
            local okn, n = pcall(function() return arr:GetArrayNum() end)
            if okn then log("H23_OVERRIDE_COUNT=" .. tostring(n)) end
        end
    else
        log("H23_OVERRIDE_ERROR " .. tostring(arr))
    end
    for i=0,3 do
        local mat = get_material(mesh, i)
        log("H23_SLOT[" .. tostring(i) .. "]=" .. full(mat))
    end
end

local function same_material(a, b)
    return object_ok(a) and object_ok(b) and full(a) == full(b)
end

-- Restore records must NEVER retain UE4SS userdata across game frames.
-- A Lua table of UObject proxies does not keep a dynamic material alive for Unreal GC.
-- For a runtime MID, follow Parent while the instance is still attached and alive.
-- Restore the stable parent asset (runtime parameter overrides may differ).
local function capture_safe_material(original, slot)
    local original_name = full(original)
    local current = original
    local seen = {}
    local fallback = false
    for depth=0,7 do
        if not object_ok(current) then break end
        local current_name = full(current)
        if seen[current_name] then break end
        seen[current_name] = true
        local class = current_name:match("^(%S+)") or ""
        if class ~= "MaterialInstanceDynamic" then
            local record = { original_name=original_name, restore_name=current_name, fallback=fallback }
            log("H25_CAPTURE_OK slot=" .. slot .. " kind=" .. (fallback and "PARENT_ASSET" or "EXACT_ASSET") .. " source=" .. original_name .. " restore=" .. current_name)
            return record
        end
        fallback = true
        local ok, parent = pcall(function() return unwrap(current:GetPropertyValue("Parent")) end)
        if not ok or not object_ok(parent) then
            log("H25_CAPTURE_NO_PARENT slot=" .. slot .. " source=" .. current_name)
            break
        end
        current = parent
    end
    log("H25_CAPTURE_UNSAFE slot=" .. slot .. " source=" .. original_name .. " ; restore will refuse if needed")
    return { original_name=original_name, restore_name=nil, fallback=true }
end

local function resolve_safe_restore(record, slot)
    if record == nil or record.restore_name == nil then
        log("H25_RESOLVE_REFUSED slot=" .. slot .. " no safe asset snapshot")
        return nil
    end
    -- Deliberately do not look up the original runtime MaterialInstanceDynamic.
    -- It may have been garbage-collected after we replaced its mesh override.
    local name = record.restore_name
    local path = name:match("^%S+%s+(.+)$")
    if path == nil then log("H25_RESOLVE_BAD_PATH slot=" .. slot .. " name=" .. name); return nil end
    local pkg = path:match("^(.+)%.[^%.]+$")
    if pkg ~= nil and (pkg:sub(1,6)=="/Game/" or pkg:sub(1,8)=="/Engine/") then
        local ok, err = pcall(function() LoadAsset(pkg) end)
        if not ok then log("H25_RELOAD_WARN slot=" .. slot .. " err=" .. tostring(err)) end
    end
    local ok, obj = pcall(function() return StaticFindObject(name) end)
    if not ok or not object_ok(obj) or full(obj) ~= name then
        log("H25_RESOLVE_MISSING slot=" .. slot .. " asset=" .. name)
        return nil
    end
    log("H25_RESOLVE_OK slot=" .. slot .. " asset=" .. name)
    return obj
end

local function apply_macros()
    log("H23_APPLY_BEGIN")
    local mesh = find_live_hinterclaw_mesh()
    if not object_ok(mesh) then log("H23_APPLY_REFUSED no live Hinterclaw CharacterMesh0"); return end

    -- A second APPLY must never replace the originally captured vanilla materials.
    if saved_materials ~= nil then
        if saved_mesh_name == full(mesh) then
            log("H24_ALREADY_APPLIED: use Method B before applying again")
            return
        end
        log("H24_STALE_SNAPSHOT: live mesh instance changed; dropping obsolete snapshot")
        saved_materials = nil
        saved_mesh_name = nil
    end

    local mats = {}
    for i,item in ipairs(MATERIALS) do
        mats[i] = load_material(item)
        if not object_ok(mats[i]) then
            log("H23_APPLY_REFUSED material missing " .. item.name)
            return
        end
    end

    local originals = {}
    local snapshots = {}
    for i=0,3 do
        local original = get_material(mesh, i)
        if original == nil then
            log("H25_APPLY_REFUSED could not read original slot " .. tostring(i))
            return
        end
        -- A-scope raw objects are used ONLY for an immediate rollback in this
        -- same GameThread invocation, never stored across commands.
        originals[i+1] = original
        snapshots[i+1] = capture_safe_material(original, i)
    end

    local changed, verified = 0, 0
    for i=0,3 do
        if not set_material(mesh, i, mats[i+1]) then break end
        changed = changed + 1
        local observed = get_material(mesh, i)
        if not same_material(observed, mats[i+1]) then
            log("H24_VERIFY_FAILED slot=" .. tostring(i) .. " expected=" .. full(mats[i+1]) .. " observed=" .. full(observed))
            break
        end
        verified = verified + 1
        if VERBOSE_VERIFICATION then log("H24_VERIFY_OK slot=" .. tostring(i)) end
    end

    if changed == 4 and verified == 4 then
        saved_mesh_name = full(mesh)
        saved_materials = snapshots
        log("H25_APPLY_OK changed=4 verified=4 target=Character.Player.Hinterclaw.MacrosCosmetic")
    else
        log("H24_APPLY_INCOMPLETE changed=" .. tostring(changed) .. " verified=" .. tostring(verified) .. "; rolling back")
        local rolled_back = 0
        for i=0,changed-1 do
            local ok = set_material(mesh, i, originals[i+1])
            local observed = get_material(mesh, i)
            if ok and same_material(observed, originals[i+1]) then
                rolled_back = rolled_back + 1
            else
                log("H24_ROLLBACK_FAILED slot=" .. tostring(i))
            end
        end
        if rolled_back ~= changed then
            -- Preserve recovery path rather than losing the only original snapshot.
            saved_mesh_name = full(mesh)
            saved_materials = snapshots
            log("H25_ROLLBACK_PARTIAL: Method B can retry using stable material assets")
        else
            log("H24_ROLLBACK_OK count=" .. tostring(rolled_back))
        end
    end
end

local function restore()
    log("H23_RESTORE_BEGIN")
    if saved_materials == nil or saved_mesh_name == nil then
        log("H23_RESTORE_REFUSED no saved material state")
        return
    end
    local mesh = find_live_hinterclaw_mesh()
    if not object_ok(mesh) then log("H23_RESTORE_REFUSED no live Hinterclaw CharacterMesh0"); return end
    if full(mesh) ~= saved_mesh_name then
        log("H23_RESTORE_REFUSED current mesh changed; switch back to the same Hinterclaw instance")
        return
    end
    -- Preflight ALL assets before touching any slot. Missing assets fail closed.
    local safe_assets = {}
    local used_parent = false
    for i=0,3 do
        local rec = saved_materials[i+1]
        safe_assets[i+1] = resolve_safe_restore(rec, i)
        if not object_ok(safe_assets[i+1]) then
            log("H25_RESTORE_REFUSED slot=" .. tostring(i) .. " ; no writes attempted")
            return
        end
        if rec.fallback then used_parent = true end
    end
    local restored = 0
    for i=0,3 do
        local ok = set_material(mesh, i, safe_assets[i+1])
        local observed = get_material(mesh, i)
        if ok and same_material(observed, safe_assets[i+1]) then
            restored = restored + 1
            if VERBOSE_VERIFICATION then log("H25_RESTORE_VERIFIED slot=" .. tostring(i)) end
        else
            log("H25_RESTORE_VERIFY_FAILED slot=" .. tostring(i) .. " expected=" .. full(safe_assets[i+1]) .. " observed=" .. full(observed))
            break
        end
    end
    if restored == 4 then
        log("H25_RESTORE_OK restored=4 verified=4 mode=" .. (used_parent and "PARENT_ASSET" or "EXACT_ASSET"))
        if used_parent then
            log("H25_NOTE runtime MID parameters are not guaranteed to be restored; re-equip default Hinterclaw if visuals differ")
        end
        saved_materials = nil
        saved_mesh_name = nil
    else
        log("H25_RESTORE_PARTIAL restored=" .. tostring(restored) .. " ; snapshot retained for retry")
    end
end


-- H30: bounded read-only automatic cosmetic UI watcher.
-- Arm with Method C once. It captures the baseline immediately and
-- samples widget/object presence automatically; no second click required.
-- No hooks, persistent Unreal object references or gameplay mutation.

local ui_watch_active = false
local ui_watch_pending = false
local ui_watch_ticks = 0
local ui_watch_samples = 0
local ui_watch_previous = nil
local ui_watch_baseline = nil
local ui_watch_total_changes = 0
local WATCH_PERIOD_TICKS = 48 -- LoopAsync(250): ~12 sec; conservative for ~250k UObjects
local WATCH_MAX_SAMPLES = 12 -- ~2.4 min, one sample every ~12 sec
local WATCH_MAX_LOG_OBJECTS = 120
local WATCH_MAX_LOG_DIFF = 160

local function contains_any(str, patterns)
    local n = tostring(str or ""):lower()
    for _,token in ipairs(patterns) do
        if n:find(token,1,true) then return true end
    end
    return false
end

local watch_tokens = {
    "cosmetic","appearance","skin","valorplate","customiz",
    "wardrobe","fashion","loadout","outfit","collection","characterselect",
    "userwidget","widgetblueprintgeneratedclass","wbp_","/ui/","/gui/","/menus/","/widgets/"
}
local watch_ui_tokens = {
    "widget","/ui/","/menus/","frontend","screen","wbp_",
    "cosmetics","playercustomization"
}
local watch_skip = {
    "material","texture","skeletalmesh","staticmesh","animsequence",
    "datatable","sound","niagara","function /","property /",
    "apwidgetcomponent /","apwidgetcomponentenemy /","combatmarkwidgetcomponent",
    "damagenumberdisplaywidgetcomponent","distributionfloatconstant"
}

local function h30_score(name)
    local l = tostring(name):lower()
    local score = 0
    if l:find("widgetblueprintgeneratedclass",1,true) then score=score+55 end
    if l:find("userwidget",1,true) then score=score+50 end
    if l:find("wbp_",1,true) then score=score+35 end
    if l:find("/ui/",1,true) or l:find("/gui/",1,true)
        or l:find("/menus/",1,true) then score=score+22 end
    if l:find("hinterclaw",1,true) then score=score+12 end
    if l:find("cosmetic",1,true) then score = score + 18 end
    if l:find("skin",1,true) then score = score + 8 end
    if l:find("appearance",1,true) then score = score + 8 end
    if l:find("customiz",1,true) then score = score + 8 end
    if l:find("widgetblueprintgeneratedclass",1,true) then score = score + 10 end
    if l:find("userwidget",1,true) or l:find("wbp_",1,true) then
        score = score + 7
    end
    if l:find("menu",1,true) then score = score + 3 end
    if l:find("valorplate",1,true) then score = score + 3 end
    if l:find("alcove",1,true) then score = score + 2 end
    if l:find("default__",1,true) then score = score - 8 end
    if l:find("niagara",1,true) then score = score - 10 end
    return score
end

local function h30_describe_classes(selected)
    table.sort(selected,function(a,b)
        if a.score ~= b.score then return a.score > b.score end
        return a.name < b.name
    end)
    local funcs, props, inspected = 0, 0, 0
    for _,entry in ipairs(selected) do
        if inspected >= 24 then break end
        inspected = inspected + 1
        log("H31_UI_CLASS score=" .. tostring(entry.score) .. " " .. entry.name)
        local okf, ferr = pcall(function()
            entry.obj:ForEachFunction(function(fn)
                if funcs >= 205 then return end
                local n = full(fn)
                local leaf = n:match(":([^:]+)$") or n
                if contains_any(leaf,{
                    "cosmetic","skin","unlock","owned","available","select",
                    "entitle","equip","refresh","visible","collection","filter",
                    "preview","display","populate","load","list","update"
                }) then
                    funcs = funcs + 1
                    log("H31_UI_FUNCTION " .. n)
                end
            end)
        end)
        if not okf then
            log("H31_UI_FUNCTION_ERROR " .. entry.name .. " " .. tostring(ferr))
        end
        local okp, perr = pcall(function()
            entry.obj:ForEachProperty(function(prop)
                if props >= 135 then return end
                local got, name = pcall(function()
                    return prop:GetFName():ToString()
                end)
                if got and name and contains_any(name,{
                    "cosmetic","skin","unlock","owned","available","select",
                    "entitle","equip","filter","preview","collection","widget",
                    "item","display"
                }) then
                    props = props + 1
                    log("H31_UI_PROPERTY class=" .. entry.name
                        .. " name=" .. tostring(name)
                        .. " kind=" .. full(prop))
                end
            end)
        end)
        if not okp then
            log("H31_UI_PROPERTY_ERROR " .. entry.name .. " " .. tostring(perr))
        end
    end
    log("H31_UI_REFLECTION classes=" .. tostring(inspected)
        .. " functions=" .. tostring(funcs)
        .. " properties=" .. tostring(props))
end

local function h30_take_snapshot(reason)
    ui_watch_samples = ui_watch_samples + 1
    local sample = ui_watch_samples
    log("H31_UI_SCAN_BEGIN sample=" .. tostring(sample) .. " reason=" .. tostring(reason))
    local names = {}
    local classes = {}
    local scanned, instances = 0, 0
    local ok, err = pcall(function()
        ForEachUObject(function(obj)
            if obj == nil then return end
            scanned = scanned + 1
            local got, raw = pcall(function() return obj:GetFullName() end)
            if not got or not raw then return end
            local name = tostring(raw)
            if not contains_any(name,watch_tokens) then return end
            if contains_any(name,watch_skip) then return end
            local is_class = name:find("^Class ") or
                name:find("^WidgetBlueprintGeneratedClass ") or
                name:find("^BlueprintGeneratedClass ")
            if not is_class and not contains_any(name,watch_ui_tokens) then return end
            if not names[name] then
                names[name] = true
                if is_class then
                    classes[#classes+1] = {
                        name=name,score=h30_score(name),obj=obj
                    }
                else
                    instances = instances + 1
                end
            end
        end)
    end)
    if not ok then
        log("H31_UI_SCAN_ERROR sample=" .. sample .. " " .. tostring(err))
        return false
    end
    local count=0
    for _ in pairs(names) do count=count+1 end
    log("H31_UI_SAMPLE sample=" .. sample
        .. " scanned=" .. scanned .. " matches=" .. count
        .. " classes=" .. #classes .. " instances=" .. instances)
    if ui_watch_previous == nil then
        ui_watch_baseline = names
        ui_watch_previous = names
        log("H31_UI_BASELINE_SAVED sample=1")
        local sorted={}
        for name in pairs(names) do sorted[#sorted+1]=name end
        table.sort(sorted,function(a,b)
            local sa,sb=h30_score(a),h30_score(b)
            if sa~=sb then return sa>sb end
            return a<b
        end)
        for i=1,math.min(#sorted,WATCH_MAX_LOG_OBJECTS) do
            log("H31_UI_BASE_OBJECT " .. sorted[i])
        end
        h30_describe_classes(classes)
    else
        local added, removed = {}, {}
        for name in pairs(names) do
            if not ui_watch_previous[name] then added[#added+1]=name end
        end
        for name in pairs(ui_watch_previous) do
            if not names[name] then removed[#removed+1]=name end
        end
        table.sort(added,function(a,b)
            if h30_score(a)~=h30_score(b) then return h30_score(a)>h30_score(b) end
            return a<b
        end)
        table.sort(removed,function(a,b)
            if h30_score(a)~=h30_score(b) then return h30_score(a)>h30_score(b) end
            return a<b
        end)
        local total=#added + #removed
        ui_watch_total_changes = ui_watch_total_changes + total
        log("H31_UI_DIFF sample=" .. sample ..
            " added=" .. #added .. " removed=" .. #removed ..
            " total_changes=" .. ui_watch_total_changes)
        local widget_add, skin_add, widget_remove, skin_remove = 0,0,0,0
        for _,name in ipairs(added) do
            local n=name:lower()
            if n:find("wbp_",1,true) or n:find("userwidget",1,true)
               or n:find("widgetblueprintgeneratedclass",1,true) then
                widget_add=widget_add+1
                if widget_add<=100 then log("H31_WIDGET_ADDED " .. name) end
            end
            if n:find("hinterclaw",1,true) and n:find("/skins/",1,true)
                and n:find("^blueprintgeneratedclass") then
                skin_add=skin_add+1
                log("H31_HINTERCLAW_SKIN_CLASS_ADDED " .. name)
            end
        end
        for _,name in ipairs(removed) do
            local n=name:lower()
            if n:find("wbp_",1,true) or n:find("userwidget",1,true)
               or n:find("widgetblueprintgeneratedclass",1,true) then
                widget_remove=widget_remove+1
                if widget_remove<=60 then log("H31_WIDGET_REMOVED " .. name) end
            end
            if n:find("hinterclaw",1,true) and n:find("/skins/",1,true)
                and n:find("^blueprintgeneratedclass") then
                skin_remove=skin_remove+1
                log("H31_HINTERCLAW_SKIN_CLASS_REMOVED " .. name)
            end
        end
        log("H31_UI_FOCUS_COUNTS sample=" .. sample ..
            " widgets_added=" .. widget_add .. " widgets_removed=" .. widget_remove ..
            " skin_classes_added=" .. skin_add .. " skin_classes_removed=" .. skin_remove)
        for i=1,math.min(#added,WATCH_MAX_LOG_DIFF) do
            log("H31_UI_ADDED_RANKED score=" .. h30_score(added[i]) .. " " .. added[i])
        end
        for i=1,math.min(#removed,WATCH_MAX_LOG_DIFF) do
            log("H31_UI_REMOVED_RANKED score=" .. h30_score(removed[i]) .. " " .. removed[i])
        end
        if total > 0 then
            local newClasses={}
            for _,entry in ipairs(classes) do
                if not ui_watch_baseline[entry.name] then
                    newClasses[#newClasses+1]=entry
                end
            end
            if #newClasses>0 then h30_describe_classes(newClasses) end
        end
        ui_watch_previous = names
    end
    log("H31_UI_SCAN_END sample=" .. sample .. " mutated=0")
    return true
end

local function h30_stop_watch(reason)
    if not ui_watch_active then return end
    ui_watch_active = false
    log("H31_UI_WATCH_STOP reason=" .. tostring(reason)
        .. " samples=" .. ui_watch_samples
        .. " total_changes=" .. ui_watch_total_changes .. " mutated=0")
end

local function h30_arm_watch()
    -- The first C press arms the monitor; further C presses can take
    -- an immediate snapshot but are NOT needed to complete the test.
    if ui_watch_active then
        log("H31_UI_MANUAL_SAMPLE active=1")
        h30_take_snapshot("MANUAL")
        ui_watch_ticks=0
        return
    end
    ui_watch_active=true
    ui_watch_ticks=0
    ui_watch_samples=0
    ui_watch_previous=nil
    ui_watch_baseline=nil
    ui_watch_total_changes=0
    log("H31_UI_WATCH_ARMED period_seconds_approx=12"
        .. " max_samples=" .. WATCH_MAX_SAMPLES
        .. " automatic=1 second_click_required=0")
    if not h30_take_snapshot("BASELINE") then
        h30_stop_watch("BASELINE_FAILED")
    end
end

local function h30_auto_tick()
    if not ui_watch_active or ui_watch_pending then return end
    if ui_watch_samples >= WATCH_MAX_SAMPLES then
        h30_stop_watch("MAX_SAMPLES")
        return
    end
    ui_watch_ticks = ui_watch_ticks + 1
    if ui_watch_ticks < WATCH_PERIOD_TICKS then return end
    ui_watch_ticks = 0
    ui_watch_pending = true
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            if ui_watch_active then
                local passed=h30_take_snapshot("AUTO")
                if not passed then h30_stop_watch("SCAN_FAILED") end
                if ui_watch_samples>=WATCH_MAX_SAMPLES then
                    h30_stop_watch("MAX_SAMPLES")
                end
            end
        end)
        ui_watch_pending = false
        if not ok then
            log("H31_UI_WATCH_ERROR " .. tostring(err))
            h30_stop_watch("EXCEPTION")
        end
    end)
end

local function read_command()
    for _,path in ipairs(CMD_PATHS) do
        local f = io.open(path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            if content ~= nil and content:gsub("%s+", "") ~= "" then
                local clear = io.open(path, "w")
                if clear then clear:write(""); clear:close() end
                log("COMMAND_FILE_READ " .. path)
                return content
            end
        end
    end
    return nil
end

local function process_command(command)
    local op = tostring(command or ""):match("^(%S+)") or ""
    log("COMMAND " .. tostring(command):gsub("[\r\n]+", " "))
    if op == "METHOD_A" or op == "APPLY_MACROS" then apply_macros(); return end
    if op == "METHOD_B" or op == "H11_RESTORE" or op == "RESTORE" then restore(); return end
    if op == "METHOD_C" or op == "AUTO_UI_WATCH" then
        h30_arm_watch()
        return
    end
    if op == "DUMP_MATERIALS" then dump_materials(); return end
    if op == "UNLOCK_UI_AUDIT" or op == "UNLOCK_AUDIT" or op == "AUDIT_UNLOCK" then h30_arm_watch(); return end
    if op == "STOP_UI_WATCH" then h30_stop_watch("USER"); return end
    if op == "PING" then log("PONG H30"); return end
    log("H23_UNKNOWN_COMMAND " .. op)
end

do
    local f = io.open(LOG_PATH, "w")
    if f then f:write(""); f:close() end
end
log("V0.6H30 Cosmetic UI Auto Watch / F1 overlay starting (H25 base)")
log("H31_BOOT_MARKER=OK")
log("H24_NO_HOOKS=TRUE")
log("H23_METHOD_A=Apply MacrosCosmetic materials via class hierarchy/direct call")
log("H23_METHOD_B=Restore captured materials")
log("H31_METHOD_C=Arm automatic UI watcher from baseline; no second C required")

LoopAsync(250, function()
    local cmd = read_command()
    if cmd ~= nil then
        ExecuteInGameThread(function()
            local ok, err = pcall(function() process_command(cmd) end)
            if not ok then log("H23_COMMAND_FATAL " .. tostring(err)) end
        end)
    end
    h30_auto_tick()
end)
