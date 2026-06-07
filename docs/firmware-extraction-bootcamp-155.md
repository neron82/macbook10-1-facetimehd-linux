# Extracting Boot Camp FaceTimeHD firmware 1.55

This repo does not redistribute Apple firmware. The working MacBook10,1 test used firmware and calibration files extracted from Apple's Boot Camp package.

## Source package

Reported working package:

```bash
wget http://swcdn.apple.com/content/downloads/32/09/041-89042-A_XVZ2U8XKG2/06ub1qfep6wv3g8bb68smwt3ac25xyng83/BootCampESD.pkg
```

## Extract package contents

Required tools vary by distro, commonly:

```bash
sudo apt install p7zip-full libarchive-tools unrar
```

Extraction:

```bash
7z x BootCampESD.pkg
bsdtar -xf Payload~ './Library/Application Support/BootCamp/WindowsSupport.dmg'
mv './Library/Application Support/BootCamp/WindowsSupport.dmg' ./WindowsSupport.dmg
7z e -y WindowsSupport.dmg 'BootCamp/Drivers/Apple/AppleCamera64.exe'
unrar e -o+ AppleCamera64.exe AppleCamera.sys
```

## Extract firmware and calibration files

```bash
dd bs=1 skip=86832 count=1417220 if=AppleCamera.sys of=firmware.bin
dd bs=1 skip=1511184 count=19040 if=AppleCamera.sys of=1871_01XX.dat
dd bs=1 skip=1530224 count=19040 if=AppleCamera.sys of=1874_01XX.dat
dd bs=1 skip=1549264 count=19040 if=AppleCamera.sys of=1771_01XX.dat
dd bs=1 skip=1568304 count=18048 if=AppleCamera.sys of=1674_01XX.dat
dd bs=1 skip=1586352 count=18048 if=AppleCamera.sys of=1675_01XX.dat
dd bs=1 skip=1604400 count=18048 if=AppleCamera.sys of=1671_01XX.dat
dd bs=1 skip=1622448 count=33072 if=AppleCamera.sys of=9112_01XX.dat
dd bs=1 skip=1655520 count=20080 if=AppleCamera.sys of=1222_01XX.dat
dd bs=1 skip=1675600 count=30240 if=AppleCamera.sys of=8221_01XX.dat
dd bs=1 skip=1705840 count=18656 if=AppleCamera.sys of=1571_01XX.dat
dd bs=1 skip=1724496 count=18672 if=AppleCamera.sys of=1575_01XX.dat
```

Verify firmware version:

```bash
strings firmware.bin | grep S2ISP
sha256sum firmware.bin *_01XX.dat
```

Expected firmware string:

```text
S2ISP-01.55.00
```

## Install firmware

```bash
sudo mkdir -p /lib/firmware/facetimehd
sudo cp firmware.bin *_01XX.dat /lib/firmware/facetimehd/
sync
```

## Important recovery note

If firmware experiments produce:

```text
Init failed! No wake signal
```

stop repeated module reloads. Restore a known source/firmware state and reboot or cold power-cycle. On the verified MacBook10,1, failed firmware boots could wedge the ISP until reboot, making later tests misleading.
