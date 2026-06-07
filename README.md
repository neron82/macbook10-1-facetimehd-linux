# MacBook10,1 FaceTimeHD Linux webcam fix

This repository documents and packages the working Linux FaceTimeHD webcam fix for the 2017 12-inch MacBook (`MacBook10,1`, board `Mac-EE2EBD4B90B839A8`).

The machine uses Apple's Broadcom 1570 PCIe FaceTimeHD camera. The upstream `patjak/facetimehd` driver historically assumes a 720p-ish path and public firmware that does not correctly identify the MacBook10,1 sensor. With the patches and firmware recipe here, the internal webcam works as a normal V4L2 device at 640x480 YUYV, including browser webcam tests.

## Verified result

Tested on:

- Model: `MacBook10,1` / 2017 12-inch MacBook
- Board: `Mac-EE2EBD4B90B839A8`
- Kernel: `6.17.0-35-generic`
- Driver base: `patjak/facetimehd`
- Firmware: Boot Camp `S2ISP-01.55.00`
- Sensor IDs: `0005/9774`
- Setfile: `1675_01XX.dat`
- Output: `640x480` YUYV, `614400` bytes/frame, ~30 fps

Observed working firmware log:

```text
Release : S2ISP-01.55.00
CH_INFO_GET ret=0 len=158 sensor ids 0005/9774 count=1
Loading set file facetimehd/1675_01XX.dat for sensor ids 0005/9774
Starting channel 0: requested 640x480, crop [0,0][640,480]
CROP -> [0, 0][640, 480] within [0, 0][848, 588]
New Output config -> format = 1, range 0, size = 640x480
```

Functional tests:

```text
single-frame capture: raw_size=614400, exit=0
30-frame smoke test: ~30 fps, bytesused=614400 per frame, exit=0
reopen-after-stop: raw_size=614400, exit=0
browser webcam test: successful video stream
```

## What was wrong

The fix appears to require all of these pieces together:

1. **Correct firmware**
   - Old public firmware `S2ISP-01.43.00` booted but reported `sensor ids 0000/0000` on this MacBook10,1.
   - Boot Camp firmware `S2ISP-01.55.00` identifies the sensor as `0005/9774` and loads `1675_01XX.dat`.

2. **480p driver path**
   - The 12-inch MacBook camera is 640x480, not 1280x720.
   - V4L2 defaults/max image size must be changed to 640x480.
   - The ISP crop command must also use 640x480. Advertising 640x480 to userspace is not enough if the firmware still receives a 720p crop.

3. **Apple ACPI CMPE power sequencing**
   - The camera ACPI device is at `\\_SB_.PCI0.RP10.CMRA`.
   - The PCI device ACPI handle is not sufficient; the driver must resolve the CMRA handle directly.
   - On this machine, skipping CMPE caused even old firmware to fail with `Init failed! No wake signal`.

4. **Timing / wedged ISP recovery**
   - Failed firmware experiments can wedge the ISP until reboot/cold reset.
   - If a known-good combination suddenly reports `No wake signal`, stop cycling patches and reboot before drawing conclusions.

## Upstream tracking

Upstream issue opened at `patjak/facetimehd`:

- https://github.com/patjak/facetimehd/issues/326

## Repository layout

- `patches/0001-macbook10-1-facetimehd-480p-fw155-support.patch` — current working patch against `patjak/facetimehd`.
- `docs/firmware-extraction-bootcamp-155.md` — how to extract the required Apple firmware/calibration files. No Apple firmware is redistributed here.
- `docs/test-results.md` — captured evidence from the working test session.
- `docs/upstream-issue-draft.md` — issue text prepared for `patjak/facetimehd`.
- `scripts/install-macbook10-1-fix.sh` — helper script to apply the patch to a local DKMS source tree and rebuild.

## Legal note about firmware

This repository does **not** include Apple's firmware or calibration files. It only documents how to extract them from Apple's Boot Camp package. You are responsible for ensuring you have the right to use the firmware on your hardware.

## Quick start

Assuming you already have `patjak/facetimehd` installed via DKMS under `/usr/src/facetimehd-0.7.0.1` and have extracted the Boot Camp 1.55 firmware files into `/lib/firmware/facetimehd/`:

```bash
git clone https://github.com/neron82/macbook10-1-facetimehd-linux.git
cd macbook10-1-facetimehd-linux
sudo ./scripts/install-macbook10-1-fix.sh /usr/src/facetimehd-0.7.0.1 0.7.0.1
sudo reboot
```

After reboot:

```bash
strings /lib/firmware/facetimehd/firmware.bin | grep S2ISP
v4l2-ctl --device=/dev/video0 --all
v4l2-ctl --device=/dev/video0 --stream-mmap=3 --stream-count=30 --stream-to=/dev/null --verbose
sudo dmesg | grep -Ei 'facetimehd|S2ISP|CH_INFO|sensor ids|set file|CROP|wake' | tail -120
```

Expected firmware string:

```text
S2ISP-01.55.00
```

Expected V4L2 format:

```text
Width/Height      : 640/480
Pixel Format      : 'YUYV'
Size Image        : 614400
```

## Status

This is a working field fix for one verified MacBook10,1. It should be treated as a reproducible hardware-specific fix and upstream lead, not yet a polished generic upstream patch for all FaceTimeHD devices.
