mount_signer = function(signer)
    local path = auth_settings:get("lcmd")
    local newuser = auth_settings:get("newuser_addr")
    local mount = auth_settings:get("smount")
    write_file(path, "mount -A " .. newuser .. " " .. mount)
    local result = read_file(path)
    return result
end

read_file = function(path)
    local local_addr = auth_settings:get("local_addr")
    local port = auth_settings:get("local_addr_port")
    local tcp = socket:tcp()
    local connection, err = tcp:connect(local_addr, port)
    if (err ~= nil) then
        print("dump of error newest .. " .. dump(err))
        print("Connection error")
        return
    end
    local conn = np.attach(tcp, "root", "")
    local p = conn:newfid()
    np:walk(conn.rootfid, p, path)
    conn:open(p, 0)
    local READ_BUF_SIZ = 8000
    local offset = 0
    local content = nil
    local dt = conn:read(p, offset, READ_BUF_SIZ)
    content = tostring(dt)
    if dt ~= nil then offset = offset + #dt end
    while (true) do
        dt = conn:read(p, offset, READ_BUF_SIZ)
        if (dt == nil) then break end
        content = content .. tostring(dt)
        offset = offset + #(tostring(dt))
    end
    conn:clunk(p)
    conn:clunk(conn.rootfid)
    tcp:close()
    return content
end

write_file = function(path, content)
    local local_addr = auth_settings:get("local_addr")
    local port = auth_settings:get("local_addr_port")
    local tcp = socket:tcp()
    local connection, err = tcp:connect(local_addr, port)
    if (err ~= nil) then
        print("dump of error newest .. " .. dump(err))
        print("Connection error")
        return
    end
    local conn = np.attach(tcp, "root", "")
    local f = conn:newfid()
    local g = conn:newfid()
    conn:walk(conn.rootfid, f, path)
    conn:clone(f, g)
    conn:open(g, 2)
    
    local buf = data.new(content)
    local n = conn:write(g, 0, buf)
    if n ~= #buf then
        error("test: expected to write " .. #buf .. " bytes but wrote " .. n)
    end
    conn:clunk(g)
    conn:clunk(f)
    conn:clunk(conn.rootfid)
    tcp:close()
end

create_file = function(parent_path, filename)
    local local_addr = auth_settings:get("local_addr")
    local port = auth_settings:get("local_addr_port")
    local tcp = socket:tcp()
    local connection, err = tcp:connect(local_addr, port)
    if (err ~= nil) then
        print("dump of error newest .. " .. dump(err))
        print("Connection error")
        return
    end
    local conn = np.attach(tcp, "root", "")
    local f, g = conn:newfid(), conn:newfid()
    conn:walk(conn.rootfid, f, parent_path)
    conn:clone(f, g)
    conn:create(g, filename, 420, 1)
    conn:clunk(f)
    conn:clunk(g)
    conn:clunk(conn.rootfid)
    tcp:close()
end

get_privileges = function()
    local privileges = minetest.settings:get("default_privs")
    return minetest.string_to_privs(privileges)
end

getauthinfo = function(lcmd, signer, name, pass)
    if pass == nil then return end
    write_file(lcmd,
               "getauthinfo default " .. signer .. " " .. name .. " " .. pass)
    local response = read_file(lcmd)
    return response
end

get_privs = function(rcmd, name)
    write_file(rcmd, "cat /users/" .. name .. "/privs")
    local privs = read_file(rcmd)
    privs = minetest.string_to_privs(privs)
    return privs
end
