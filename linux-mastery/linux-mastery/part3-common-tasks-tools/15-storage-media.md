# Chapter 15 · Storage Media (lighter chapter, vital for forensics)
📖 Book: Part III, pp. 165–180 · ⏱ ~75 min · Prereq: Chapter 14

## Learning goals
- Understand devices, partitions, file systems, and mount points
- Mount and unmount safely; read `/etc/fstab`
- Create disk images and **practice safely with a loopback file**
- Know the forensic basics: read-only mounts, imaging, hashing

## 1. Core concepts
- Disks appear as device files: `/dev/sda`, `/dev/nvme0n1`, `/dev/vda` (VMs). Partitions add numbers: `/dev/sda1`, `/dev/nvme0n1p1`.
- A partition holds a **file system** (ext4, xfs, btrfs, vfat, ntfs, exfat). **Mounting** attaches it to a directory.
- `/etc/fstab` lists persistent mounts; `/proc/mounts` shows what's mounted now.

| Command | Purpose |
|---|---|
| `lsblk -f` | Tree of disks, partitions, FS types, mount points |
| `df -hT` | Space and FS type of mounted systems |
| `findmnt` | Mount tree |
| `sudo blkid` | UUIDs and types |
| `sudo fdisk -l` | Partition tables |
| `mount` / `sudo mount dev dir` | Show / attach |
| `sudo umount dir` | Detach |
| `sync` | Flush writes |
| `sudo mkfs.ext4 dev` | Create a file system (**destroys data**) |
| `sudo fsck dev` | Check/repair (unmounted!) |
| `dd if=SRC of=DST bs=4M status=progress` | Raw copy |
| `sudo dmesg \| tail` | Kernel messages (what happened when a USB was plugged in) |

**macOS:** `diskutil list`, `diskutil mount/unmount`, `hdiutil attach -readonly image.dmg`, raw devices are `/dev/rdiskN`.
**Alpine:** BusyBox `mount`; `apk add util-linux e2fsprogs lsblk` for full tools.
Debian/RHEL: `lsblk`, `blkid`, `fdisk` come with `util-linux`; `mkfs.xfs` needs `xfsprogs`.

## 2. 🧪 Safe lab: a virtual disk (no real disk touched)
```bash
cd ~/linux-lab
dd if=/dev/zero of=disk.img bs=1M count=64          # 64 MB empty file
mkfs.ext4 -F disk.img                               # format it (works on a file)
sudo mkdir -p /mnt/lab
sudo mount -o loop disk.img /mnt/lab
df -hT /mnt/lab; lsblk | grep loop
sudo touch /mnt/lab/hello.txt && ls -l /mnt/lab
sudo umount /mnt/lab
sudo mount -o loop,ro,noexec,nosuid,nodev disk.img /mnt/lab    # forensic-style mount
sudo touch /mnt/lab/new.txt                                      # fails: read-only
sudo umount /mnt/lab
sha256sum disk.img
```
macOS equivalent: `hdiutil create -size 64m -fs "MS-DOS" -volname LAB disk.dmg`, `hdiutil attach disk.dmg`, `hdiutil detach /Volumes/LAB`.

## 3. fstab quick read
```
# <device>        <mount>  <type> <options>        <dump> <pass>
UUID=abcd-1234    /        ext4   defaults,errors=remount-ro  0 1
```
Never edit `/etc/fstab` carelessly: a wrong entry can prevent boot. Test with `sudo mount -a` and keep a backup.

## 4. 🔐 Cyber relevance
- **Forensic principle:** never alter evidence. Use a **write blocker** (hardware) or mount read-only: `mount -o ro,noexec,nosuid,nodev,noload` (`noload` for ext4 avoids journal replay).
- **Imaging:**
  ```bash
  sudo dd if=/dev/sdX of=evidence.img bs=4M conv=noerror,sync status=progress
  sha256sum evidence.img > evidence.img.sha256
  ```
  Better tools: `dc3dd`, `dcfldd`, `ddrescue` (failing disks), `ewfacquire` (E01 format). Hash the source and image; record serial numbers (`lsblk -o NAME,SERIAL,SIZE,MODEL`) and times (UTC).
