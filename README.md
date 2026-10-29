# PenguinPlay

A local AirPlay receiver for Linux. The desktop app manages [UxPlay](https://github.com/FDH2/UxPlay), which receives mirrored video with audio as well as AirPlay-only audio.

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

The firewall must allow mDNS (UDP 5353) and UxPlay's AirPlay ports. PenguinPlay fixes the TCP/UDP range `35000–35002` so firewall rules remain stable between launches; the service is advertised on TCP `35001`. On the development host, the interface is `enp4s0`, the IPv4 network is `192.168.1.0/24`, and the local IPv6 prefix is `fdd0:7e7:91e0:401d::/64`. UFW has IPv6 enabled, so configure both address families:

```sh
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 5353 proto udp
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 35000:35002 proto tcp
sudo ufw allow in on enp4s0 from 192.168.1.0/24 to any port 35000:35002 proto udp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 5353 proto udp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 35000:35002 proto tcp
sudo ufw allow in on enp4s0 from fdd0:7e7:91e0:401d::/64 to any port 35000:35002 proto udp
sudo ufw status numbered
```

If your interface or subnet differs, replace these values with the ones shown by `ip -brief address` and `ip route`. To confirm that the iPhone/iPad is on the same LAN, it should be connected to the same Wi-Fi/router as this host (`192.168.1.x` or the local IPv6 prefix). Avoid guest Wi-Fi or client isolation. If the receiver appears in Screen Mirroring but iOS reports “Unable to connect,” check the firewall rules first.

## Compatibility

- Uses the legacy AirPlay mirroring protocol supported by UxPlay. It does not implement every AirPlay 2 feature or multi-room audio.
- Screen mirroring carries H.264 video and AAC audio; dedicated audio mode supports ALAC.
- DRM-protected video, such as content from the Apple TV app, cannot be decrypted.
- Direct HLS streaming depends on app-specific support (for example, YouTube). Use **Screen Mirroring** for general video.
- Discovery requires the same local network and mDNS/Avahi; this app does not create a peer-to-peer connection outside that network.

The control interface listens only on `127.0.0.1`. UxPlay/GStreamer process the stream and audio on the host; media does not pass through the browser.

## Performance

At startup, PenguinPlay requests up to 60 FPS and lets GStreamer automatically choose a decoder and video output compatible with the current graphics session. Normal audio/video synchronization remains enabled. The 60 FPS value is a request to the iPhone, not a guarantee; actual performance also depends on the content and sending device.