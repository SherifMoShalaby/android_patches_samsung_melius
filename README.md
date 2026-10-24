# LineageOS-UL 21.0 for the Samsung Galaxy Mega 6.3 (meliusltexx): build patches

Unofficial. Not affiliated with or endorsed by the LineageOS project.

This repo holds what a LineageOS-UL 21.0 (Android 14) tree needs to build for the GT-I9200 (meliusltexx,
msm8930):

- `pinned-manifest.xml`: the full manifest of the released build. Every project is pinned, the patched ones at
  the commit their patches were made on, and the device and kernel trees at the forks below.
- `local_manifests/melius.xml`: the same device additions as a local manifest, for a tree that follows the
  `lineage-21.0` branch instead.
- Device and kernel trees: forks of [sileshn](https://github.com/sileshn)'s lineage-18.1 trees, branch
  `lineage-21`, tag `b11`. Proprietary blobs come from sileshn's vendor repo, unmodified.
- `patches/<path>/`: 31 patches to 16 platform projects (camera HALv1, the `/acct` cgroup fallback, text
  relocations for 2013 vendor blobs, HIDL lookup delays, eight security backports to frameworks/base…).
- `SERIES.tsv`: the upstream commit each project's patches were made on.

## Build the released source

```bash
git clone -b lineage-21 https://github.com/SherifMoShalaby/android_patches_samsung_melius ~/melius-patches
mkdir ~/ul21 && cd ~/ul21
repo init -u https://github.com/SherifMoShalaby/android_patches_samsung_melius -b lineage-21 -m pinned-manifest.xml --git-lfs
repo sync -c -j8
~/melius-patches/apply.sh
source build/envsetup.sh && breakfast meliusltexx && mka bacon
```

`apply.sh` checks every project before changing anything and stops if one is not at its expected commit.

To follow LineageOS-UL's moving branch instead, `repo init -u https://github.com/LineageOS-UL/android.git -b
lineage-21.0 --git-lfs`, copy `local_manifests/melius.xml` into `.repo/local_manifests/`, sync, and run
`FORCE=1 ~/melius-patches/apply.sh`. Patches may then need fixing up.

The 3.4 kernel only builds with GCC 4.9, so melius-common sets `TARGET_KERNEL_CLANG_COMPILE := false`.

`mka bacon` gives a test-key build. The released zip was built as target-files and signed with the maintainer's
own release keys (`sign_target_files_apks`, then `ota_from_target_files`, APEX keys included). A build of your
own has your keys, so its checksum and certificate differ.

## Licences

Patches keep the licence of the project they apply to (mostly Apache 2.0). The kernel is GPL-2.0.
Proprietary Samsung and Qualcomm blobs are not in this repo.
