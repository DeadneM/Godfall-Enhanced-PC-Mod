-- Godfall Enhanced V0.6H41 Single-Function DataBridge Event Timeline / F1 overlay TEST
-- No hooks. No loadout/session mutation. No entitlement changes.
-- METHOD_A = apply Hinterclaw MacrosCosmetic material overrides
-- METHOD_B = restore materials captured before apply
-- METHOD_C = arm/stop one exact DataBridge UFunction Type-only observation

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
local PROBE_MAX_SAMPLES=5
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

-- H34: summarize only the route category of a view URL, never the
-- remote host, port, query/fragment, absolute path or credentials.
local function h34_safe_route(value)
    if type(value)~="string" or #value==0 or #value>420 then return nil end
    local scheme=probe_lower(value:match("^([%a][%w+%.%-]*):") or "relative")
    local path=nil
    local origin="not_applicable"
    if scheme=="http" or scheme=="https" then
        local host,rest=value:match("^https?://([^/%?#]+)([^%?#]*)")
        if host==nil then return "scheme="..scheme.." route=redacted" end
        local localHost=probe_lower(host):match("^([^:]+)") or ""
        origin=(localHost=="localhost" or localHost=="127.0.0.1")
            and "loopback" or "non_loopback"
        path=rest
    elseif scheme=="coui" then
        path=value:match("^coui://[^/]*(/[^%?#]*)") or "/"
    elseif scheme=="relative" then
        path=value:match("^([^%?#]*)") or ""
    else
        return "scheme=other route=redacted"
    end
    path=(path or ""):gsub("\\","/"):gsub("^/+","")
    local summary="scheme="..scheme.." origin="..origin
    if #path==0 then return summary.." leaf=empty" end
    if #path>120 or not path:match("^[%w_%.%-%/]+$") then
        return summary.." leaf=redacted"
    end
    local lower=probe_lower(path)
    if probe_has_any(lower,{"user","home","appdata","account",
        "session","auth","token","secret","email","profile",
        "credential","password"}) or lower:find("%d%d%d%d%d%d") then
        return summary.." leaf=redacted"
    end
    local leaf=path:match("([^/]+)$") or ""
    if #leaf==0 or #leaf>55 then return summary.." leaf=redacted" end
    if leaf:find("%d%d%d%d") then return summary.." leaf=redacted" end
    -- Only log the final simple resource name/route, not its parent
    -- folders, user-specific parameters or HTTP host.
    return summary.." leaf="..leaf
end

