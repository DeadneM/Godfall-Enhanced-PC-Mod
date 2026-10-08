-- Godfall Enhanced V0.6H27 Native Unlock Audit / F1 overlay TEST
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


-- H27 native cosmetic unlock discovery. READ ONLY.
-- No calls to unlock/reward functions. No hooks, and no UObject userdata cached
-- between GameThread calls. Class reflection only in this invocation.
local function unlock_audit()
    log("H27_UNLOCK_AUDIT_BEGIN mode=READ_ONLY scope=Aperion")
    local rules = {
        {name="ownership", tokens={"unlock","entitle","account","reward","claim","profile","ownership"}, limit=9},
        {name="cosmetics", tokens={"cosmetic","appearance","skin","valorplate","customiz"}, limit=9},
        {name="inventory", tokens={"inventory","equipment","loadout","itemmanager","loot","acquis","collect"}, limit=10},
        {name="progression", tokens={"progress","persistence","savegame","playerstate","quest","session"}, limit=10},
        {name="player", tokens={"localplayer","playercontroller","playersubsystem","playerdata"}, limit=5},
    }
    local candidates, chosen, already, quota = {}, {}, {}, {}
    local ok, err = pcall(function()
        ForEachUObject(function(obj)
            if obj == nil then return end
            local good, val = pcall(function() return obj:GetFullName() end)
            if not good or val == nil then return end
            local n = tostring(val)
            if not n:find("^Class /Script/Aperion%.") or already[n] then return end
            local low = n:lower()
            -- Eliminate the input/gameplay action wrappers that swamped H26.
            if low:find("%.apaction_",1,true) or low:find("%.apactionrules_",1,true) then return end
            local group = nil
            for _,rule in ipairs(rules) do
                for _,tok in ipairs(rule.tokens) do
                    if low:find(tok,1,true) then
                        group = rule.name
                        break
                    end
                end
                if group then break end
            end
            if group == nil then return end
            already[n] = true
            local score = 0
            for _,v in ipairs({"manager","subsystem","component","service","localplayer","playerstate","profile","unlock","reward","inventory","cosmetic"}) do
                if low:find(v,1,true) then score = score + 3 end
            end
            if low:find("functionlibrary",1,true) then score = score - 2 end
            if low:find("gamepad",1,true) then score = score - 8 end
            if low:find("anim",1,true) then score = score - 3 end
            if low:find("ui",1,true) then score = score - 1 end
            if #candidates < 350 then
                candidates[#candidates+1] = {obj=obj,name=n,group=group,score=score}
            end
        end)
    end)
    if not ok then
        log("H27_UNLOCK_AUDIT_SCAN_ERROR " .. tostring(err))
        return
    end
    table.sort(candidates, function(a,b)
        if a.score ~= b.score then return a.score > b.score end
        return a.name < b.name
    end)
    local candidates_by_group = {}
    for _,entry in ipairs(candidates) do
        candidates_by_group[entry.group] = (candidates_by_group[entry.group] or 0) + 1
        local rule = nil
        for _,r in ipairs(rules) do if r.name == entry.group then rule = r; break end end
        quota[entry.group] = quota[entry.group] or 0
        if rule and quota[entry.group] < rule.limit then
            quota[entry.group] = quota[entry.group] + 1
            chosen[#chosen+1] = entry
        end
    end
    log("H27_CANDIDATES count=" .. tostring(#candidates) .. " selected=" .. tostring(#chosen))
    for _,r in ipairs(rules) do
        log("H27_GROUP " .. r.name .. " candidates=" .. tostring(candidates_by_group[r.name] or 0)
            .. " selected=" .. tostring(quota[r.name] or 0))
    end
    local function relevant(s)
        local l=tostring(s or ""):lower()
        for _,k in ipairs({"unlock","cosmetic","own","entitle","reward","grant","claim",
            "inventory","acquir","source","loadout","loot","profile","progress",
            "collect","playerstate","item","quest","skin","save","character","purchas"}) do
            if l:find(k,1,true) then return true end
        end
        return false
    end
    local signatures, funcs, props = 0, 0, 0
    for _,entry in ipairs(chosen) do
        log("H27_CLASS group=" .. entry.group .. " score=" .. tostring(entry.score)
            .. " name=" .. entry.name)
        local okf, ef = pcall(function()
            entry.obj:ForEachFunction(function(fn)
                if funcs >= 360 then return end
                local n = full(fn)
                if not relevant(n) then return end
                funcs = funcs + 1
                log("H27_FUNCTION " .. n)
                -- UFunction argument metadata is safe to enumerate, without
                -- calling the function. Cap signature expansion to 24 functions.
                local leaf = n:match(":([^:]+)$") or ""
                local low = leaf:lower()
                local signature = low:find("unlock",1,true)
                    or low:find("cosmetic",1,true)
                    or low:find("owned",1,true)
                    or low:find("reward",1,true)
                    or low:find("inventory",1,true)
                    or low:find("acquir",1,true)
                    or low:find("entitle",1,true)
                if signature and signatures < 24 then
                    signatures = signatures + 1
                    local okp, ep = pcall(function()
                        fn:ForEachProperty(function(prop)
                            local okname, property_name = pcall(function()
                                return prop:GetFName():ToString()
                            end)
                            if okname then
                                log("H27_PARAM function=" .. n
                                    .. " name=" .. tostring(property_name)
                                    .. " type=" .. full(prop))
                            end
                        end)
                    end)
                    if not okp then log("H27_PARAM_ERROR " .. n .. " err=" .. tostring(ep)) end
                end
            end)
        end)
        if not okf then log("H27_FUNCTION_ERROR " .. entry.name .. " err=" .. tostring(ef)) end
        local okp, ep = pcall(function()
            entry.obj:ForEachProperty(function(prop)
                if props >= 210 then return end
                local okn, propname = pcall(function() return prop:GetFName():ToString() end)
                if okn and relevant(propname) then
                    props = props + 1
                    log("H27_PROPERTY class=" .. entry.name
                        .. " property=" .. tostring(propname)
                        .. " type=" .. full(prop))
                end
            end)
        end)
        if not okp then log("H27_PROPERTY_ERROR " .. entry.name .. " err=" .. tostring(ep)) end
    end
    log("H27_UNLOCK_AUDIT_END classes=" .. tostring(#chosen)
        .. " functions=" .. tostring(funcs)
        .. " properties=" .. tostring(props)
        .. " signatures=" .. tostring(signatures)
        .. " mutated=0")
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
    if op == "METHOD_C" or op == "DUMP_MATERIALS" then
        dump_materials()
        unlock_audit()
        return
    end
    if op == "UNLOCK_AUDIT" or op == "AUDIT_UNLOCK" then unlock_audit(); return end
    if op == "PING" then log("PONG H27"); return end
    log("H23_UNKNOWN_COMMAND " .. op)
end

do
    local f = io.open(LOG_PATH, "w")
    if f then f:write(""); f:close() end
end
log("V0.6H27 Native Unlock Audit / F1 overlay starting (H25 base)")
log("H27_BOOT_MARKER=OK")
log("H24_NO_HOOKS=TRUE")
log("H23_METHOD_A=Apply MacrosCosmetic materials via class hierarchy/direct call")
log("H23_METHOD_B=Restore captured materials")
log("H27_METHOD_C=Dump materials + refined read-only inventory/unlock metadata audit")

LoopAsync(250, function()
    local cmd = read_command()
    if cmd ~= nil then
        ExecuteInGameThread(function()
            local ok, err = pcall(function() process_command(cmd) end)
            if not ok then log("H23_COMMAND_FATAL " .. tostring(err)) end
        end)
    end
end)
