local rn = require("racoonnet")
local sysutils = require("sysutils")
local component = require("component")
local io = require("io")
local filesystem = require("filesystem")
local thread = require("thread")
local event = require("event")
local card, err = rn.init(sysutils.readconfig("racoonnet"))
local config = {}
config.directory = "/www/"
local clientip, request, path
local str = require "string"
local key = ""

file_types = {}
file_types["html"] = "text/html"
local codes = {[302] = "Found", [400] = "Bad Request", [404] = "Not Found", [500] = "Internal Server Error"}

if not card then
  sysutils.log("Ошибка подключения к сети: \""..err.."\"!", 4, "webserver")
  return
end
function senderror(code)
  key = ""
    while #key < 16 do
    key = key..card.ip
    end
    Ckey = str.sub(key,1,16)
    print(key)
  local codestr = code.." "..codes[code]
  local html = "<html><body>"..codestr.."</body></html>"
  local str = "HTTP/1.1 "..codestr.."\nContent-Type: text/html\nContent-Length:"..html:len().."\n\n"..html
    edata = component.data.encrypt(str,Ckey,Ckey)
    print(edata)
    --on.send(clientip,edata)
    print("senderr")

    card:send(clientip, edata)
end

function redirect(redirto)
  local resp = "HTTP/1.1 302 Found\nLocation: "..redirto.."\n\n";
    while #key < 16 do
    key = key..card.ip
    end
    Ckey = str.sub(key,1,16)
    print(key)

    print("redirect")
    card:send(clientip, component.data.encrypt(resp,Ckey,Ckey))
  --card:send(clientip, component.data.encode64(resp))
end

function response()
  clientip, request = card:receive()
  if request:sub(1,3) == "GET" then
    sysutils.log("Получен запрос. IP: \""..clientip.."\".", 1, "webserver")
    path = request:match("GET .* HTTP/"):sub(5,request:match("GET .* HTTP/"):len()-6):gsub("[\n ]","")
    if path == nil then senderror(400) return end
    if path:match("%.%.") then senderror(400) return end
    local fpath = filesystem.concat(config.directory, path)
    if filesystem.exists(fpath) == false then senderror(404) return end
    if filesystem.isDirectory(fpath) then 
	  if path:sub(-1) ~= "/" then redirect(filesystem.concat(card.ip, path).."/") return end
      if filesystem.exists(filesystem.concat(fpath, "index.html")) then
	    redirect(card.ip..filesystem.concat(path, "index.html"))
		return
	  else
	    local fcontent = "<html><body>Индекс \""..path.."\":<br><a href=\"../\">../</a><br>"
		for name in filesystem.list(fpath)do
		  fcontent = fcontent.."<a href=\"./"..name.."\">"..name.."</a><br>"
		end
		fcontent = fcontent.."</body></html>"
	    local resp = "HTTP/1.1 200 OK\nContent-Type: text/html\nContent-Length: "..fcontent:len().."\n\n"..fcontent;
    while #key < 16 do
    key = key..card.ip
    end
    Ckey = str.sub(key,1,16)
    --print(key)

    print("resp")
    card:send(clientip, component.data.encrypt(resp,Ckey,Ckey))
		return
	  end
	else
	  if path:sub(-1) == "/" then redirect(filesystem.concat(card.ip, path)) return end
	end
    local file = io.open(fpath, "r")
    local fcontent = file:read("*a")
	if file_types[path:match("%.([%a%d]*)")] ~= nil then
      ftype = file_types[path:match("%.([%a%d]*)")]
    else
      ftype = "text/plain"
    end
    local resp = "HTTP/1.1 200 OK\nContent-Type: "..ftype.."\nContent-Length: "..fcontent:len().."\n\n"..fcontent;
    key = ""
    while #key < 16 do
    key = key..card.ip
    end
    Ckey = str.sub(key,1,16)
    print("resp1")
    --print(Ckey)
    --print(#key)
    --print(#Ckey)
    card:send(clientip, component.data.encrypt(resp,Ckey,Ckey))
  end
end

sysutils.log("Запущен WEB сервер. IP: \""..card.ip.."\".", 0, "webserver")

function server()
  while true do
    response()
  end
end

local t = thread.create(server)

while true do
  ev = {event.pull(_, "key_down")}
  local key=ev[4]
  if key==16 then --Q
    t:kill()
	break
  end
end