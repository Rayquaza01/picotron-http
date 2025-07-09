local HTTP_REASON_PHRASE = {
    [101] = "Switching Protocol",
    [200] = "OK",
    [400] = "Bad Request",
    [403] = "Forbidden",
    [404] = "Not Found",
    [418] = "I'm a teapot",
    [500] = "Internal Server Error",
    [501] = "Not Implemented"
}

local MIME_TYPES = {
    ["html"] = "text/html",
    ["js"]   = "text/javascript",
    ["css"]  = "text/css",
    ["json"] = "application/json",
    ["png"]  = "image/png",
    ["jpg"]  = "image/jpg",
    ["gif"]  = "image/gif",
    ["svg"]  = "image/svg+xml",
    ["wav"]  = "audio/wav",
    ["mp4"]  = "video/mp4",
    ["woff"] = "application/font-woff",
    ["ttf"]  = "application/font-ttf",
    ["eot"]  = "application/vnd.ms-fontobject",
    ["otf"]  = "application/font-otf",
    ["wasm"] = "application/wasm",
    ["*"]     = "application/octet-stream"
}

local function getReasonString(status)
    return tostr(status) .. " " .. HTTP_REASON_PHRASE[status];
end

local function GMTString()
    return date("!%a, %d %b %Y %H:%M:%S GMT")
end

--- @class HTTPSocket
--- @field socket any
local HTTPSocket = {}

function HTTPSocket:New(s)
    local o = {
        socket = s
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

--- Reads an HTTP request
--- @return table | nil, string | nil
function HTTPSocket:Read()
    local res = self.socket:read()
    if type(res) == "string" and (res:find("^GET") or res:find("^POST") or res:find("^HEAD")) then
        local lines = split(res:gsub("\r\n", "\n"), "\n", false)

        local method, path = table.unpack(split(lines[1], " ", false))
        local realPath, queryString = table.unpack(split(path, "?", false))

        local headers = {}
        headers.searchParams = queryString
        headers.method = method
        headers.path = realPath

        for i = 2, #lines, 1 do
            if lines[i] == "" then
                break
            end

            local c = lines[i]:find(":", 1, true)
            if c then
                headers[sub(lines[i], 1, c - 1)] = sub(lines[i], c + 2, #lines[i])
            end
        end

        local postData = ""

        if method == "POST" and headers["Content-Length"] then
            local startOfData = res:find("\r\n\r\n") + 4
            postData = sub(res, startOfData)
        end

        return headers, postData
    end

    return nil, nil
end

--- Writes an HTTP response
--- @param data string | integer
--- @param headers table
--- @param status integer
function HTTPSocket:Write(data, headers, status)
    local response = "HTTP/1.1 " .. getReasonString(status) .. "\r\n"
    for k, v in pairs(headers) do
        response = response .. k .. ": " .. v .. "\r\n"
    end
    response = response .. "Date: " .. GMTString() .. "\r\n"
    response = response .. "Connection: Keep-Alive\r\n"
    if type(data) == "number" then
        response = response .. "Content-Length: " .. tostr(data) .. "\r\n"
    else
        response = response .. "Content-Length: " .. #data .. "\r\n"
    end

    response = response .. "\r\n"

    if type(data) == "string" then
        response = response .. data
    end

    self.socket:write(response)
end

--- @class HTTPServer
--- @field listener any
--- @field clients table
--- @field getHandlers table
--- @field postHandlers table
--- @field staticPath string
--- @field log table
local HTTPServer = {}

--- @param port integer
function HTTPServer:New(port)
    local o = {
        listener = socket("tcp://*:" .. tostr(port)),
        clients = {},
        getHandlers = {},
        postHandlers = {},
        staticPath = ".",
        log = {}
    }

    if not o.listener then
        error("Could not open server on port " .. tostr(port))
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function HTTPServer:Update()
    if self.listener then
		local new_client = self.listener:accept()
		if new_client then
			add(self.clients, HTTPSocket:New(new_client))
		end

		for client in all(self.clients) do
			local dat, post = client:Read()
			if dat then
                add(self.log, string.format("%s %s %s", GMTString(), dat.method, dat.path))

                local handler = nil

                if dat.method == "GET" or dat.method == "HEAD" then
                    handler = self.getHandlers[dat.path]
                elseif dat.method == "POST" then
                    handler = self.postHandlers[dat.path]
                end

                if handler then
                    handler(client, dat, post)
                else
                    if dat.method == "GET" or dat.method == "HEAD" then
                        self:serveStaticPage(dat.method, dat.path, client)
                    else
                        client:Write(getReasonString(403), {}, 403)
                    end
                end
			end
		end
    end
end

--- Add GET handler for a path
--- cb takes arguments HTTPSocket, Headers
--- @param path string
--- @param cb function
function HTTPServer:GET(path, cb)
    self.getHandlers[path] = cb
end

--- Add GET handler for a path
--- cb takes arguments HTTPSocket, Headers, Post Data
--- @param path string
--- @param cb function
function HTTPServer:POST(path, cb)
    self.postHandlers[path] = cb
end

--- Set the static path
--- @param path string
function HTTPServer:Static(path)
    self.staticPath = path
end

--- Serve a static page, relative to the static path
--- @param method string
--- @param path string
--- @param client HTTPSocket
function HTTPServer:serveStaticPage(method, path, client)
    if path == "/" then
        path = "/index.html"
    end

    local filepath = self.staticPath .. path
    local t, s, o = fstat(filepath)

    if t == "file" then
        local data = ""

        if method == "HEAD" then
            data = s
        else
            data = fetch(filepath)
        end

        local mime = MIME_TYPES[filepath:ext()] or MIME_TYPES["*"]

        client:Write(data, { ["Content-Type"] = mime }, 200)
    else
        client:Write(getReasonString(404), {}, 404)
    end
end

return HTTPServer
