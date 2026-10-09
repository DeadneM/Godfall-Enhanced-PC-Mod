-- Godfall Enhanced V0.6H33 Coherent GT Value Probe / F1 overlay TEST
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


-- H32: targeted read-only Coherent GT / native cosmetic UI bridge probe.
-- No JavaScript execution or method calls into views, no mutation/hook.
-- Only transient class handles within an ExecuteInGameThread callback.
local frontend_watch = {
    active=false, pending=false, ticks=0, samples=0, previous=nil
}
local PROBE_PERIOD_TICKS=48 -- 250 ms * 48 ~= 12 seconds
local PROBE_MAX_SAMPLES=10
local PROBE_MAX_CHANGED=70

local function probe_lower(value) return tostring(value or ""):lower() end
local function probe_has_any(value, words)
    local v=probe_lower(value)
    for _,w in ipairs(words) do
        if v:find(w,1,true) then return true end
    end
    return false
end

local function probe_kind(name)
    local lower=probe_lower(name)
    if lower:find("coherentuigt",1,true) or
       lower:find("coherentui",1,true) then return "COHERENT" end
    if lower:find("wbp_gt_test",1,true) then return "GT_ROOT" end
    if lower:find("wbp_menu_game",1,true) then return "MENU_GAME" end
    if lower:find("cosmetic",1,true) or lower:find("skin",1,true) or
       lower:find("appearance",1,true) then
        if lower:find("widgetblueprintgeneratedclass",1,true)
           or lower:find("wbp_",1,true)
           or lower:find("/ui/",1,true)
           or lower:find("/menus/",1,true) then
            return "COSMETIC_UI"
        end
    end
    return nil
end

local function probe_class_metadata(classes)
    table.sort(classes,function(a,b)
        if a.rank~=b.rank then return a.rank>b.rank end
        return a.name<b.name
    end)
    local class_count,fn_count,prop_count=0,0,0
    for _,entry in ipairs(classes) do
        if class_count>=14 then break end
        class_count=class_count+1
        log("H32_CLASS_META kind="..entry.kind.." "..entry.name)
        local ok,err=pcall(function()
            entry.obj:ForEachFunction(function(fn)
                if fn_count>=150 then return end
                local nm=full(fn)
                local leaf=probe_lower(nm:match(":([^:]+)$") or nm)
                local rel={
                    "load","url","view","bind","event","javascript","trigger",
                    "cosmetic","skin","set","get","menu","refresh","select",
                    "initialize","resource","interface","ready","navigate",
                    "script","page","create","register","change","focus"
                }
                if probe_has_any(leaf,rel) then
                    fn_count=fn_count+1
                    log("H32_CLASS_FUNCTION "..nm)
                end
            end)
        end)
        if not ok then log("H32_CLASS_FUNCTION_ERROR "..entry.name.." "..tostring(err)) end
        local okp,errp=pcall(function()
            entry.obj:ForEachProperty(function(prop)
                if prop_count>=140 then return end
                local okn,name=pcall(function()return prop:GetFName():ToString() end)
                if okn and name~=nil then
                    local rel={
                        "view","url","page","asset","resource","load","script",
                        "javascript","bind","event","data","coherent",
                        "cosmetic","skin","menu","widget","focus","ready",
                        "select","owner","path","source"
                    }
                    if probe_has_any(name,rel) then
                        prop_count=prop_count+1
                        log("H32_CLASS_PROPERTY class="..entry.name..
                            " field="..tostring(name).." type="..full(prop))
                    end
                end
            end)
        end)
        if not okp then log("H32_CLASS_PROPERTY_ERROR "..entry.name.." "..tostring(errp)) end
    end
    log("H32_CLASS_METADATA_END classes="..class_count..
        " functions="..fn_count.." properties="..prop_count.." mutated=0")
end

