# Chapter 22 · Printing (lighter chapter)
📖 Book: Part III, pp. 297–310 · ⏱ ~45 min · Prereq: Chapter 21

## Learning goals
- Understand how Linux prints (CUPS) and use `lp`/`lpr`, `lpstat`, `cancel`
- Print or convert to PDF without physical hardware
- Treat printers and print services as part of the attack surface

## 1. Concepts
- Linux and macOS print through **CUPS** (Common UNIX Printing System). Jobs go into a queue (`/var/spool/cups`), are converted by filters, and sent to a printer. Admin web UI: `http://localhost:631`.
- Old Unix history: BSD style (`lpr`, `lpq`, `lprm`) and System V style (`lp`, `lpstat`, `cancel`); both work with CUPS.

| Command | Purpose |
|---|---|
| `lpstat -p -d` | Printers and default |
| `lpstat -t` | Everything (queues, jobs, status) |
| `lp file` / `lpr file` | Print a file |
| `lp -d printer -n 2 file` | Choose printer, copies |
| `lpq` | Show queue |
| `cancel jobid` / `lprm jobid` | Remove a job |
| `lpoptions -l` | Printer options |
| `sudo lpadmin -p name -E -v uri` | Add/configure a printer |
| `cupsctl` | Show/change server settings |
| `pr file \| lpr` | Paginate then print |
| `a2ps file`, `enscript` | Pretty text-to-PostScript |
| `ps2pdf`, `cupsfilter` | Convert formats |

Install: Debian/Ubuntu `sudo apt install cups cups-client cups-pdf`; RHEL `sudo dnf install cups cups-client`; Arch `sudo pacman -S cups`; Alpine `apk add cups cups-client`; macOS has CUPS built in. Start: `sudo systemctl enable --now cups` (Alpine: `rc-service cupsd start`).

## 2. Walkthrough (no printer needed)
```bash
lpstat -t                                 # status (may say "no destinations")
sudo systemctl status cups                # is the service running?
cupsctl                                   # server settings
# Print-to-PDF virtual printer (cups-pdf): output lands in ~/PDF
echo "Hello printing" > ~/linux-lab/hello.txt
lp -d PDF ~/linux-lab/hello.txt           # printer name may differ; check lpstat -p
lpstat -o                                 # outstanding jobs
# Without a printer: convert text to PDF
cupsfilter ~/linux-lab/hello.txt > ~/linux-lab/hello.pdf 2>/dev/null
file ~/linux-lab/hello.pdf
```

## 3. 🔐 Cyber relevance
- **Print services are network services.** CUPS listens on **631/tcp** (IPP) and historically **631/udp** (browsing). Check: `sudo ss -tulpn | grep -E ':631|cupsd|cups-browsed'`.
- **Real-world precedent:** critical vulnerabilities in `cups-browsed` (and related CUPS components) disclosed in September 2024 allowed remote code execution chains when the service was exposed. Lesson: if you don't print, **remove or disable it**:
  ```bash
  sudo systemctl disable --now cups cups-browsed cups.socket cups.path 2>/dev/null
  ```
  If you need printing, bind CUPS to localhost, block 631 inbound with the firewall, keep it patched, and disable network browsing.
- **Spool files contain data.** `/var/spool/cups` may hold copies of sensitive documents (and are readable by root/lp). Review retention; clean spool after incidents; include in forensics scope. Logs: `/var/log/cups/` (access, error, page logs).
- **Network printers and MFPs:** default credentials, outdated firmware, SNMP public community, open admin pages, stored scans and address books, and pivoting points into internal networks. Inventory them, segment them (VLAN), change default passwords, disable unused protocols (Telnet, FTP, SNMPv1/2c, raw 9100 where not needed).
- **Data loss:** printing is an exfiltration channel and a source of confidential paper. Policies: secure/pull printing, watermarking, logging (`lpstat`, page_log).
- **Discovery (authorized only):** `nmap -p 631,9100,515 192.168.1.0/24` finds IPP, JetDirect (raw), and LPD printers on **your** network. Use `ippfind` (CUPS tools) or `avahi-browse -a` for mDNS discovery.
- **Injection awareness:** filenames and job titles are attacker-controlled; the 2024 issues involved printer-description (PPD) and URI handling. Treat anything accepted from the network as hostile.

## 4. Labs
**Easy**
1. Check whether CUPS is installed and running; list printers with `lpstat -p`.
2. Open `http://localhost:631` in a browser (if running) and look around.
3. Create a text file and send it to a PDF printer or convert with `cupsfilter`.

**Medium**
4. List queued jobs with `lpstat -o`; submit two jobs to a paused queue (`cupsdisable PDF` / `cupsenable PDF`), then cancel one.
5. Paginate a file with `pr -h "My Report" -l 40 file | lp`.
6. Read the CUPS error log: `sudo tail /var/log/cups/error_log`.

**Hard (cyber)**
7. Determine whether CUPS or `cups-browsed` is listening on any non-local interface. Decide whether to disable it and document the exact commands for your OS.
8. Check `cupsctl` output for `_remote_admin`, `_remote_any`, `_share_printers`. Which should be off on a workstation?
9. Locate `/var/spool/cups` and describe what an investigator could learn from it (don't copy others' documents; just list file names and times).
10. Write a 5-line hardening checklist for a print server.

## 5. Common mistakes
- Leaving CUPS/cups-browsed enabled on servers that never print
- Exposing 631/tcp to untrusted networks
- Forgetting spool files and printer logs in incident scope
- Ignoring MFP/printer firmware updates

## 6. Quiz
1. What is CUPS?
2. Which port does IPP use?
3. Why should unused print services be disabled?
4. Where do queued print jobs live?

<details><summary>Answers</summary>

1. The standard printing system on Linux and macOS.
2. 631 (TCP; also UDP for legacy browsing).
3. Every running network service is attack surface; CUPS has had serious remote vulnerabilities.
4. `/var/spool/cups`.
</details>

## 7. Mastery checklist
- [ ] I can print, inspect queues, and cancel jobs from the CLI
- [ ] I can tell whether print services are exposed and shut them down
- [ ] I include printers in my asset and risk inventory

## Next → `23-compiling-programs.md`
