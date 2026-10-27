# Android 14 on a 2013 phablet: porting LineageOS to the Galaxy Mega 6.3

*Sherif Shalaby, October 2026*

The Samsung Galaxy Mega 6.3 shipped in 2013 with Android 4.2. Its community support ended at LineageOS 18.1
(Android 11). I wanted to know how far a 1.5 GB, 32-bit Snapdragon 400 phone with a Linux 3.4 kernel could
go. It went to Android 14: three major versions, about 110 logged issues, and one build at each step that
booted and stayed up.

This is the engineering story. The ROM is on [XDA](https://xdaforums.com/t/rom-unofficial-14-lineageos-ul-21-0-for-the-galaxy-mega-6-3-gt-i9200-melius.4806510/); the sources and build steps are in [this repo](../README.md).

## The plan: one version at a time

Jumping straight from 11 to 14 would have meant debugging three Android releases' worth of changes at once.
Instead each version got its own branch, built on the previous one's patch series: LineageOS-UL 19.1
(Android 12), then 20.0 (13), then 21.0 (14). LineageOS-UL ("Ultra Legacy") is a community fork that keeps
32-bit devices building after official LineageOS drops them.

Android 12 removed the msm8960 hardware layer the Mega relied on. The Galaxy S4's (jflte) HAL set, kept
alive by JDCTeam, filled the gap.

## A 3.4 kernel in a cgroup v2 world

Modern Android puts every process in a cgroup v2 hierarchy. Linux 3.4 doesn't have one. Services hung in
`stopping` and `createProcessGroup` failed everywhere. libprocessgroup learned to fall back to the old
cpuacct controller mounted at `/acct`, and the phone went from bootlooping to 60-odd working process groups.

## The freezer that broke file copies

On Android 13, copying a large file to `/sdcard` failed whenever the phone dozed. FUSE request waits in
kernel 3.4 weren't freezer-aware: suspend woke the waiter and the request failed. A freezer-aware wait in
`fs/fuse/dev.c` fixed it. A 300 MB copy then survived 31 suspends with the hash intact.

## "Bootloops" that weren't

The first Android 14 build seemed to bootloop on a black screen. It wasn't looping at all. The first boot
after a wipe took about five minutes on this hardware, and the screen timed out on the way. On top of that,
every HIDL `getService` without a VINTF manifest slept for a full second. Removing that sleep, and waiting,
gave a warm boot of about 84 seconds.

## Bringing back a camera API Android deleted

The Mega's camera is a HALv1 device, and Android 14 removed HALv1 support entirely. The camera service saw
zero cameras. Getting photos and video back took five layers:

- forward-porting the HALv1 device code into the camera service (with html6405's msm8226 work as the donor);
- restoring the recording-proxy listener and the CameraSource modes that video recording needs;
- carrying legacy video metadata as native handles across processes;
- restoring Android 13's `camera2.legacy` shim so camera2 and CameraX apps (Aperture) work;
- bringing back the HALv1 torch path for the flashlight tile.

The hardest bug was in a 2013 binary blob. The camera daemon crashed half a second after the stream started.
strace showed the fault address was always the start of an mmap region minus 4. The blob read the word before
a heap block, which faults whenever that block happens to start a fresh page. Face detection, a stack
overflow, the old TLS layout and an allocator change were all ruled out first. The fix was one environment
variable: a 16-byte front guard on the daemon's allocations.

## A kernel deadlock from 2013

With zram swap enabled, opening the camera app right after closing another one hard-reset the phone within
20 seconds, three times out of three. A `softlockup_panic` backtrace pointed at `mm/swapfile.c`: two callers
took the per-device swap lock but released the global `swap_lock` instead. The first `/proc/<pid>/smaps` read
that touched a swapped-out page left one lock held and the other corrupted, both CPUs spun, and the watchdog
reset the phone. The fix changes two lines, about ten years late.

## Security on a frozen platform

LineageOS-UL froze its Android 14 platform at April 2025. I backported eight framework security fixes from
LineageOS 21, and the release reports a security level of 2025-04-05 rather than the build date. The vendor
blobs are from 2017 and the kernel is 3.4, so this is a project phone, not a daily driver.

The public build also runs SELinux enforcing, with a policy written from a survey of every denial on a real
boot. There is one exception: two 2013 camera libraries need text relocations.

## What's next

Android 15 (LineageOS 22.2) boots on the Mega, but Wi-Fi, the keyboard and the camera don't work yet. It
needs a kernel with eBPF backports, which exists, and a lot more time.

## Thanks

sileshn for the melius trees this all started from; the LineageOS and LineageOS-UL teams; JDCTeam for the
jflte HALs; and html6405 for the HALv1 camera groundwork on msm8226.
