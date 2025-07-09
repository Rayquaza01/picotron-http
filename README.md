# Picotron HTTP Server

An HTTP Server in Picotron!

Running the cart will start a demo, hosting a server on `localhost:8000`. The cart will display the access logs. The site serves a form. Once submitted, the form results will be displayed in the log.

## `HTTPServer`

### `HTTPServer:New(port)`

Creates a new server, listening on port `port`. Errors if port can't be acquired.

### `HTTPServer:Update()`

Handles clients. Must be run in `_update` for the HTTP Server to function.

### `HTTPServer:Static(path)`

Sets a static path to serve from (default `.`)

### `HTTPServer:serveStaticPage(method, path, client)`

Serves a static page. `method` should be `HEAD` or `GET`. `path` is the path of the file to serve. `client` is an `HTTPSocket`

### `HTTPServer:GET(path, cb)`

Defines a callback for a specific path. The callback takes the arguments `client` (`HTTPSocket`), and `headers` (a table of headers).

`headers` includes `method`, `path`, and `queryString` along with whatever headers were included in the request.

### `HTTPServer:POST(path, cb)`

Defines a callback for a specific path. The callback takes the arguments `client` (`HTTPSocket`), `headers` (a table of headers), and `body` (the POST body).

`headers` includes `method`, `path`, and `queryString` along with whatever headers were included in the request.

## `HTTPSocket`

A wrapper around a socket.

### `HTTPSocket:Read()`

Reads from the socket, parsing the HTTP request.

Returns `headers` and `body` (or nil)

### `HTTPSocket:Write(data, headers, status)`

Writes an HTTP response to the socket.

`data` is the response body, `headers` are a table of additional headers for the response, and `status` is the HTTP status code.
