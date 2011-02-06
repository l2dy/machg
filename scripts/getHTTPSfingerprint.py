#!/usr/bin/python
# syntax : getHTTPSfingerprint host port
import ssl, sys
from hashlib import sha1

if (len(sys.argv) != 3):
	print 'getHTTPSfingerprint needs two arguments!'
	sys.exit(1)

def genfingerprint(host, port):
		pem = ssl.get_server_certificate( (host,port) )
		der = ssl.PEM_cert_to_DER_cert(pem)
		hash = sha1(der).hexdigest()
		pretty = ":".join([hash[x:x + 2] for x in xrange(0, len(hash), 2)])
		return pretty

print genfingerprint(sys.argv[1], int(sys.argv[2]))