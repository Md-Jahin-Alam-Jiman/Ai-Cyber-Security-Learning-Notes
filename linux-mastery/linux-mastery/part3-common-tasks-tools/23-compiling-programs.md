# Chapter 23 · Compiling Programs (lighter chapter)
📖 Book: Part III, pp. 311–322 · ⏱ ~60 min · Prereq: Chapter 22

## Learning goals
- Understand compilation and the build process (`configure`, `make`, `make install`)
- Install a build toolchain on any distro
- Build software safely: verify, read, isolate, and install without polluting the system
- Use compiler hardening flags and inspect binaries safely

## 1. Concepts
Source code (C/C++) → **compiler** (`gcc`/`clang`) → **object files** → **linker** → executable. `make` reads a `Makefile` and rebuilds what changed. Most open-source tarballs follow:
```
tar xzf pkg.tar.gz && cd pkg
./configure --prefix=$HOME/opt/pkg     # checks system, generates Makefiles
make                                   # compile
make check                             # run tests (if available)
make install                           # copy files (no sudo if prefix is yours)
```
Other build systems: `cmake` (`cmake -S . -B build && cmake --build build`), `meson`/`ninja`, `cargo` (Rust), `go build`.

## 2. Install the toolchain
| Distro | Command |
|---|---|
| Debian/Ubuntu/Kali | `sudo apt install build-essential` |
| RHEL/Rocky/Fedora | `sudo dnf groupinstall "Development Tools"` (or `sudo dnf group install development-tools`) |
| Arch | `sudo pacman -S base-devel` |
| Alpine | `sudo apk add build-base` |
| openSUSE | `sudo zypper install -t pattern devel_basis` |
| macOS | `xcode-select --install` (Clang) or `brew install gcc make` |

Verify: `gcc --version && make --version`.

## 3. Hands-on: Hello, build
```bash
cd ~/linux-lab && mkdir -p cc && cd cc
cat > hello.c <<'EOT'
#include <stdio.h>
int main(void) {
    printf("Hello, build!\n");
    return 0;
}
EOT
gcc hello.c -o hello && ./hello
file hello
cat > Makefile <<'EOT'
CC=gcc
CFLAGS=-Wall -Wextra -O2
hello: hello.c
	$(CC) $(CFLAGS) hello.c -o hello
clean:
	rm -f hello
EOT
make            # builds; run again: "up to date"
make clean
make -n         # dry run: shows commands without running them
```
(Makefile recipe lines must start with a **tab**, not spaces.)

Real-world practice: download GNU Hello from the GNU mirror (https://ftp.gnu.org/gnu/hello/), verify it, then:
```bash
tar xzf hello-*.tar.gz && cd hello-*/
./configure --prefix=$HOME/opt/hello
make && make check && make install
$HOME/opt/hello/bin/hello
```

## 4. 🔐 Cyber relevance
- **Verify before you build:** compare the tarball's checksum with the publisher's and verify GPG signatures: `gpg --verify pkg.tar.gz.sig pkg.tar.gz` (import the maintainer's key from a trusted channel). A compromised mirror or a typosquatted repo is a real supply-chain path (the 2024 XZ Utils backdoor hid in release tarballs and build scripts, which is why reading `configure`/`Makefile` and verifying sources matters).
- **Build as an unprivileged user, in a VM/container, never as root.** Build scripts execute arbitrary commands. Only `make install` needs privileges, and with `--prefix=$HOME/...` or `DESTDIR=/tmp/stage make install` it doesn't.
- **Skim before running:** `less Makefile configure.ac`, `grep -nE 'curl|wget|nc |bash -c|base64' Makefile configure`. `make -n` shows what would run.
- **Avoid unmanaged system installs:** `sudo make install` scatters files into `/usr/local` and can't be cleanly removed. Prefer distro packages; otherwise `checkinstall` (Debian), `stow`, or a dedicated prefix.
- **Compile exploit PoCs only in isolated labs.** Read them first; run in a snapshot-able VM with no sensitive data and a restricted network.
- **Hardening flags** for your own code:
  ```bash
  gcc -Wall -Wextra -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fPIE -pie \
      -Wl,-z,relro,-z,now hello.c -o hello
  ```
  Check results: `checksec --file=./hello` (package `checksec`), or `readelf -h hello`, `readelf -d hello`.
- **Inspect unknown binaries safely:** `file`, `strings -n 8`, `readelf -h`, `objdump -d -M intel | less`, `sha256sum`. ⚠️ **Don't run `ldd` on untrusted binaries.** It may execute them; use `objdump -p bin | grep NEEDED` or `readelf -d bin | grep NEEDED`.
- **Static vs dynamic:** `gcc -static` produces self-contained binaries (handy for incident-response tools you copy to a compromised host without trusting its libraries) but patches don't flow in via shared libraries.
- **Reproducibility and provenance:** keep hashes of source and resulting binaries; note compiler version (`gcc --version`) and flags in your notes.
- **Memory-safety bugs** (buffer overflows, use-after-free) are the root of many CVEs. Try `-fsanitize=address,undefined` during development: `gcc -g -fsanitize=address,undefined x.c`.

## 5. Labs
**Easy**
1. Install the toolchain, compile `hello.c`, run it.
2. Write a Makefile and run `make`, `make -n`, `make clean`.
3. Use `file hello` and `ls -l hello` to describe the binary.

**Medium**
4. Add a second source file (`greet.c` + header) and update the Makefile to build both.
5. Build GNU Hello into `$HOME/opt/hello` and run it; then delete the directory to "uninstall".
6. Run `make -n install` for any project to see what it would copy and where.

**Hard (cyber)**
7. Build `hello.c` with and without hardening flags; compare with `checksec` or `readelf -l` / `readelf -d`.
8. Inspect `/bin/ls` with `file`, `readelf -d`, and `strings | head`, **without** `ldd`. List its shared libraries.
9. Write a small vulnerable C program (unchecked `strcpy` into a small buffer) in a VM, compile with and without `-fstack-protector-strong`, and observe the difference for a long input. (Learning exercise only, using your own code.)
10. Verify a tarball: compute its `sha256sum`, compare with a published value (or sign/verify your own test tarball with `gpg --detach-sign` and `gpg --verify`).

## 6. Common mistakes
- Spaces instead of tabs in Makefiles
- Missing `-dev`/`-devel` packages (errors like "header not found"). Search: `apt-file search header.h` / `dnf provides '*/header.h'`
- Running `sudo make` for the whole build
- Mixing `/usr/local` builds with packaged versions
- Running unknown binaries or `ldd` on them

## 7. Quiz
1. Steps of a classic source build?
2. Why use `--prefix=$HOME/...`?
3. Why shouldn't you run `ldd` on an untrusted binary?
4. Name two compiler hardening flags.
5. What does `make -n` do?

<details><summary>Answers</summary>

1. `./configure`, `make`, `make install` (plus tests).
2. Installs without root and keeps the system clean and removable.
3. `ldd` may execute the program to resolve libraries.
4. e.g. `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`, `-fPIE -pie`, `-Wl,-z,relro,-z,now`.
5. Shows the commands it would run without executing them.
</details>

## 8. Mastery checklist
- [ ] I can compile C code and write a basic Makefile
- [ ] I build third-party source as a non-root user in an isolated prefix
- [ ] I verify sources and read build scripts
- [ ] I inspect unknown binaries without executing them

## Next → `checkpoint-3-log-analysis-and-backup-project.md`