-- H33: selected runtime values ONLY. Never call Coherent/JSEvent functions,
-- process JS payload arguments, hook methods, or save any UObject handles.
local h33_seen_values = {}
local h33_metadata_done = false

local function h33_read_string(obj, key)
    local ok,value=pcall(function() return obj:GetPropertyValue(key) end)
    if not ok or value==nil then return nil end
    if type(value)=="string" then return value end
    local okstr,sv=pcall(function() return value:ToString() end)
    if okstr and type(sv)=="string" then return sv end
    -- A typed string property may be exposed as a Lua primitive by the
    -- UE4SS version. Avoid logging opaque userdata or memory addresses.
    return nil
end

local function h33_safe_event(value)
    if type(value)~="string" or #value<1 or #value>70 then return nil end
    if not value:match("^[%a_][%w_.:%-]*$") then return nil end
    local v=value:lower()
    if v:find("password",1,true) or v:find("session",1,true)
       or v:find("auth",1,true) or v:find("secret",1,true)
       or v:find("token",1,true) or v:find("email",1,true)
       or v:find("key=",1,true) or v:find("%d%d%d%d%d%d%d%d") then
        return nil
    end
    return value
end

local function h33_safe_resource(value)
    if type(value)~="string" or #value<1 or #value>220 then return nil end
    local s=value:match("^[^%?%#]+") or ""
    if #s==0 then return nil end
    local low=s:lower()
    -- Never copy absolute paths, URLs with authorities or tokens into logs.
    if low:find("http://",1,true) or low:find("https://",1,true)
        or low:find("file://",1,true) or low:find("c:\\",1,true)
        or low:find("/users/",1,true) or low:find("/home/",1,true)
        or low:find("@",1,true) or low:find("token",1,true)
        or low:find("auth",1,true) then
        local scheme=s:match("^([%a][%w+%.%-]*):")
        return "[REDACTED_ABSOLUTE_RESOURCE scheme="..tostring(scheme or "none").."]"
    end
    -- Coherent coui:// references and relative game paths are useful
    -- but we still strip query/fragment and constrain characters.
    if not s:match("^[%w_%.%-%/\\:]+$") then return "[REDACTED_RESOURCE]" end
    return s
end

