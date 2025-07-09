--[[pod_format="raw",created="2024-03-15 13:58:36",modified="2025-07-09 14:12:09",revision=31,xstickers={}]]
-- name of cart v1.0
-- by Arnaught

local HTTPServer = include("http.lua")

function _init()
    window(256, 128)
    Server = HTTPServer:New(8000)

    Server:Static("./static")

    Server:POST("/form", function(client, headers, body)
        add(Server.log, string.format("Form Response: %s", body))
        Server:serveStaticPage("GET", "/form.html", client)
    end)
end

function _update()
    Server:Update()
end

function _draw()
	cls()
    print("Running HTTP Server on localhost:8000")
    for i = #Server.log, 1, -1 do
        print(Server.log[i])
    end
end
