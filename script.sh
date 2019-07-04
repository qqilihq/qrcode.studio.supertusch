#!/bin/sh

set -e

# Change to script directory
cd "$(dirname "$0")"

# credentials for QR Code Studio
email=$QR_CODE_STUDIO_EMAIL
password=$QR_CODE_STUDIO_PASSWORD

# credentials for RapidAPI
rapid_api_key=$RAPID_API_KEY

# use `https://qrstud.io` or a custom domain
# (requires 'Whitelabel URL' feature)
domain='https://qrstud.io'

# your QR code logo design (used for two API requests)
design_config_json=$(cat <<-END
{
  "bgColor": "#FFFFFF",
  "body": "square",
  "bodyColor": "#000000",
  "crop": true,
  "darkColor": "#000000",
  "eye": "frame0",
  "eye1Color": "#000000",
  "eye2Color": "#000000",
  "eye3Color": "#000000",
  "eyeBall": "ball0",
  "eyeBall1Color": "#000000",
  "eyeBall2Color": "#000000",
  "eyeBall3Color": "#000000",
  "gradientColor1": null,
  "gradientColor2": null,
  "gradientOnEyes": true,
  "gradientType": "linear",
  "logoMode": "default"
}
END
)

# (0) login using `/api/authentication`
authentication_result_json=`curl \
  -X POST 'https://app.qrcode.studio/api/authentication' \
  -d "{ \"email\": \"${email}\", \"password\": \"${password}\" }" \
  -H 'Content-Type: application/json' \
  --silent --fail
`
# extract the `token` and `id` from JSON result using jq
token=`echo "${authentication_result_json}" | jq -r '.token'`
user_id=`echo "${authentication_result_json}" | jq -r '.id'`

echo "Logged in with ${email}: user id = ${user_id}"

# [loop] do this for every QR code to generate
echo "=== Starting (simulated) loop ==="

# the destination URL
destination_url='http://example.com'

# (1) generate a random identifier for the short URL
# (this must be 7 chars long, consisting of [a-z0-9], e.g. `pg7dz73`,
# and be generated client-side)
short_url_identifier=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 7 | head -n 1`

# the full tracking URL which will be put into the QR Code
full_tracking_url="${domain}/${short_url_identifier}"

# I’m just using the randomly generated identifier as name here;
# you’ll probably want to go for something more descriptive
name="${short_url_identifier}"


# (2) generate the QR Code using our public API
# https://www.qrcode-monkey.com/qr-code-api-with-logo
# and save it as file with the random identifier as name
custom_data=$(cat <<-END
{
  "config": ${design_config_json},
  "data": "${full_tracking_url}",
  "download": false,
  "file": "svg",
  "size": 400
}
END
)
output_file="${name}.svg"
curl \
  -X POST 'https://qrcode-monkey.p.mashape.com/qr/custom' \
  -d "${custom_data}" \
  -H "X-RapidAPI-Key: ${rapid_api_key}" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  --output "${output_file}" --silent --fail

echo "Wrote QR code to ${output_file}"

# (3) generate the entry to the dashboard using a (currently) private API
qrcodes_data=$(cat <<-END
{
  "name": "${name}",
  "alias": "${short_url_identifier}",
  "domain": "${domain}",
  "type": "url",
  "content": {
    "url": { "url": "${destination_url}" }
  },
  "static": false,
  "active": true,
  "design": {
    "type": "custom",
    "config": ${design_config_json}
  }
}
END
)

curl \
  -X POST "https://app.qrcode.studio/api/users/${user_id}/qrcodes?token=${token}" \
  -H 'Content-Type: application/json' \
  -d "${qrcodes_data}" \
  --silent --fail >> /dev/nul

echo "Added entry with name '${name}' to the QR Code Studio dashboard"
