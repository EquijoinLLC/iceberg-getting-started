#!/bin/bash

if ! output=$(curl -X POST -H "Polaris-Realm: default-realm" "http://polaris:8181/api/catalog/v1/oauth/tokens" \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=s3cr3t" \
  -d "scope=PRINCIPAL_ROLE:ALL"); then
  logred "Error: Failed to retrieve bearer token"
  exit 1
fi

token=$(echo "$output" | awk -F\" '{print $4}')

if [ "$token" == "unauthorized_client" ]; then
  logred "Error: Failed to retrieve bearer token"
  exit 1
fi

PRINCIPAL_TOKEN=$token

# Use local filesystem by default
curl -i -X POST -H "Authorization: Bearer $PRINCIPAL_TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' \
  http://polaris:8181/api/management/v1/catalogs \
  -d '{
        "catalog": {
          "name": "polaris",
          "type": "INTERNAL",
          "readOnly": false,
          "properties": {
            "default-base-location": "file:///tmp/polaris/"
          },
          "storageConfigInfo": {
            "storageType": "FILE",
            "allowedLocations": [
              "file:///tmp"
            ]
          }
        }
      }'

# Add TABLE_WRITE_DATA to the catalog's catalog_admin role since by default it can only manage access and metadata
curl -i -X PUT -H "Authorization: Bearer $PRINCIPAL_TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' \
  http://polaris:8181/api/management/v1/catalogs/polaris/catalog-roles/catalog_admin/grants \
  -d '{"type": "catalog", "privilege": "TABLE_WRITE_DATA"}'
