To generate the certs, and run project:

Check and change script env vars
-------------------------------
JAVA_HOME=/path/to/jdk

Optionally, change certs password (you have to change on src/main/resources/application.properties too)
----------------------------------
PFX_PASSWORD=password 


Generate scripts
----------------
cd ssl-script
chmod +x ./create-certificates-client-server.sh
./create-certificates-client-server.sh

Run locally with
----------------
cd ../sb2-soap-proxy-with-ssl-example
mvn spring-boot:run

go to
------
https://localhost:9443/service

# if 2 way SSL is enabled, this cannot be seen from browser, unless you add the cert

To test 1 way SSL:
-------------------
- Set value of property
server.ssl.client-auth=need

- Start server
mvn spring-boot:run

test request with ca cert with:
----------------------------------
curl --cacert ../ssl-script/ca.crt --data @soap-request.xml --header "Content-Type: text/xml;charset=UTF-8" https://localhost:9443/service/contract_first_order/

To test 2 way SSL:
-------------------
- Set value of property
server.ssl.client-auth=need

- Start server
mvn spring-boot:run

test bad request without certs with:
----------------------------------
curl --data @soap-request.xml --header "Content-Type: text/xml;charset=UTF-8" https://localhost:9443/service/contract_first_order/


test good request with certs with:
----------------------------------
curl --cacert ../ssl-script/ca.crt      --key ../ssl-script/client.key      --cert ../ssl-script/client.crt --data @soap-request.xml --header "Content-Type: text/xml;charset=UTF-8" https://localhost:9443/service/contract_first_order/