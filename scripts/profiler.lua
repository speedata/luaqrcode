local profiler = {
    running = false,
    data = {}
}

local clock = os.clock

local function hook(event)
    local info = debug.getinfo(2, "nS")  -- 2 = caller, n = name, S = source
    if not info then return end

    local key = string.format("%s:%s:%d",
        info.short_src or "unknown",
        info.name or "<anonymous>",
        info.linedefined or 0
    )

    local entry = profiler.data[key]
    if not entry then
        entry = { calls = 0, time = 0, last = 0 }
        profiler.data[key] = entry
    end

    if event == "call" then
        entry.calls = entry.calls + 1
        entry.last = clock()
    elseif event == "return" then
        if entry.last ~= 0 then
            entry.time = entry.time + (clock() - entry.last)
            entry.last = 0
        end
    end
end

function profiler.start()
    if profiler.running then return end
    profiler.running = true
    debug.sethook(hook, "cr")  -- c = call, r = return
end

function profiler.stop()
    if not profiler.running then return end
    profiler.running = false
    debug.sethook()
end

function profiler.report(limit)
    limit = limit or 30
    local list = {}

    for key, entry in pairs(profiler.data) do
        list[#list+1] = {
            key = key,
            calls = entry.calls,
            time = entry.time
        }
    end

    table.sort(list, function(a,b)
        return a.time > b.time
    end)

    print(string.format("%-50s %10s %10s", "Function", "Calls", "Time (s)"))
    print(("="):rep(76))

    local n = math.min(limit, #list)
    for i = 1, n do
        local e = list[i]
        print(string.format("%-50s %10d %10.6f", e.key, e.calls, e.time))
    end
end

return profiler
