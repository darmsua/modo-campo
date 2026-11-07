# Modo Campo — Toolbox-OT (visor de activos cifrado)

App web (PWA) para **consultar en campo** la ficha de un activo OT **sin portátil**: escaneas el
**QR** del equipo (que solo lleva el **código**) y la app muestra sus datos, leídos de una base de
datos **cifrada y firmada** que abres con **tu certificado** (`.p12`). Todo **offline**.

## Qué incluye este paquete

```
index.html            La app (visor Modo Campo)
fv_bundle.js          Motor cripto+QR (PKI.js + forge + jsQR) — offline, sin CDN
manifest.webmanifest  Metadatos PWA (instalable)
sw.js                 Service worker (funciona sin conexión)
icon-192.png/512.png  Iconos
empaquetar.sh         Script del PROFESOR: firma + cifra el inventario -> .p7
GUIA_XCA_alumnos.md   Práctica de PKI con XCA (generar certificados)
demo/                 Ejemplo listo para probar (ver abajo)
```

## Probar ya (carpeta `demo/`)

Necesitas servir la carpeta por **HTTPS** (la cámara y la instalación PWA lo exigen). Opciones:

- **GitHub Pages** (recomendado): sube esta carpeta a un repo público → *Settings → Pages →
  Deploy from a branch → main / root*. Abre la URL `https://TU_USUARIO.github.io/modo-campo/`.
- **Local (sin cámara):** `python3 -m http.server` y abre `http://localhost:8000`. En `localhost`
  el descifrado funciona; la **cámara** solo va por HTTPS, pero puedes usar el **código manual**.

Con la app abierta:
1. **Identidad** → `demo/alumno1.p12`, contraseña **`1234`**.
2. **Base de datos** → `demo/inventario_demo.p7`.
3. **Consultar** → teclea `A001` o `A010` (o escanea un QR con ese código).

> Los certificados de `demo/` son de **prueba** (CA de ejemplo). Para uso real, genera los tuyos
> con **XCA** siguiendo `GUIA_XCA_alumnos.md` y vuelve a empaquetar con `empaquetar.sh`.

## Flujo real (resumen)

1. **Alumnos**: generan clave + CSR en XCA → el **profesor (CA)** firma → obtienen su `.crt` y
   exportan su `.p12` (clave + cert + CA).
2. **Profesor**: exporta el proyecto de Análisis de Riesgo a `inventario.json` y ejecuta:
   ```bash
   ./empaquetar.sh inventario.json inventario.p7 profesor.crt profesor.key ca.crt alumno1.crt alumno2.crt …
   ```
   Reparte `inventario.p7` (va cifrado; no es secreto).
3. **En campo**: cada alumno abre Modo Campo, importa su `.p12`, carga `inventario.p7` y consulta.

## Seguridad (y por qué está así)

- **El QR solo lleva el código** (p. ej. `A001`). Ningún dato sensible viaja en la pegatina: así no
  se regala reconocimiento de la red a quien pase al lado. Los datos viven en la base cifrada.
- **Cifrado** (confidencialidad): AES-256 + clave envuelta a cada alumno con **RSA-OAEP**. Solo
  quien tenga la **clave privada** correspondiente abre la base.
- **Firma** (autenticidad/integridad): el visor **verifica** que la base la firmó la **CA de clase**;
  si no, muestra aviso y **no enseña datos**. Detecta manipulación y suplantación.
- **La clave privada no se guarda**: el `.p12` se usa solo en memoria durante la sesión. Protégelo
  con buena contraseña; si se filtra (con su contraseña), se pierde la confidencialidad.
- Es un sistema **docente**: usa primitivas reales (X.509, CMS/PKCS#7, AES-GCM/CBC, RSA-OAEP,
  ECDSA/RSA), pero no está pensado como producto de producción.

## Formato técnico

- Paquete = **CMS/PKCS#7**: `EnvelopedData` (cifrado a varios destinatarios) que contiene un
  `SignedData` (inventario firmado). Generado con **OpenSSL**; abierto en el navegador con **PKI.js**.
- `.p12` = **PKCS#12** (lo exporta XCA): clave privada + certificado + CA. Se lee con **forge**.

---
Inspirada por David de Armas Suárez (conecta3@hotmail.com) · Propulsada por Claude.ai · CC BY 4.0
