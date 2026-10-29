# PenguinPlay

Receptor local de AirPlay para Linux. La app web administra [UxPlay](https://github.com/FDH2/UxPlay), que recibe duplicación de pantalla con imagen y sonido, además de audio AirPlay.

## Ejecutar

```sh
npm start
```

Abre <http://127.0.0.1:4173>. El modo de desarrollo usa Electron y electron-builder; el AppImage final no depende de una instalación global de Node. El receptor UxPlay está instalado en `~/.local/bin/uxplay` en el equipo de desarrollo.

## Aplicación de escritorio

Requiere Node.js/npm, las dependencias multimedia y UxPlay instalados en el sistema.

```sh
npm ci
npm run dist
./scripts/install-appimage.sh
```

El instalador coloca el AppImage en `~/.local/opt/penguinplay`, registra la entrada de escritorio en `~/.local/share/applications` y copia el icono. Caelestia detecta esa entrada para su launcher Meta+Espacio. La ventana de escritorio inicia el servidor local automáticamente y detiene UxPlay al cerrarse.

En otro Arch Linux, instala las dependencias de sistema y compila UxPlay para tu usuario:

```sh
sudo pacman -S --needed git cmake gcc pkgconf openssl libplist avahi gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav
./scripts/install-uxplay.sh
```

Avahi debe estar habilitado para anunciar el receptor en la red local:

```sh
sudo systemctl enable --now avahi-daemon
```

## Conectar desde iPhone o iPad

1. Conecta el dispositivo iOS y el equipo Linux a la misma Wi-Fi; las redes de invitados con aislamiento entre clientes no sirven.
2. Inicia el receptor y espera a que el iPhone se conecte.
3. En iOS, abre el Centro de control, toca **Duplicar pantalla** y selecciona el nombre configurado.
4. Para enviar solo audio, elige el receptor desde el selector AirPlay de una app compatible.

El cortafuegos debe permitir mDNS (UDP 5353) y los puertos AirPlay de UxPlay. PenguinPlay fija el bloque TCP/UDP `35000–35002` para que las reglas no cambien entre arranques; el servicio se anuncia por TCP `35001`. En este equipo la interfaz es `enp4s0`, la red IPv4 es `192.168.1.0/24` y el prefijo IPv6 local es `fdd0:7e7:91e0:401d::/64`. UFW tiene IPv6 habilitado, así que configura ambas familias:

```sh
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 5353 proto udp
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 35000:35002 proto tcp
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 35000:35002 proto udp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 5353 proto udp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 35000:35002 proto tcp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 35000:35002 proto udp
sudo ufw status numbered
```

Si tu interfaz o subredes son distintas, sustitúyelas por las que muestran `ip -brief address` y `ip route`. Para confirmar que iPhone/iPad comparte la LAN, debe estar conectado a la misma Wi-Fi/router que este equipo (`192.168.1.x` o el prefijo IPv6 local); evita una Wi-Fi de invitados o el aislamiento de clientes. Si el nombre aparece en “Duplicar pantalla” pero iOS muestra “Unable to connect”, comprueba primero las reglas del cortafuegos.

## Alcance

- Usa el protocolo de duplicación AirPlay heredado compatible con UxPlay. No implementa todas las funciones de AirPlay 2 ni audio multiroom.
- La duplicación de pantalla incluye video H.264 y audio AAC; el modo de audio dedicado admite ALAC.
- El video protegido por DRM, como contenido de Apple TV, no se puede descifrar.
- El streaming directo HLS desde apps depende de compatibilidad específica (por ejemplo, YouTube); para video general usa **Duplicar pantalla**.
- El descubrimiento requiere la misma red local y mDNS/Avahi; la función no establece una conexión punto a punto fuera de esa red.

La interfaz escucha únicamente en `127.0.0.1`. El stream y el audio se procesan en el propio host mediante UxPlay/GStreamer; no pasan por el navegador.

## Rendimiento

Al iniciar, PenguinPlay solicita hasta 60 FPS y deja que GStreamer seleccione automáticamente el decoder y la salida de vídeo compatibles con la sesión gráfica. La sincronización normal de audio y vídeo queda activa. El límite de 60 FPS es una petición al iPhone, no una garantía: el resultado también depende del contenido y del dispositivo emisor.