local function h33_probe_value(obj,kind,name,changed)
    local property=nil
    if name:find("CoherentUIGTJSPayload /Engine/Transient.",1,true) then
        property="EventName"
    elseif name:find("CoherentUIGTSettings ",1,true) then
        property="CoUIResourcesRoot"
    elseif kind=="COHERENT" and
        (name:find("CoherentUIGTWidget",1,true) or
         name:find("CoherentUIGTComponent ",1,true)) then
        property="URL"
    end
    if not property then return end
    local value=h33_read_string(obj,property)
    if value==nil then return end
    local safe=(property=="EventName") and h33_safe_event(value) or h33_safe_resource(value)
    if safe==nil then return end
    local key=property.."|"..safe
    if not h33_seen_values[key] then
        h33_seen_values[key]=true
        changed[#changed+1]={property=property,value=safe}
    end
end

local function h33_class_widget_metadata(classes)
    if h33_metadata_done then return end
    h33_metadata_done=true
    local targets={
        "CoherentUIGTWidget_Persistent","CoherentUIGTWidget",
        "CoherentUIGTComponent","WBP_GT_Test_C","WBP_Menu_Game_C"
    }
    local found={}
    for _,entry in ipairs(classes) do
        for _,target in ipairs(targets) do
            if entry.name:match("^Class /Script/CoherentUIGTPlugin%."..target.."$")
               or entry.name:find("."..target,1,true) then
                if not found[target] then found[target]=entry.obj end
            end
        end
    end
    for _,target in ipairs(targets) do
        local obj=found[target]
        if obj~=nil then
            log("H33_TARGET_CLASS "..target.." "..full(obj))
            local count=0
            local ok,err=pcall(function()
                obj:ForEachProperty(function(prop)
                    if count>=50 then return end
                    local valid,pname=pcall(function() return prop:GetFName():ToString() end)
                    if valid and pname then
                        local lower=tostring(pname):lower()
                        if probe_has_any(lower,{
                            "url","page","view","resource","load","asset","path",
                            "javascript","script","coherent","bind","event",
                            "interface","menu","cosmetic","skin","source"
                        }) then
                            count=count+1
                            log("H33_TARGET_PROPERTY class="..target..
                                " name="..tostring(pname).." type="..full(prop))
                        end
                    end
                end)
            end)
            if not ok then log("H33_TARGET_META_ERROR "..target.." "..tostring(err)) end
        end
    end
end

local function probe_snapshot(reason)
    frontend_watch.samples=frontend_watch.samples+1
    local number=frontend_watch.samples
    log("H32_PROBE_BEGIN sample="..number.." reason="..tostring(reason))
    local found,classes={},{}
    local found_values={}
    local scanned=0
    local ok,err=pcall(function()
        ForEachUObject(function(obj)
            if obj==nil then return end
            scanned=scanned+1
            local okn,name=pcall(function()return obj:GetFullName() end)
            if not okn or name==nil then return end
            name=tostring(name)
            local kind=probe_kind(name)
            if not kind then return end
            -- Avoid reflecting asset content and transient classes unrelated
            -- to the live frontend, including materials/animation/VFX.
            if probe_has_any(name,{"material","skeletalmesh","staticmesh",
                "niagara","texture","animsequence","function /","property /",
                "soundwave","datatable"}) then return end
            found[name]=kind
            h33_probe_value(obj,kind,name,found_values)
            if name:find("^Class ") or name:find("^WidgetBlueprintGeneratedClass ")
                or name:find("^BlueprintGeneratedClass ") then
                local rank=kind=="COHERENT" and 100 or
                    kind=="GT_ROOT" and 85 or
                    kind=="MENU_GAME" and 75 or 50
                classes[#classes+1]={obj=obj,name=name,kind=kind,rank=rank}
            end
        end)
    end)
    if not ok then
        log("H32_PROBE_SCAN_ERROR "..tostring(err))
        return false
    end
    table.sort(found_values,function(a,b)
        if a.property~=b.property then return a.property<b.property end
        return a.value<b.value
    end)
    log("H33_VALUE_SUMMARY sample="..number.." unique_new="..#found_values)
    for i=1,math.min(#found_values,35) do
        log("H33_VALUE field="..found_values[i].property.." value="..found_values[i].value)
    end
    h33_class_widget_metadata(classes)
    local counts={COHERENT=0,GT_ROOT=0,MENU_GAME=0,COSMETIC_UI=0}
    local names={}
    for name,kind in pairs(found) do
        counts[kind]=(counts[kind] or 0)+1
        names[#names+1]=name
    end
    table.sort(names)
    log("H32_PROBE_COUNTS sample="..number.." scanned="..scanned..
        " total="..#names.." coherent="..counts.COHERENT..
        " gt_root="..counts.GT_ROOT.." menu_game="..counts.MENU_GAME..
        " cosmetic_ui="..counts.COSMETIC_UI)
    if frontend_watch.previous==nil then
        log("H32_PROBE_BASELINE_SAVED")
        for _,name in ipairs(names) do
            local kind=found[name]
            if kind=="COHERENT" or kind=="GT_ROOT" or kind=="MENU_GAME" then
                log("H32_BASELINE_INSTANCE kind="..kind.." "..name)
            end
        end
        probe_class_metadata(classes)
    else
        local added,removed={},{}
        for name in pairs(found) do
            if not frontend_watch.previous[name] then added[#added+1]=name end
        end
        for name in pairs(frontend_watch.previous) do
            if not found[name] then removed[#removed+1]=name end
        end
        table.sort(added)
        table.sort(removed)
        log("H32_PROBE_DIFF sample="..number.." added="..#added..
            " removed="..#removed)
        for i=1,math.min(#added,PROBE_MAX_CHANGED) do
            local name=added[i]
            log("H32_PROBE_ADDED kind="..found[name].." "..name)
        end
        for i=1,math.min(#removed,PROBE_MAX_CHANGED) do
            local name=removed[i]
            log("H32_PROBE_REMOVED kind="..frontend_watch.previous[name].." "..name)
        end
    end
    -- Store names/labels, not transient UObject handles, between ticks.
    frontend_watch.previous=found
    log("H32_PROBE_END sample="..number.." mutated=0")
    return true
end

local function probe_stop(reason)
    if not frontend_watch.active then return end
    frontend_watch.active=false
    log("H32_PROBE_STOP reason="..tostring(reason)..
        " samples="..frontend_watch.samples.." mutated=0")
end

local function probe_arm()
    if frontend_watch.active then
        log("H32_PROBE_MANUAL_SAMPLE")
        local passed=probe_snapshot("MANUAL")
        if not passed then probe_stop("SCAN_FAILED") end
        frontend_watch.ticks=0
        return
    end
    frontend_watch.active=true
    frontend_watch.pending=false
    frontend_watch.ticks=0
    frontend_watch.samples=0
    frontend_watch.previous=nil
    h33_seen_values={}
    h33_metadata_done=false
    log("H32_PROBE_ARMED interval_approx_seconds=12 max_samples=10")
    if not probe_snapshot("BASELINE") then probe_stop("BASELINE_FAILED") end
end

local function probe_tick()
    if not frontend_watch.active or frontend_watch.pending then return end
    if frontend_watch.samples>=PROBE_MAX_SAMPLES then
        probe_stop("MAX_SAMPLES")
        return
    end
    frontend_watch.ticks=frontend_watch.ticks+1
    if frontend_watch.ticks<PROBE_PERIOD_TICKS then return end
    frontend_watch.ticks=0
    frontend_watch.pending=true
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            if frontend_watch.active then
                if not probe_snapshot("AUTO") then probe_stop("SCAN_FAILED") end
                if frontend_watch.samples>=PROBE_MAX_SAMPLES then
                    probe_stop("MAX_SAMPLES")
                end
            end
        end)
        frontend_watch.pending=false
        if not ok then
            log("H32_PROBE_EXCEPTION "..tostring(err))
            probe_stop("EXCEPTION")
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
    if op == "METHOD_C" or op == "AUTO_UI_WATCH" or op == "COHERENT_PROBE" then
        probe_arm()
        return
    end
    if op == "DUMP_MATERIALS" then dump_materials(); return end
    if op == "UNLOCK_UI_AUDIT" or op == "UNLOCK_AUDIT" or op == "AUDIT_UNLOCK" then probe_arm(); return end
    if op == "STOP_UI_WATCH" or op == "STOP_COHERENT_PROBE" then probe_stop("USER"); return end
    if op == "PING" then log("PONG H33"); return end
    log("H23_UNKNOWN_COMMAND " .. op)
end

do
    local f = io.open(LOG_PATH, "w")
    if f then f:write(""); f:close() end
end
log("V0.6H33 Coherent GT Value Probe / F1 overlay starting (H25 base)")
log("H33_BOOT_MARKER=OK")
log("H24_NO_HOOKS=TRUE")
log("H23_METHOD_A=Apply MacrosCosmetic materials via class hierarchy/direct call")
log("H23_METHOD_B=Restore captured materials")
log("H33_METHOD_C=Targeted Coherent GT URL/root/event name string values, read-only")

LoopAsync(250, function()
    local cmd = read_command()
    if cmd ~= nil then
        ExecuteInGameThread(function()
            local ok, err = pcall(function() process_command(cmd) end)
            if not ok then log("H23_COMMAND_FATAL " .. tostring(err)) end
        end)
    end
    probe_tick()
end)
