# ca key and cert

openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1024 -out ca.pem -subj "/CN=App"

# server key and cert

openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -config openssl.cnf
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 500 -sha256 -extfile openssl.cnf -extensions req_ext

# client key and cert

openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=Client"
openssl x509 -req -in client.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out client.crt -days 500 -sha256

# start server

go run server.go

# test with curl

curl --cert client.crt --key client.key --cacert ca.pem https://localhost:8443/
docker run --rm --platform linux/amd64 -v "$(pwd)":/root -w /root racket/racket:8.5 curl --cert client.crt --key client.key --cacert ca.pem https://host.docker.internal:8443/

# test with racket

docker run --rm --platform linux/amd64 -v "$(pwd)":/root -w /root racket/racket:8.5 racket client.rkt