- ⚠️ **`dd` is "disk destroyer":** swapping `if` and `of`, or choosing the wrong device, erases a disk instantly. Triple-check with `lsblk` before pressing Enter. Never run it against your boot disk.
- **Mount options are security controls:** `noexec` (no running binaries), `nosuid` (ignore setuid), `nodev` (ignore device files). Hardening guides recommend them on `/tmp`, `/var/tmp`, `/home`, `/dev/shm` and removable media.
- **USB threats:** plugging in unknown devices can run autorun or HID attacks. Check `dmesg` and `udevadm monitor`. Disable automounting on sensitive systems.
- **Encryption:** LUKS: `sudo cryptsetup luksFormat dev`, `luksOpen`, `luksClose`; check with `sudo cryptsetup luksDump dev`. Full-disk encryption protects lost laptops; remember keys in memory and swap.
- **Secure wiping:** SSD wear-levelling means overwriting isn't guaranteed; prefer encryption + key destruction, ATA Secure Erase, or `blkdiscard` for SSDs.
- **Loop-mount suspicious images** read-only and inspect, never execute. Mounting an untrusted image is safer in a VM since file-system drivers have had bugs.

## 5. Labs
**Easy**
1. Run `lsblk -f`, `df -hT`, `findmnt`. Identify your root disk and its file system.
2. View `/etc/fstab`. Explain each column of one line.
3. Create `disk.img` (64 MB) and format it as ext4.

**Medium**
4. Mount `disk.img` at `/mnt/lab`, create 3 files, unmount, remount **read-only**, prove writes fail.
5. Create a second image formatted as `vfat` (`mkfs.vfat disk2.img`) and compare `df -hT` output.
6. Plug in a USB stick (if you have one), run `sudo dmesg | tail -20` before and after. Identify the device name. Unmount safely.

**Hard (cyber)**
7. Image your loopback file: `dd if=disk.img of=copy.img bs=1M`; verify with `sha256sum` that both match; alter one byte in copy (`printf 'X' | dd of=copy.img bs=1 seek=100000 conv=notrunc`) and hash again.
8. Delete a file inside `disk.img`, then search the raw image for leftover text: `strings disk.img | grep -i 'secret'` (put a text file with "secret-note" inside first). Explain why deletion isn't erasure.
9. Document the exact steps and commands of a forensic-safe acquisition (device identification, hash, image, hash, read-only mount) in `~/linux-lab/imaging-procedure.md`.
10. Optional: create a LUKS container on an image file: `sudo cryptsetup luksFormat disk.img`, open, format, mount, close. Explain what an attacker sees without the key.

## 6. Common mistakes
- Pulling out a USB without `umount`/`sync`
- Running `fsck` on a mounted file system
- Confusing `/dev/sda` (disk) with `/dev/sda1` (partition)
- Wrong `of=` in `dd`
- Editing `fstab` without testing

## 7. Quiz
1. What does `mount -o loop` allow?
2. Which options make a mount safer for untrusted media?
3. What's the danger of `dd`?
4. Why hash an evidence image?
5. Why is deletion not erasure?

<details><summary>Answers</summary>

1. Mounting a regular file as if it were a disk.
2. `ro`, `noexec`, `nosuid`, `nodev` (and `noload` for ext4 forensics).
3. It overwrites the target without confirmation; a wrong device means data loss.
4. To prove integrity and show it hasn't changed since acquisition.
5. Only the directory entry is removed; data blocks stay until overwritten.
</details>

## 8. Mastery checklist
- [ ] I read `lsblk`, `df -hT`, `findmnt` output
- [ ] I mount and unmount, including read-only/noexec
- [ ] I make and verify disk images safely
- [ ] I can outline a forensically sound acquisition

## Next → `16-networking.md`
