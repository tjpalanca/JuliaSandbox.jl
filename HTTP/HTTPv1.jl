"Exploration of HTTP v1 Release"
module HTTPv1

using HTTP
using Gumbo

# Client 

# GET requests
resp = HTTP.request("GET", "http://httpbin.org/ip")
resp = HTTP.get("http://httpbin.org/ip")
stat = resp.status
body = String(resp.body)

# POST requests
resp = HTTP.post("http://httpbin.org/post"; body="request body")
# form-urlencoded body
resp = HTTP.post("http://httpbin.org/post"; body=Dict("nm" => "val"))

# query parameters
resp = HTTP.get("http://httpbin.org/anything"; query=["hello" => "world"])

# websockets 
WebSockets.open("ws://websocket.org") do ws
    for msg in ws
        send(ws, resp)
    end
end

# Server 

# Authentication middleware
function auth(handler)
    return function(req)
        ident = parse_auth(req)
        if ident === nothing
            # failed to security authentication
            return HTTP.Response(401, "unauthorized")
        else
            # store parsed identity in request context for handler usage
            req.context[:auth] = ident
            # pass request on to handler function for further processing
            return handler(req)
        end
    end
end

# Client functionality and parsing
resp = HTTP.get("https://www.congress.gov.ph/legisdocs/?v=bills")
body = String(resp.body)
html = parsehtml(body)
children(children(html.root)[1])[29]

# Server functionality 

using HTTP

const ROUTER = HTTP.Router()

function square(req::HTTP.Request)
    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, OPTIONS"
    ]
    # handle CORS requests
    if HTTP.method(req) == "OPTIONS"
        return HTTP.Response(200, headers)
    end
    body = parse(Float64, String(req.body))
    square = body^2
    HTTP.Response(200, headers, string(square))
end

HTTP.register!(ROUTER, "POST", "/api/square", square)

server = HTTP.serve!(ROUTER, Sockets.localhost, 8888)

# usage
resp = HTTP.post("http://localhost:8888/api/square"; body="3")
sq = parse(Float64, String(resp.body))
@assert sq == 9.0

# close the server which will stop the HTTP server from listening
close(server)
@assert istaskdone(server.task)

end