# PenguinPlay

An AirPlay receiver app for Linux and Windows. The desktop app manages [UxPlay](https://github.com/FDH2/UxPlay), which receives mirrored video with audio as well as AirPlay-only audio.

![PenguinPlay desktop app in dark mode](docs/screenshots/penguinplay-dark.png)

## Run in development

```sh
npm start
```

Open <http://127.0.0.1:4173>. Development uses Electron and electron-builder; the packaged AppImage does not require a system-wide Node.js installation. UxPlay is installed at `~/.local/bin/uxplay` on the development machine.

## Desktop application

Build and install the AppImage:

```sh
npm ci
npm run dist
./scripts/install-appimage.sh
```

The installer places the AppImage in `~/.local/opt/penguinplay`, registers a desktop entry in `~/.local/share/applications`, and installs the icon. Caelestia indexes that entry in its Meta+Space launcher. The desktop window starts the local server automatically and stops UxPlay when it closes.

## Run on Windows 10/11

PenguinPlay's Electron desktop UI runs on Windows. The Windows host also needs a Windows build of UxPlay and GStreamer; the Linux AppImage is not used on Windows.

### Build UxPlay

1. Install [MSYS2](https://www.msys2.org/), then open the **MSYS2 UCRT64** terminal from the Start menu.
2. Update MSYS2 when prompted, reopen UCRT64, then install the compiler and media dependencies:

```sh
pacman -Syu
```

If the terminal closes after the core update, reopen **MSYS2 UCRT64** and run:

```sh
pacman -S --needed git mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-pkgconf mingw-w64-ucrt-x86_64-libplist mingw-w64-ucrt-x86_64-gstreamer mingw-w64-ucrt-x86_64-gst-plugins-base mingw-w64-ucrt-x86_64-gst-plugins-good mingw-w64-ucrt-x86_64-gst-plugins-bad mingw-w64-ucrt-x86_64-gst-libav
```

3. Build the current UxPlay source with its built-in mDNS responder, so a separate Bonjour SDK/service is not required:

```sh
git clone https://github.com/FDH2/UxPlay.git
cd UxPlay
cmake -S . -B build -G Ninja -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" -DUSE_MDNS=1
cmake --build build
cmake --install build
```

The executable should be at `C:\msys64\ucrt64\bin\uxplay.exe`. UxPlay's built-in mDNS option is available in v1.74 and later; if building an older version, follow UxPlay's Bonjour SDK instructions instead.

### Install and run PenguinPlay

Install [Node.js LTS](https://nodejs.org/) for Windows. In the **MSYS2 UCRT64** terminal, clone this repository and install its npm dependencies:

```sh
git clone https://github.com/JonayMr/PenguinPlay.git
cd PenguinPlay
npm ci
```

Start the desktop app from the same UCRT64 terminal so Electron inherits the GStreamer runtime environment and finds `uxplay.exe` on `PATH`:

```sh
npm run desktop
```

The desktop UI launches UxPlay when you press **Start receiver**. You can also run the web UI in development with `npm start` and open <http://127.0.0.1:4173>. The `npm run dist` AppImage target is Linux-only; a signed Windows installer is not currently provided.

### Windows Firewall and network

Allow inbound AirPlay traffic only on a trusted **Private** network. Open **PowerShell as Administrator** and run the following, adjusting the executable path if MSYS2 was installed elsewhere:

```powershell
$uxplay = "C:\msys64\ucrt64\bin\uxplay.exe"
New-NetFirewallRule -DisplayName "PenguinPlay mDNS" -Direction Inbound -Program $uxplay -Protocol UDP -LocalPort 5353 -RemoteAddress LocalSubnet -Profile Private -Action Allow
New-NetFirewallRule -DisplayName "PenguinPlay AirPlay TCP" -Direction Inbound -Program $uxplay -Protocol TCP -LocalPort 35000-35002 -RemoteAddress LocalSubnet -Profile Private -Action Allow
New-NetFirewallRule -DisplayName "PenguinPlay AirPlay UDP" -Direction Inbound -Program $uxplay -Protocol UDP -LocalPort 35000-35002 -RemoteAddress LocalSubnet -Profile Private -Action Allow
```

Keep the iPhone/iPad and Windows PC on the same local Wi-Fi/network; guest Wi-Fi and client isolation prevent discovery. If Windows Firewall prompts when UxPlay first starts, allow it on **Private networks** only. The receiver uses mDNS on UDP 5353 and TCP/UDP ports 35000–35002.

On another Arch Linux system, install the system dependencies and build UxPlay for your user:

```sh
sudo pacman -S --needed git cmake gcc pkgconf openssl libplist avahi gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav
./scripts/install-uxplay.sh
```

Avahi must be enabled to advertise the receiver on the local network:

```sh
sudo systemctl enable --now avahi-daemon
```

## Connect an iPhone or iPad

1. Connect the iOS device and Linux host to the same Wi-Fi network. Guest networks with client isolation will not work.
2. Start the receiver and wait for the iPhone to connect.
3. On iOS, open Control Center, tap **Screen Mirroring**, and select the configured receiver name.
4. To send audio only, select the receiver from the AirPlay picker in a compatible app.

The firewall must allow mDNS (UDP 5353) and UxPlay's AirPlay ports. PenguinPlay fixes the TCP/UDP range `35000–35002` so firewall rules remain stable between launches; the service is advertised on TCP `35001`. To restrict UFW to your local network, replace the quoted interface and subnet values below with those for your host. Find them with `ip -brief address` and `ip route` (IPv6 routes are shown by `ip -6 route`):

```sh
export LAN_INTERFACE="YOUR_INTERFACE"
export LAN_IPV4_CIDR="YOUR_IPV4_SUBNET/CIDR"
export LAN_IPV6_CIDR="YOUR_IPV6_PREFIX/CIDR"
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV4_CIDR" to any port 5353 proto udp
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV4_CIDR" to any port 35000:35002 proto tcp
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV4_CIDR" to any port 35000:35002 proto udp
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV6_CIDR" to any port 5353 proto udp
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV6_CIDR" to any port 35000:35002 proto tcp
sudo ufw allow in on "$LAN_INTERFACE" from "$LAN_IPV6_CIDR" to any port 35000:35002 proto udp
sudo ufw status numbered
```

Set `LAN_INTERFACE`, `LAN_IPV4_CIDR`, and `LAN_IPV6_CIDR` to your interface name and local network prefixes before running those commands. To confirm that the iPhone/iPad is on the same LAN, connect it to the same Wi-Fi/router as this host. Avoid guest Wi-Fi or client isolation. If the receiver appears in Screen Mirroring but iOS reports “Unable to connect,” check the firewall rules first.

## Compatibility

- Uses the legacy AirPlay mirroring protocol supported by UxPlay. It does not implement every AirPlay 2 feature or multi-room audio.
- Screen mirroring carries H.264 video and AAC audio; dedicated audio mode supports ALAC.
- DRM-protected video, such as content from the Apple TV app, cannot be decrypted.
- Direct HLS streaming depends on app-specific support (for example, YouTube). Use **Screen Mirroring** for general video.
- Discovery requires the same local network and mDNS/Avahi; this app does not create a peer-to-peer connection outside that network.

The control interface listens only on `127.0.0.1`. UxPlay/GStreamer process the stream and audio on the host; media does not pass through the browser.

## Performance

At startup, PenguinPlay requests up to 60 FPS and lets GStreamer automatically choose a decoder and video output compatible with the current graphics session. Normal audio/video synchronization remains enabled. The 60 FPS value is a request to the iPhone, not a guarantee; actual performance also depends on the content and sending device.