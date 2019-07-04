# QR Code Studio API Example

Demonstrate how to use the public API for generating QR codes with a currently private API for adding them to the dashboard.

To run with Docker:

```
$ docker build -t qrcode.studio.supertusch .
$ docker run -it --rm -v $(pwd):/script \
    -e QR_CODE_STUDIO_EMAIL='…' \
    -e QR_CODE_STUDIO_PASSWORD='…' \
    -e RAPID_API_KEY='…' \
    qrcode.studio.supertusch /script/script.sh
```
