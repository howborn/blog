#!/bin/bash

dir='/var/www/ssl'
certs_dir="$dir/certs"

mkdir -p $certs_dir
cd $certs_dir

if [ -z "$SSL_DOMAINS" ]; then
    echo "### Domains is empty"
    exit 1
fi

echo "### Starting ssl ..."

openssl genrsa 4096 > account.key
openssl genrsa 4096 > domain.key

domains=`echo "DNS:$SSL_DOMAINS" | sed 's/,/&DNS:/g'`
echo "### Gen domain key, domains: $domains ..."
openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config \
    <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=$domains")) > domain.csr

echo "### Download acme_tiny script ..."
wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O acme_tiny.py

echo "### Gen chained cert ..."
python acme_tiny.py --account-key account.key --csr domain.csr --acme-dir $dir/challenges/ > signed.crt || exit
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat signed.crt intermediate.pem > chained.pem

echo "### End ssl ..."