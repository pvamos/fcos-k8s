# HTTPS server in python 3
#   generate self-signed certificate with:
#   openssl req -new -x509 -keyout private.pem -out certificate.pem -days 365 -nodes 
#

from http.server import HTTPServer,SimpleHTTPRequestHandler
import ssl

httpsrv = HTTPServer(('', 4443), SimpleHTTPRequestHandler)
sslctx = ssl.SSLContext(protocol = ssl.PROTOCOL_TLS_SERVER, check_hostname = False)
sslctx.load_cert_chain(certfile='certificate.pem', keyfile='private.pem')
httpsrv.socket = sslctx.wrap_socket(httpsrv.socket, server_side=True)
httpsrv.serve_forever()

