Hi,

I have a working FaceTimeHD setup on a 2017 12-inch MacBook (`MacBook10,1`, board `Mac-EE2EBD4B90B839A8`) and wanted to document the findings because this model appears to need a slightly different path from the default 720p assumptions.

Hardware / system:

- Model: `MacBook10,1`
- Board: `Mac-EE2EBD4B90B839A8`
- Kernel: `6.17.0-35-generic`
- Camera: Broadcom 1570 PCIe FaceTimeHD
- Working firmware: Boot Camp `S2ISP-01.55.00`
- Sensor IDs reported by firmware: `0005/9774`
- Setfile used: `facetimehd/1675_01XX.dat`
- Working format: `640x480` YUYV, `614400` bytes/frame, ~30 fps

The old public firmware `S2ISP-01.43.00` could create `/dev/video0`, but on this MacBook it reported no sensor:

```text
Sensor is null after hNVStorage Validate
CH_INFO_GET ret=0 len=158 sensor ids 0000/0000 count=0
```

With Boot Camp firmware `S2ISP-01.55.00` and the matching calibration files, the sensor is detected:

```text
Release : S2ISP-01.55.00
CH_INFO_GET ret=0 len=158 sensor ids 0005/9774 count=1
Loading set file facetimehd/1675_01XX.dat for sensor ids 0005/9774
```

This model also needs a true 480p path. It is not enough to expose 640x480 via V4L2 while still sending a 720p-style crop to the ISP. The working log shows:

```text
Starting channel 0: requested 640x480, crop [0,0][640,480]
CROP -> [0, 0][640, 480] within [0, 0][848, 588]
New Output config -> format = 1, range 0, size = 640x480
```

Functional tests that passed:

```text
single-frame capture: 614400 bytes, exit 0
30-frame v4l2-ctl smoke test: ~30 fps, 614400 bytes/frame, exit 0
reopen-after-stop single frame: 614400 bytes, exit 0
browser webcam test: successful video stream
```

There also appears to be an Apple ACPI power sequencing requirement. The camera ACPI method is at:

```text
\\_SB_.PCI0.RP10.CMRA.CMPE
```

Using the PCI device ACPI handle did not reliably resolve the right object. Resolving the CMRA handle directly and calling `CMPE` before firmware init was needed on this machine. Skipping CMPE caused even the old firmware to fail before first wake with:

```text
Init failed! No wake signal
```

One additional trap: after failed firmware experiments, the ISP can remain wedged until reboot/cold reset. Repeated module reloads after `No wake signal` can produce misleading results.

I collected the working patch, firmware extraction notes, and test logs here:

https://github.com/neron82/macbook10-1-facetimehd-linux

The patch is currently a working field patch rather than a minimal upstream-ready PR. I am opening this issue first to document the exact model/firmware/sensor behavior and discuss how best to upstream the 12-inch MacBook path without breaking other FaceTimeHD models.
