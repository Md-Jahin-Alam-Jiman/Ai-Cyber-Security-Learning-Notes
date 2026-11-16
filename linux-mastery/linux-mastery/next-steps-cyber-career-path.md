# Next Steps · From Command Line to Cyber Career

You finished the book's four parts, three checkpoints, and a capstone. Here's how to keep building on it.

## 1. Lock in the skills (weeks 1–4 after the course)
- **Re-do Checkpoint 1 and 3 from memory** on a different distro (Debian ↔ Rocky/Alma ↔ Alpine). Speed and confidence come from repetition.
- **Practice daily in a lab:** a VM with snapshots (VirtualBox/VMware/KVM) or containers. Break it, restore it, repeat.
- **Keep your journal and scripts in git.** A GitHub portfolio with `seckit`, your triage scripts, and write-ups is concrete proof of skill.
- **Read man pages for one new tool each week** (`ss`, `journalctl`, `auditctl`, `iptables/nft`, `systemctl`, `lsof`, `strace`, `tcpdump`).

## 2. Hands-on practice sites (legal, built for learning)
- **OverTheWire: Bandit**: gamified Linux command-line puzzles, a perfect follow-up to this course
- **TryHackMe** and **Hack The Box** (beginner paths): guided labs for Linux fundamentals, privilege escalation, and incident response
- **picoCTF**, **CyberDefenders**, **Blue Team Labs Online**: CTF/forensics/blue-team challenges
- **Your own lab:** intentionally vulnerable VMs/containers (for example DVWA, Metasploitable, VulnHub images) on an **isolated** network

> Only test systems you own or have written permission to test.

## 3. Topics that build directly on this book
| Area | What to learn next |
|---|---|
| Linux administration | `systemd` units/timers, users & groups, `sudoers`, PAM, `journald`, LVM, file systems, `cron` |
| Hardening | CIS Benchmarks, `lynis`, `auditd`, SELinux/AppArmor, firewalls (`nftables`, `ufw`, `firewalld`), SSH hardening, kernel parameters (`sysctl`) |
| Incident response & forensics | Disk/memory acquisition, timeline building, `The Sleuth Kit`, Volatility, log analysis, chain of custody |
| Network security | `tcpdump`/Wireshark, `nmap`, TLS inspection, DNS analysis, IDS (Suricata/Snort/Zeek) |
| Detection engineering | Log pipelines (rsyslog, Filebeat), SIEM basics (Elastic, Splunk, Wazuh), Sigma rules, YARA |
| Offensive security (authorized) | Linux privilege escalation concepts, web app testing, GTFOBins, enumeration methodology |
| Automation | Python for security (`requests`, `scapy`, `paramiko`), Ansible, Git/CI basics |
| Cloud & containers | Docker/Podman security, Kubernetes basics, cloud IAM, logging in AWS/Azure/GCP |

## 4. Certifications to consider (choose by goal)
- **Linux foundations:** LPIC-1, CompTIA Linux+, Red Hat **RHCSA**
- **Security foundations:** CompTIA Security+ (widely recognized baseline)
- **Defensive/IR:** CompTIA CySA+, GIAC GCIH/GCFA (SANS), Blue Team Level 1
- **Offensive:** eJPT → OSCP (hands-on, Linux-heavy)

Check each certification's current exam objectives on the vendor's site before committing; they change.

## 5. A 30-60-90 day plan
**Days 1–30:** Redo checkpoints on two distros · finish OverTheWire Bandit · add `shellcheck` and tests to all your scripts · publish your toolkit on GitHub with a clear README.
**Days 31–60:** Learn `systemd`, `auditd`, firewalls, and SSH hardening by hardening a VM to a CIS-style baseline and scoring it with `lynis` · start a TryHackMe/HTB Linux path.
**Days 61–90:** Do a full mock incident: compromise an isolated lab box, then investigate it with your own tools, write a report in the format from Checkpoint 3 · start preparing for your first certification.

## 6. Habits of strong practitioners
- **Quote everything. Validate input. Prefer allow-lists.**
- **Dry-run first** and keep backups/snapshots before changing systems
- **Verify, don't trust:** hashes, signatures, `type -a`, `bash -n`, `shellcheck`
- **Least privilege:** `sudo` for the one command, not a root shell for the afternoon
- **Document as you go**: commands, timestamps (UTC), and why
- **Stay legal and ethical.** Authorization is the line between a professional and a criminal

Good luck. Keep your terminal open.
