#!/usr/bin/env bash
# ------------------------------------------------------------------
# Toolbox-OT · Empaquetar inventario (FIRMA + CIFRA) en formato CMS/PKCS#7
# El profesor firma el inventario con la clave de la CA/profesor y lo cifra
# para los certificados de los alumnos autorizados. El paquete .p7 solo lo
# pueden abrir esos alumnos (con su .p12), y el visor verifica la firma.
#
# Uso:
#   ./empaquetar.sh <inventario.json> <salida.p7> <profesor.crt> <profesor.key> <ca.crt> <alumno1.crt> [alumno2.crt ...]
#
# Requisitos: OpenSSL 1.1.1+ / 3.x
# ------------------------------------------------------------------
set -euo pipefail
if [ "$#" -lt 6 ]; then
  echo "Uso: $0 <inventario.json> <salida.p7> <profesor.crt> <profesor.key> <ca.crt> <alumno1.crt> [alumno2.crt ...]" >&2
  exit 1
fi
IN="$1"; OUT="$2"; TCRT="$3"; TKEY="$4"; CA="$5"; shift 5
RECIPS=("$@")
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
# 1) Firmar con el certificado del profesor (se incrusta la cadena con la CA)
openssl cms -sign -binary -in "$IN" -signer "$TCRT" -inkey "$TKEY" -certfile "$CA" \
  -outform DER -nodetach -out "$TMP"
# 2) Cifrar a todos los alumnos. RSA-OAEP (compatible con navegador) + AES-256-CBC.
#    Cada destinatario necesita su propio -recip ... -keyopt (padding OAEP).
ARGS=()
for CERT in "${RECIPS[@]}"; do
  ARGS+=(-recip "$CERT" -keyopt rsa_padding_mode:oaep -keyopt rsa_oaep_md:sha256)
done
openssl cms -encrypt -binary -in "$TMP" -outform DER -aes-256-cbc -out "$OUT" "${ARGS[@]}"
echo "OK -> $OUT  (firmado por $(basename "$TCRT") · cifrado a ${#RECIPS[@]} alumno/s)"
