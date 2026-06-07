# MacBook10,1 FaceTimeHD - Boot Camp firmware 1.55 working status

Date: 2026-06-07
Kernel: 6.17.0-35-generic
Machine: MacBook10,1 / board Mac-EE2EBD4B90B839A8

## Current working combination

- DKMS module: `/lib/modules/6.17.0-35-generic/updates/dkms/facetimehd.ko.zst`
- DKMS srcversion: `96DFEB75D38472AC0CF850B`
- DKMS source: `/usr/src/facetimehd-0.7.0.1`
- Firmware installed: `/lib/firmware/facetimehd/firmware.bin`
- Firmware version: `S2ISP-01.55.00`
- Calibration files installed in `/lib/firmware/facetimehd/`:
  - `1222_01XX.dat`
  - `1571_01XX.dat`
  - `1575_01XX.dat`
  - `1671_01XX.dat`
  - `1674_01XX.dat`
  - `1675_01XX.dat`
  - `1771_01XX.dat`
  - `1871_01XX.dat`
  - `1874_01XX.dat`
  - `8221_01XX.dat`
  - `9112_01XX.dat`

## Driver patches retained

- 12-inch MacBook 480p path:
  - V4L2 defaults/max format set to 640x480.
  - ISP crop set to `[0,0][640,480]` for 640x480.
- ACPI CMPE power-on retained.
  - Skipping CMPE made even old 1.43 firmware fail to wake.
- Setfile handling made non-fatal and safer.
  - Avoids panic-prone stale `set_file` behavior.
  - Logs selected setfile and sensor IDs.
- Channel-info diagnostics retained.

## Clean reboot test with firmware 1.55

Run directory:

`/home/neron/research/macbook-webcam-linux/codex-20260607-210043/phase-fw155-cleanreboot-20260607-213255/`

Important dmesg:

```text
Release : S2ISP-01.55.00
CH_INFO_GET ret=0 len=158 sensor ids 0005/9774 count=1
Loading set file facetimehd/1675_01XX.dat for sensor ids 0005/9774
Starting channel 0: requested 640x480, crop [0,0][640,480]
CROP -> [0, 0][640, 480] within [0, 0][848, 588]
New Output config -> format = 1, range 0, size = 640x480
```

## Functional verification

### Single-frame capture

Command output recorded in:

`phase-fw155-cleanreboot-20260607-213255/stream-fw155.txt`

Result:

```text
stream_exit=0
raw_size=614400 path=.../fw155-frame.raw
```

`614400 = 640 * 480 * 2`, expected YUYV frame size.

Converted preview/stat files:

- `phase-fw155-cleanreboot-20260607-213255/fw155-frame.raw`
- `phase-fw155-cleanreboot-20260607-213255/fw155-frame.ppm`
- `phase-fw155-cleanreboot-20260607-213255/fw155-frame-stats.txt`

Frame stats:

```text
raw_size=614400
Y: min=0 max=220 mean=99.42 unique=209
U: min=89 max=149 mean=119.77 unique=59
V: min=115 max=161 mean=136.09 unique=46
nonzero_bytes=614399
```

This confirms the frame is not empty/constant.

### 30-frame smoke test

Recorded in:

`phase-fw155-cleanreboot-20260607-213255/stream-fw155-30frames.txt`

Result:

- exit 0
- frames delivered at ~30 fps
- each frame `bytesused: 614400`

A firmware SIF warning appeared during this test:

```text
ERR: ./H4ISPCD/filters/IC/CImageCaptureH4.cpp, 777: FlowIC00: SIF errors: sifIrq = 0x8a!
```

Streaming still completed successfully. Treat as non-fatal unless visual corruption or instability appears.

### Reopen-after-stop test

Recorded in:

`phase-fw155-cleanreboot-20260607-213255/stream-fw155-reopen.txt`

Result:

```text
cap dqbuf: 0 seq: 0 bytesused: 614400
exit=0
raw_size=614400 path=.../fw155-frame-reopen.raw
```

This verifies the old reopen-after-stop failure pattern is not immediately present.

## Caution

Earlier repeated failed firmware experiments wedged the ISP until reboot. If future tests hit `Init failed! No wake signal`, stop cycling firmware, restore known firmware/source, and reboot before drawing conclusions.
