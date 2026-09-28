#!/bin/bash

CLOUDFLARE_API_TOKEN="xxxxx"
ZONE_ID="xxxx"
DNS_RECORD_ID="xxxxxxx"
DNS_RECORD_NAME="domain.co.uk"
DNS_RECORD_TYPE="A"

# Define the full paths to commands to be able run this script with cron
CURL="/usr/bin/curl"
JQ="/usr/bin/jq"

# Get the current public IP address
IP=$($CURL -s http://ipv4.icanhazip.com | tr -d '\n')

# Cloudflare API endpoint to get the current DNS record
GET_API_ENDPOINT="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID"

# Get the current DNS record's IP address from Cloudflare
current_ip=$($CURL -s -X GET "$GET_API_ENDPOINT" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" | $JQ -r '.result.content')

echo "Fetched IP: '$IP'"
echo "Current DNS IP: '$current_ip'"
echo "Fetched IP bytes: $(echo -n "$IP" | od -c)"
echo "Current DNS IP bytes: $(echo -n "$current_ip" | od -c)"
IP=$($CURL -s http://ipv4.icanhazip.com | tr -d '\r\n[:space:]')
current_ip=$(echo "$current_ip" | tr -d '\r\n[:space:]')


# Check if the IP addresses are different
if [[ "$IP" == "$current_ip" ]]; then
  echo "No update needed. IP address has not changed: $IP"
else
  echo "IP address has changed from $current_ip to $IP. Updating record..."

  # Cloudflare API endpoint to update the DNS record
  UPDATE_API_ENDPOINT="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID"

  # Update the DNS record
  response=$($CURL -s -X PUT "$UPDATE_API_ENDPOINT" \
       -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
       -H "Content-Type: application/json" \
       --data '{
         "type": "'"$DNS_RECORD_TYPE"'",
         "name": "'"$DNS_RECORD_NAME"'",
         "content": "'"$IP"'",
         "ttl": 120,
         "proxied": false
       }')

  # Check if the update was successful
  if [[ $response == *"\"success\":true"* ]]; then
    echo "DNS record updated successfully to IP: $IP"
  else
    echo "Failed to update DNS record. Response: $response"
  fi
fi