local h34_cdo_read_done=false
local function h34_read_class_defaults(target,obj)
    if target~="WBP_Menu_Game_C" and
        target~="CoherentUIGTSettings" then return end
    local ok,cdo=pcall(function() return obj:GetCDO() end)
    if not ok or cdo==nil then
        log("H34_CDO_NOT_AVAILABLE class="..target)
        return
    end
    local props=target=="WBP_Menu_Game_C" and
        {"ReactSettingsURL","ReactCharacterSelectURL"} or
        {"CoUIResourcesRoot"}
    for _,field in ipairs(props) do
        local v=h33_read_string(cdo,field)
        if v==nil then
            log("H34_CDO_FIELD_UNAVAILABLE class="..target.." field="..field)
        else
            local safe=h34_safe_route(v)
            if safe~=nil then
                log("H34_CDO_ROUTE class="..target.." field="..field.." "..safe)
            end
        end
    end
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
    if property=="URL" or property=="CoUIResourcesRoot" then
        local route=h34_safe_route(value)
        if route then
            local rk="H34_ROUTE|"..property.."|"..route
            if not h33_seen_values[rk] then
                h33_seen_values[rk]=true
                changed[#changed+1]={property=property.."_ROUTE",value=route}
            end
        end
    end
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
        "CoherentUIGTComponent","CoherentUIGTSettings",
        "WBP_GT_Test_C","WBP_Menu_Game_C"
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
            h34_read_class_defaults(target,obj)
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
    log("H32_PROBE_ARMED interval_approx_seconds=12 max_samples=5")
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

-- H36: single-shot read-only audit of the actual Sanctum Valorplate Alcove
-- instances. The FModel CDO export has no CosmeticTagToPlayerSkin values.
-- Never invoke SetValorplateCosmetic here; that is an action, not an unlock proof.
local function h36_string(value)
    local v=unwrap(value)
    if v==nil then return nil end
    local ok,ret=pcall(function()return v:ToString() end)
    if ok and ret~=nil then return tostring(ret) end
    local ok2,text=pcall(function() return tostring(v) end)
    if ok2 and text~=nil then return text end
    return nil
end

local function h36_tag(key)
    local v=unwrap(key)
    if v==nil then return "UNREADABLE" end
    local ok,tag=pcall(function() return v.TagName end)
    if not ok or tag==nil then
        ok,tag=pcall(function() return v:GetPropertyValue("TagName") end)
    end
    if ok and tag~=nil then
        local text=h36_string(tag)
        if text~=nil and #text<240 then return text end
    end
    return "TAG_NOT_DECODABLE"
end

local function h36_class(value)
    local v=unwrap(value)
    if v==nil then return "NONE" end
    local ok,path=pcall(function()return v.AssetPathName end)
    if ok and path~=nil then
        local text=h36_string(path)
        if text~=nil and #text<320 then return text end
    end
    local ok2,text=pcall(function() return v:GetFullName() end)
    if ok2 and text~=nil and #tostring(text)<320 then return tostring(text) end
    return "SOFTCLASS_UNRESOLVED"
end

-- H37: bounded, read-only probes. Guard every UE4SS native call:
-- (1) classify the SoftClass map values; (2) Alcove class members;
-- (3) compare native menu widget presence before/inside skin menu.
-- Nothing is inserted into CosmeticTagToPlayerSkin.
local h37_meta_logged=false
local h37_c_presses=0

local function h37_safe_identifier(v)
    if v==nil then return nil end
    local function asstr(x)
        if x==nil then return nil end
        local ok,s=pcall(function()return x:ToString() end)
        if ok and s~=nil then return tostring(s) end
        ok,s=pcall(function()return x:GetFullName() end)
        if ok and s~=nil then return tostring(s) end
        ok,s=pcall(function()return tostring(x) end)
        if ok and s~=nil then return tostring(s) end
        return nil
    end
    local str=asstr(unwrap(v))
    if not str then return nil end
    -- Do not log addresses, arbitrary object dumps, URLs or paths outside assets.
    local path=str:match("(/Game/[%w_%.%/-]+)")
    if path and #path<260 then return path end
    local bp=str:match("(BP_[%w_]+_C)")
    if bp and #bp<120 then return bp end
    local tag=str:match("(Character%.Player%.[%w_%.]+)")
    if tag and #tag<220 then return tag end
    return nil
end

local function h37_softclass_probe(v)
    local obj=unwrap(v)
    if obj==nil then return "NIL" end
    local ok_kind,kind=pcall(function()return obj:type() end)
    kind=(ok_kind and kind~=nil) and tostring(kind) or type(obj)
    kind=kind:gsub("[^%w_]","")
    if #kind>48 then kind=kind:sub(1,48) end

    local probes={
        {"AssetPathName",function()return obj.AssetPathName end},
        {"SoftObjectPath",function()return obj.SoftObjectPath end},
        {"SoftObjectPath.AssetPathName",function()return obj.SoftObjectPath.AssetPathName end},
        {"AssetPath.AssetPathName",function()return obj.AssetPath.AssetPathName end},
        {"AssetPtr",function()return obj.AssetPtr end},
        {"GetAssetPathName",function()return obj:GetAssetPathName() end},
        {"ToString",function()return obj:ToString() end},
        {"GetFullName",function()return obj:GetFullName() end},
    }
    for _,entry in ipairs(probes) do
        local ok,value=pcall(entry[2])
        if ok and value~=nil then
            local resolved=h37_safe_identifier(value)
            if resolved~=nil then
                return "type="..kind.." source="..entry[1].." path="..resolved
            end
        end
    end
    return "type="..kind.." path=UNRESOLVED"
end

local function h37_alcove_class_metadata(actor)
    if h37_meta_logged then return end
    h37_meta_logged=true
    log("H37_CLASS_AUDIT_BEGIN target=HinterclawAlcove")
    local ok,cls=pcall(function()return actor:GetClass() end)
    if not ok or not object_ok(cls) then
        log("H37_CLASS_AUDIT_END status=no_class mutated=0")
        return
    end
    local function interesting(s)
        local lower=s:lower()
        return lower:find("cosmetic",1,true) or
               lower:find("skin",1,true) or
               lower:find("owned",1,true) or
               lower:find("select",1,true) or
               lower:find("valorplate",1,true) or
               lower:find("exalt",1,true) or
               lower:find("unlock",1,true) or
               lower:find("preview",1,true)
    end
    local func_count,prop_count=0,0
    local ok_fn,err_fn=pcall(function()
        cls:ForEachFunction(function(fn)
            if func_count>=36 then return true end
            local name=full(fn)
            if interesting(name) and #name<240 then
                func_count=func_count+1
                log("H37_CLASS_FUNCTION "..name)
            end
        end)
    end)
    if not ok_fn then log("H37_CLASS_FUNCTION_ERROR reason="..tostring(err_fn):sub(1,100)) end
    local ok_prop,err_prop=pcall(function()
        cls:ForEachProperty(function(prop)
            if prop_count>=28 then return true end
            local name=full(prop)
            if interesting(name) and #name<240 then
                prop_count=prop_count+1
                log("H37_CLASS_PROPERTY "..name)
            end
        end)
    end)
    if not ok_prop then log("H37_CLASS_PROPERTY_ERROR reason="..tostring(err_prop):sub(1,100)) end
    log("H37_CLASS_AUDIT_END functions="..func_count..
        " properties="..prop_count.." mutated=0")
end

local function h37_ui_snapshot()
    h37_c_presses=h37_c_presses+1
    local sample=h37_c_presses
    log("H37_UI_SNAPSHOT_BEGIN sample="..sample..
        " stage="..(sample==1 and "SANCTUM_BASELINE" or "VANILLA_MENU_COMPARISON"))
    for _,short in ipairs({"WBP_GT_Test_C","WBP_Menu_Game_C"}) do
        local ok,obj=pcall(function()return FindFirstOf(short) end)
        if not ok then
            log("H37_UI_WIDGET_ERROR class="..short)
        elseif not object_ok(obj) then
            log("H37_UI_WIDGET class="..short.." present=0")
        else
            log("H37_UI_WIDGET class="..short.." present=1")
            if short=="WBP_Menu_Game_C" then
                for _,prop in ipairs({"ReactCharacterSelectURL","ReactSettingsURL"}) do
                    local got,val=pcall(function()return obj:GetPropertyValue(prop) end)
                    if got and val~=nil then
                        local r=h34_safe_route(tostring(val))
                        if r then log("H37_UI_ROUTE property="..prop.." "..r) end
                    end
                end
            end
        end
    end
    log("H37_UI_SNAPSHOT_END sample="..sample.." mutated=0")
end

local function h36_audit_alcove_map()
    log("H36_ALCOVE_AUDIT_BEGIN mode=read_only")
    local ok,instances=pcall(function() return FindAllOf("BP_ValorplateAlcove_C") end)
    if not ok then
        log("H36_FIND_INSTANCES_ERROR="..tostring(instances))
        log("H36_ALCOVE_AUDIT_END status=error mutated=0")
        return
    end
    if type(instances)~="table" or #instances==0 then
        log("H36_NO_LIVE_ALCOVES check=Sanctum_loaded")
        log("H36_ALCOVE_AUDIT_END actors=0 mutated=0")
        return
    end
    local total,with_map,with_entries,matched=0,0,0,0
    log("H36_INSTANCES_FOUND count="..tostring(#instances))
    for _,actor in ipairs(instances) do
        if total>=20 then break end
        total=total+1
        if object_ok(actor) then
            local name=full(actor)
            -- Log just the actor name/path, never pointer addresses.
            if #name>240 then name=name:sub(1,240) end
            log("H36_ALCOVE_ACTOR n="..total.." "..name)
            if name:find("BP_VPAlcove_Hinterclaw",1,true) then
                h37_alcove_class_metadata(actor)
            end
            local get_ok,map=pcall(function()
                return actor:GetPropertyValue("CosmeticTagToPlayerSkin")
            end)
            if not get_ok or map==nil then
                get_ok,map=pcall(function() return actor.CosmeticTagToPlayerSkin end)
            end
            if not get_ok or map==nil then
                log("H36_ALCOVE_MAP_UNAVAILABLE actor="..total)
            else
                with_map=with_map+1
                local len_ok,map_len=pcall(function()return #map end)
                log("H36_ALCOVE_MAP_SIZE actor="..total.." count="..(len_ok and tostring(map_len) or "UNKNOWN"))
                local count=0
                local ok_iter,err=pcall(function()
                    map:ForEach(function(key,value)
                        count=count+1
                        if count>128 then return true end
                        local tag=h36_tag(key)
                        local lower=tag:lower()
                        if lower:find("hinterclaw",1,true) or
                           lower:find("macros",1,true) or
                           lower:find("gratitude",1,true) then
                            matched=matched+1
                            if matched<=48 then
                                log("H36_ALCOVE_MATCH actor="..total..
                                    " tag="..tag.." class="..h36_class(value))
                                log("H37_SOFTCLASS actor="..total..
                                    " tag="..tag.." "..h37_softclass_probe(value))
                            end
                        end
                    end)
                end)
                if ok_iter then
                    with_entries=with_entries+count
                    log("H36_ALCOVE_MAP_ITER_OK actor="..total.." visited="..count)
                else
                    log("H36_ALCOVE_MAP_ITER_UNAVAILABLE actor="..total.." reason="..tostring(err):sub(1,180))
                end
            end
        else
            log("H36_ALCOVE_INVALID actor="..total)
        end
    end
    log("H36_ALCOVE_AUDIT_END actors="..total.." maps="..with_map..
        " visited="..with_entries.." hinterclaw_matches="..matched.." mutated=0")
end

-- H38: one-view experiment after H37's two-state UI finding.
-- Inspect WBP_GT_Test_C only when it actually exists, and keep
-- the Coherent host probe separate from eligibility/entitlement logic.
local h38_metadata_done=false

local function h38_property_name(prop)
    local ok,name=pcall(function() return prop:GetFName():ToString() end)
    if not ok or type(name)~="string" then return nil end
    if #name>95 or not name:match("^[%w_]+$") then return nil end
    return name
end

local function h38_relevant(name)
    local lower=name:lower()
    for _,term in ipairs({
        "cosmetic","skin","character","select","coherent",
        "widget","data","bridge","event","menu","view",
        "route","url","react","page","request","initialize",
        "construct","destroy","loaded","player","owned","available"
    }) do
        if lower:find(term,1,true) then return true end
    end
    return false
end

local function h38_class_metadata(widget)
    if h38_metadata_done then return end
    h38_metadata_done=true
    log("H38_GT_CLASS_BEGIN target=WBP_GT_Test_C")
    local ok,cls=pcall(function() return widget:GetClass() end)
    if not ok or not object_ok(cls) then
        log("H38_GT_CLASS_END status=no_class mutated=0")
        return
    end
    local fn_count,prop_count=0,0
    local fn_ok,fn_err=pcall(function()
        cls:ForEachFunction(function(fn)
            if fn_count>=60 then return true end
            local name=full(fn):match(":([^:]+)$")
            if name and #name<=95 and h38_relevant(name) then
                fn_count=fn_count+1
                log("H38_GT_FUNCTION name="..name)
            end
        end)
    end)
    if not fn_ok then log("H38_GT_FUNCTION_ERROR reason="..tostring(fn_err):sub(1,90)) end
    local prop_ok,prop_err=pcall(function()
        cls:ForEachProperty(function(prop)
            if prop_count>=65 then return true end
            local name=h38_property_name(prop)
            if name and h38_relevant(name) then
                prop_count=prop_count+1
                local t=full(prop):match("^([%w_]+)") or "Property"
                log("H38_GT_PROPERTY name="..name.." type="..t)
                -- Read only the URL fields, never JS payloads or arbitrary UI data.
                if name:lower():find("url",1,true) then
                    local value=h33_read_string(widget,name)
                    local safe=value and h34_safe_route(value) or nil
                    if safe then log("H38_GT_ROUTE field="..name.." "..safe) end
                end
            end
        end)
    end)
    if not prop_ok then log("H38_GT_PROPERTY_ERROR reason="..tostring(prop_err):sub(1,90)) end
    log("H38_GT_CLASS_END functions="..fn_count.." properties="..prop_count.." mutated=0")
end

local function h38_view_probe(class_name)
    local ok,obj=pcall(function() return FindFirstOf(class_name) end)
    if not ok then
        log("H38_VIEW class="..class_name.." search=failed")
        return
    end
    if not object_ok(obj) then
        log("H38_VIEW class="..class_name.." present=0")
        return
    end
    log("H38_VIEW class="..class_name.." present=1")
    local url=h33_read_string(obj,"URL")
    if url then
        local safe=h34_safe_route(url)
        if safe then log("H38_VIEW_URL class="..class_name.." "..safe) end
    end
    local ok_outer,outer=pcall(function() return obj:GetOuter() end)
    if ok_outer and object_ok(outer) then
        local name=full(outer):lower()
        -- Classify parent; do not log memory addresses or full transient paths.
        local relation=name:find("wbp_gt_test",1,true) and "GT_TEST" or
            (name:find("coherentuigt",1,true) and "COHERENT" or
            (name:find("gameinstance",1,true) and "GAME_INSTANCE" or "OTHER"))
        log("H38_VIEW_PARENT class="..class_name.." category="..relation)
    end
end

local function h38_active_frontend()
    log("H38_GT_PROBE_BEGIN mode=read_only")
    local ok,widget=pcall(function() return FindFirstOf("WBP_GT_Test_C") end)
    if not ok then
        log("H38_GT_PROBE_END status=lookup_error mutated=0")
        return
    end
    if not object_ok(widget) then
        log("H38_GT_PRESENT=0")
        log("H38_GT_PROBE_END status=not_loaded mutated=0")
        return
    end
    log("H38_GT_PRESENT=1")
    h38_class_metadata(widget)
    -- H32/H33 found CoherentUIGTWidget_Persistent near this widget.
    -- Probe only three specific classes, with no global UObject traversal.
    h38_view_probe("CoherentUIGTWidget_Persistent")
    h38_view_probe("CoherentUIGTWidget")
    h38_view_probe("CoherentUIGTComponent")
    log("H38_GT_PROBE_END status=completed mutated=0")
end

-- H39: direct read-only inspection of the specific Coherent widget component
-- exposed by WBP_GT_Test_C. No Javascript calls or Unreal setters.
local h39_metadata_seen=false
local function h39_safe_name(x)
    if x==nil then return nil end
    local str=tostring(x)
    if #str<1 or #str>95 or not str:match("^[%w_]+$") then return nil end
    return str
end

local function h39_relevant_name(name)
    local s=name:lower()
    for _,token in ipairs({"url","source","view","page","resource","coherent",
        "scripting","javascript","js","bind","ready","event","data",
        "load","bridge","handler","interface","web"}) do
        if s:find(token,1,true) then return true end
    end
    return false
end

local function h39_child_members(child)
    if h39_metadata_seen then return end
    h39_metadata_seen=true
    log("H39_CHILD_META_BEGIN")
    local ok,c=pcall(function()return child:GetClass() end)
    if not ok or not object_ok(c) then
        log("H39_CHILD_META_END status=no_class mutated=0")
        return
    end
    local nf,np,depth=0,0,0
    while object_ok(c) and depth<4 do
        local class_name=full(c)
        local leaf=class_name:match("([%w_]+)$") or "UNKNOWN"
        if #leaf>95 then leaf=leaf:sub(1,95) end
        log("H39_CHILD_CLASS depth="..depth.." name="..leaf)
        local okf,ef=pcall(function()
            c:ForEachFunction(function(fn)
                if nf>=48 then return true end
                local n=h39_safe_name(full(fn):match(":([^:]+)$"))
                if n and h39_relevant_name(n) then
                    nf=nf+1
                    log("H39_CHILD_FUNCTION depth="..depth.." name="..n)
                end
            end)
        end)
        if not okf then log("H39_FUNCTION_READ_ERROR depth="..depth) end
        local okp,ep=pcall(function()
            c:ForEachProperty(function(prop)
                if np>=45 then return true end
                local okn,n=pcall(function()return prop:GetFName():ToString() end)
                n=okn and h39_safe_name(n) or nil
                if n and h39_relevant_name(n) then
                    np=np+1
                    local typename=h39_safe_name(full(prop):match("^([%w_]+)")) or "Property"
                    log("H39_CHILD_PROPERTY depth="..depth.." name="..n.." type="..typename)
                end
            end)
        end)
        if not okp then log("H39_PROPERTY_READ_ERROR depth="..depth) end
        if nf>=48 and np>=45 then break end
        local oks,parent=pcall(function()return c:GetSuperStruct() end)
        if not oks or not object_ok(parent) or full(parent)==full(c) then break end
        c=parent
        depth=depth+1
    end
    log("H39_CHILD_META_END functions="..nf.." properties="..np.." mutated=0")
end

local function h39_child_route(child)
    for _,key in ipairs({"URL","Url","SourceURL","InitialURL"}) do
        local value=h33_read_string(child,key)
        if value then
            local safe=h34_safe_route(value)
            if safe then log("H39_CHILD_ROUTE field="..key.." "..safe) end
        end
    end
end

local function h39_specific_child_probe()
    log("H39_CHILD_PROBE_BEGIN mode=read_only")
    local ok,host=pcall(function()return FindFirstOf("WBP_GT_Test_C") end)
    if not ok or not object_ok(host) then
        log("H39_CHILD_PROBE_END status=host_not_loaded mutated=0")
        return
    end
    local got,child=pcall(function()
        return unwrap(host:GetPropertyValue("CoherentUIGTWidget_Persistent_90"))
    end)
    if not got or not object_ok(child) then
        log("H39_CHILD_PROPERTY result=unavailable")
        log("H39_CHILD_PROBE_END status=child_unavailable mutated=0")
        return
    end
    log("H39_CHILD_PROPERTY result=resolved")
    local o,outer=pcall(function()return child:GetOuter() end)
    local relationship=o and object_ok(outer) and full(outer)==full(host)
    log("H39_CHILD_OWNERSHIP direct="..(relationship and "1" or "0"))
    local label=full(child):match("([%w_]+)$")
    if label and #label<100 then log("H39_CHILD_INSTANCE name="..label) end
    h39_child_route(child)
    h39_child_members(child)
    log("H39_CHILD_PROBE_END status=completed mutated=0")
end

-- H40: optional, short-lived DataBridge request TYPE tracer.
-- This is a narrow UFunction hook, NOT a ProcessEvent/foreach hook.
-- It never reads Payload or Promise, never calls their methods, and never
-- changes return values, entitlement fields, JS state, rewards or saves.
local h40 = {
    active=false, hooks={}, ticks=0, hits=0, filtered=0, 
    by_type={}, install_attempts=0,
}
local H40_MAX_HITS=48
local H40_MAX_TICKS=360  -- LoopAsync(250ms): approximately 90 seconds
local H40_PATHS={
    {label="BASE",path="/Game/Aperion/Blueprints/UI/WBP_GT_Base.WBP_GT_Base_C:OnDataBridgeIncomingRequest"},
    {label="SETTINGS",path="/Game/Aperion/Blueprints/UI/WBP_GT_Settings.WBP_GT_Settings_C:OnDataBridgeIncomingRequest"},
}

local function h40_get_type_only(type_param)
    if type_param==nil then return nil end
    local val=unwrap(type_param)
    if type(val)=="string" then return h33_safe_event(val) end
    if val~=nil then
        local ok,s=pcall(function()return val:ToString() end)
        if ok and type(s)=="string" then return h33_safe_event(s) end
    end
    return nil
end

local function h40_cleanup(reason)
    if not h40.active then return end
    h40.active=false
    local removed,failed=0,0
    for _,record in ipairs(h40.hooks) do
        if type(record.pre)=="number" and type(record.post)=="number" then
            local ok=pcall(function()
                UnregisterHook(record.path,record.pre,record.post)
            end)
            if ok then removed=removed+1 else failed=failed+1 end
        else
            failed=failed+1
        end
    end
    h40.hooks={}
    log("H40_BRIDGE_STOP reason="..tostring(reason)..
        " hits="..h40.hits.." filtered="..h40.filtered..
        " unregistered="..removed.." errors="..failed.." mutated=0")
end

local function h40_on_event(label,context,type_param)
    if not h40.active then return end
    local ok,err=pcall(function()
        local ctx=unwrap(context)
        if not object_ok(ctx) then return end
        local ctx_name=full(ctx)
        -- Avoid requests from other generic menus/screen types.
        if not ctx_name:find("WBP_GT_Test",1,true) then return end
        h40.hits=h40.hits+1
        local safe=h40_get_type_only(type_param)
        local value=safe or "[FILTERED]"
        if not safe then h40.filtered=h40.filtered+1 end
        -- Count duplicates but print at most three per label/type.
        local key=label.."|"..value
        local count=(h40.by_type[key] or 0)+1
        h40.by_type[key]=count
        if count<=3 then
            log("H40_BRIDGE_TYPE host=GT_TEST source="..label..
                " type="..value.." count="..count)
        end
        if h40.hits>=H40_MAX_HITS then
            -- Do not unregister UFunction hooks from inside their own callback.
            h40.ticks=H40_MAX_TICKS
        end
    end)
    if not ok then
        h40.filtered=h40.filtered+1
        if h40.filtered<=3 then log("H40_CALLBACK_READ_ERROR redacted=true") end
    end
end

local function h40_start()
    if h40.active then
        h40_cleanup("MANUAL_STOP")
        return
    end
    log("H40_BRIDGE_ARM_BEGIN scope=GT_TEST request_type_only")
    local ok,host=pcall(function()return FindFirstOf("WBP_GT_Test_C") end)
    if not ok or not object_ok(host) then
        log("H40_BRIDGE_NOT_ARMED reason=GT_TEST_NOT_LOADED; open_original_skins_menu_first")
        return
    end
    if type(RegisterHook)~="function" or type(UnregisterHook)~="function" then
        log("H40_BRIDGE_NOT_ARMED reason=HOOK_API_UNAVAILABLE")
        return
    end
    h40.active=true
    h40.ticks=0;h40.hits=0;h40.filtered=0
    h40.by_type={};h40.hooks={};h40.install_attempts=0
    for _,target in ipairs(H40_PATHS) do
        h40.install_attempts=h40.install_attempts+1
        local ok_reg,pre,post=pcall(function()
            return RegisterHook(target.path,function(context,type_param,payload,promise)
                -- Payload and Promise are intentionally not inspected.
                h40_on_event(target.label,context,type_param)
                -- Returning nothing lets native behavior proceed unchanged.
            end)
        end)
        if ok_reg and type(pre)=="number" and type(post)=="number" then
            h40.hooks[#h40.hooks+1]={path=target.path,pre=pre,post=post}
            log("H40_BRIDGE_HOOK_OK source="..target.label)
        else
            log("H40_BRIDGE_HOOK_UNAVAILABLE source="..target.label..
                " note=function_may_not_be_loaded")
        end
    end
    if #h40.hooks==0 then
        h40_cleanup("NO_HOOKS_REGISTERED")
        return
    end
    log("H40_BRIDGE_ARMED hooks="..#h40.hooks.." max_events="..
        H40_MAX_HITS.." timeout_approx_sec=90 mutated=0")
end

local function h40_tick()
    if not h40.active then return end
    h40.ticks=h40.ticks+1
    if h40.ticks>=H40_MAX_TICKS then
        h40_cleanup(h40.hits>=H40_MAX_HITS and "EVENT_LIMIT" or "TIME_LIMIT")
    end
end

-- H41: lower-volume, SINGLE exact Blueprint hook. H40's double hook
-- captured the same event family twice and exhausted the limit too soon.
-- Only sanitized request TYPE names are observed, not Payload/Promise.
local h41={active=false,hook=nil,ticks=0,hits=0,filtered=0,names={},events={}}
local H41_MAX_EVENTS=160
local H41_MAX_TICKS=360 -- existing 250 ms loop, ~90 seconds
local H41_UFUNCTION="/Game/Aperion/Blueprints/UI/WBP_GT_Base.WBP_GT_Base_C:OnDataBridgeIncomingRequest"

local function h41_stop(reason)
    if not h41.active then return end
    h41.active=false
    local removed,failed=0,0
    if h41.hook~=nil then
        local hook=h41.hook
        local ok=pcall(function()
            UnregisterHook(H41_UFUNCTION,hook.pre,hook.post)
        end)
        if ok then removed=1 else failed=1 end
    end
    h41.hook=nil
    local unique=0
    for _ in pairs(h41.names) do unique=unique+1 end
    log("H41_BRIDGE_STOP reason="..reason..
        " hits="..h41.hits.." unique_types="..unique..
        " filtered="..h41.filtered.." unregistered="..removed..
        " errors="..failed.." mutated=0")
    local names={}
    for name in pairs(h41.names) do names[#names+1]=name end
    table.sort(names)
    for idx=1,math.min(30,#names) do
        local name=names[idx]
        log("H41_BRIDGE_SUMMARY type="..name.." count="..h41.names[name])
    end
end

local function h41_on_event(context,type_param)
    if not h41.active then return end
    local ok=pcall(function()
        local ctx=unwrap(context)
        if not object_ok(ctx) then return end
        local name=full(ctx)
        if not name:find("WBP_GT_Test",1,true) then return end
        local type_name=h40_get_type_only(type_param)
        if type_name==nil then
            h41.filtered=h41.filtered+1
            type_name="[FILTERED]"
        end
        h41.hits=h41.hits+1
        local count=(h41.names[type_name] or 0)+1
        h41.names[type_name]=count

        local low=type_name:lower()
        local high_signal=low:find("loadout",1,true) or
            low:find("skin",1,true) or
            low:find("cosmetic",1,true) or
            low:find("valorplate",1,true) or
            low:find("route",1,true) or
            low:find("equip",1,true) or
            low:find("weapon",1,true) or
            low:find("unlock",1,true)
        local cap=high_signal and 32 or 2
        if count<=cap then
            log("H41_BRIDGE_EVENT n="..h41.hits..
                " type="..type_name.." count="..count)
        end
        if h41.hits>=H41_MAX_EVENTS then
            -- Unhook safely from normal LoopAsync, not within this callback.
            h41.ticks=H41_MAX_TICKS
        end
    end)
    if not ok then
        h41.filtered=h41.filtered+1
        if h41.filtered<=2 then log("H41_EVENT_READ_ERROR fields_redacted=1") end
    end
end

local function h41_toggle()
    if h41.active then
        h41_stop("MANUAL_STOP")
        return
    end
    log("H41_BRIDGE_ARM_BEGIN scope=GT_TEST single=BASE type_only=1")
    local ok,host=pcall(function()return FindFirstOf("WBP_GT_Test_C") end)
    if not ok or not object_ok(host) then
        log("H41_BRIDGE_NOT_ARMED reason=GT_TEST_NOT_LOADED")
        return
    end
    if type(RegisterHook)~="function" or type(UnregisterHook)~="function" then
        log("H41_BRIDGE_NOT_ARMED reason=HOOK_API_UNAVAILABLE")
        return
    end
    h41.active=true;h41.ticks=0;h41.hits=0;h41.filtered=0;h41.names={}
    local success,pre,post=pcall(function()
        return RegisterHook(H41_UFUNCTION,function(context,type_param,payload,promise)
            -- Payload and Promise are never accessed.
            h41_on_event(context,type_param)
            -- No return value override or request mutation.
        end)
    end)
    if not success or type(pre)~="number" or type(post)~="number" then
        log("H41_BRIDGE_HOOK_UNAVAILABLE source=BASE")
        h41_stop("INSTALL_FAILED")
        return
    end
    h41.hook={pre=pre,post=post}
    log("H41_BRIDGE_HOOK_OK source=BASE")
    log("H41_BRIDGE_ARMED hooks=1 max_events="..H41_MAX_EVENTS..
        " timeout_approx_sec=90 mutated=0")
end

local function h41_tick()
    if not h41.active then return end
    h41.ticks=h41.ticks+1
    if h41.ticks>=H41_MAX_TICKS then
        h41_stop(h41.hits>=H41_MAX_EVENTS and "EVENT_LIMIT" or "TIME_LIMIT")
    end
end

local function process_command(command)
    local op = tostring(command or ""):match("^(%S+)") or ""
    log("COMMAND " .. tostring(command):gsub("[\r\n]+", " "))
    if op == "METHOD_A" or op == "APPLY_MACROS" then apply_macros(); return end
    if op == "METHOD_B" or op == "H11_RESTORE" or op == "RESTORE" then restore(); return end
    if op == "METHOD_C" or op == "DATABRIDGE_TRACE_TOGGLE" then
        h41_toggle()
        return
    end
    if op == "DATABRIDGE_TRACE_STOP" then h41_stop("USER_STOP"); return end
    if op == "COHERENT_CHILD_AUDIT" then
        h37_ui_snapshot()
        h39_specific_child_probe()
        return
    end
    if op == "GT_HOST_METADATA" then h38_active_frontend(); return end
    if op == "ALCOVE_MAP_AUDIT" then h36_audit_alcove_map(); return end
    if op == "AUTO_UI_WATCH" or op == "COHERENT_PROBE" then
        probe_arm()
        return
    end
    if op == "DUMP_MATERIALS" then dump_materials(); return end
    if op == "UNLOCK_UI_AUDIT" or op == "UNLOCK_AUDIT" or op == "AUDIT_UNLOCK" then probe_arm(); return end
    if op == "STOP_UI_WATCH" or op == "STOP_COHERENT_PROBE" then probe_stop("USER"); return end
    if op == "PING" then log("PONG H41"); return end
    log("H23_UNKNOWN_COMMAND " .. op)
end

do
    local f = io.open(LOG_PATH, "w")
    if f then f:write(""); f:close() end
end
log("V0.6H41 Single-Function DataBridge Event Timeline / F1 overlay starting (H25 base)")
log("H41_BOOT_MARKER=OK")
log("H41_HOOKS=OPTIONAL_ON_C_ONLY")
log("H23_METHOD_A=Apply MacrosCosmetic materials via class hierarchy/direct call")
log("H23_METHOD_B=Restore captured materials")
log("H41_METHOD_C=single BASE DataBridge request type timeline and summary")

LoopAsync(250, function()
    local cmd = read_command()
    if cmd ~= nil then
        ExecuteInGameThread(function()
            local ok, err = pcall(function() process_command(cmd) end)
            if not ok then log("H23_COMMAND_FATAL " .. tostring(err)) end
        end)
    end
    probe_tick()
    h40_tick()
    h41_tick()
end)
