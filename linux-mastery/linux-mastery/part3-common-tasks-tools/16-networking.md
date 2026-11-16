# Chapter 16 · Networking
📖 Book: Part III, pp. 181–196 · ⏱ ~120 min · Prereq: Chapter 15 · **Core security chapter**

> ⚖️ **Authorization rule:** scan, probe or capture only systems and networks you own or have **written permission** to test. Practice on `localhost`, your own VMs, or intentionally vulnerable labs.

## Learning goals
- Inspect interfaces, routes, DNS and sockets
- Transfer files and connect remotely (`curl`, `wget`, `ssh`, `scp`, `sftp`, `rsync`)
- Use basic network analysis tools (`nc`, `dig`, `tcpdump`, `nmap`, `openssl`)
- Harden SSH and understand host firewalls

## 1. Install the tools
| Distro | Command |
|---|---|
| Debian/Ubuntu/Kali | `sudo apt install iproute2 iputils-ping traceroute dnsutils curl wget netcat-openbsd nmap tcpdump openssh-client whois` |
| RHEL/Fedora/Rocky | `sudo dnf install iproute iputils traceroute bind-utils curl wget nmap-ncat nmap tcpdump openssh-clients whois` |
| Arch | `sudo pacman -S iproute2 iputils traceroute bind curl wget openbsd-netcat nmap tcpdump openssh whois` |
| Alpine | `sudo apk add iproute2 iputils traceroute bind-tools curl wget netcat-openbsd nmap tcpdump openssh-client whois` |
| macOS | `brew install wget nmap tcpdump` (curl, ssh, nc, dig, ping included) |

## 2. Command table
| Task | Modern command | Legacy |
|---|---|---|
| Addresses | `ip -br a` | `ifconfig` |
| Routes | `ip r` | `route -n`, `netstat -r` |
| Neighbors (ARP) | `ip neigh` | `arp -a` |
| Sockets / ports | `ss -tulpn` | `netstat -tulpn` |
| Reachability | `ping -c 4 host` | |
| Path | `traceroute host` / `tracepath host` | |
| DNS | `dig example.com`, `dig +short A host`, `host host`, `nslookup` | |
| HTTP | `curl -I https://x`, `curl -O url`, `wget url` | |
| Remote shell | `ssh user@host` | `telnet` (plaintext, avoid) |
| Copy files | `scp file user@host:path`, `sftp user@host`, `rsync -avz` | `ftp` |
| Raw TCP | `nc -zv host 22`, `nc -l 4444` | |
| Ownership | `whois domain` | |
macOS: `ifconfig`, `netstat -rn`, `lsof -i -P -n`, `networksetup -listallhardwareports`, `scutil --dns`.

## 3. Guided walkthrough (local, safe)
```bash
ip -br a ; ip r ; cat /etc/resolv.conf
ping -c 3 127.0.0.1
dig +short example.com
curl -I https://example.com
ss -tulpn
# Local service + nc
python3 -m http.server 8080 --bind 127.0.0.1 &
curl -s http://127.0.0.1:8080 | head -5
nc -zv 127.0.0.1 8080
ss -tlnp | grep 8080 ; kill %1
# SSH keys
ssh-keygen -t ed25519 -C "lab-key"          # passphrase recommended
ls -l ~/.ssh                                 # private 600, public 644
```

## 4. 🔐 Cyber relevance
**Recon (authorized only)**
```bash
nmap -sV -O localhost                # service/version detection on your own box
nmap -sn 192.168.1.0/24              # host discovery on YOUR network
nmap -p- --min-rate 1000 127.0.0.1   # all 65535 ports locally
dig axfr @ns.example.com example.com # zone transfer test (only against your own DNS)
openssl s_client -connect example.com:443 -servername example.com </dev/null | openssl x509 -noout -subject -dates -issuer
curl -sI https://example.com | head  # banner/headers
```
**Packet capture** (needs root): `sudo tcpdump -i any -nn port 53 -c 20`, `sudo tcpdump -i eth0 -w capture.pcap` then open in Wireshark/`tshark -r capture.pcap`. Filters: `host 10.0.0.5`, `tcp port 22`, `not port 22` (avoid capturing your own SSH).
**Triage of a suspect host**
```bash
ss -tunap                       # all connections with PIDs
sudo lsof -i -P -n | grep ESTABLISHED
ip neigh; ip r                  # unexpected gateways? ARP duplicates?
cat /etc/hosts /etc/resolv.conf # DNS tampering
```
**SSH hardening** (`/etc/ssh/sshd_config`; validate with `sudo sshd -t`, then reload; keep a second session open):
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers alice bob
MaxAuthTries 3
```
Add `fail2ban` or rate limits; log in `auth.log`/`secure`/`journalctl -u sshd`. Verify host key fingerprints (`ssh-keygen -lf`), and treat a "REMOTE HOST IDENTIFICATION HAS CHANGED" warning seriously.
**SSH tunnels** (pivoting basics; legit admin and attacker use): `ssh -L 8080:internal:80 jump` (local), `ssh -R` (remote), `ssh -D 1080 host` (SOCKS). Know how to spot them: unusual long-lived `ssh` processes, `AllowTcpForwarding no` to block.
**Firewalls**
| Distro | Tool | Examples |
|---|---|---|
| Ubuntu/Debian | `ufw` | `sudo ufw default deny incoming`, `sudo ufw allow 22/tcp`, `sudo ufw enable`, `sudo ufw status verbose` |
| RHEL/Fedora/SUSE | `firewalld` | `sudo firewall-cmd --list-all`, `--add-service=ssh --permanent`, `--reload` |
| Any (kernel) | `nftables`/`iptables` | `sudo nft list ruleset`, `sudo iptables -L -n -v` |
| macOS | `pf` / app firewall | `sudo pfctl -sr` |
Default policy: **deny inbound, allow what's needed**. **Mind the lockout risk** when changing SSH/firewall rules remotely.
**Detection signals:** many failed SSH logins (`grep "Failed password" /var/log/auth.log`), outbound connections to unknown IPs, beacons at regular intervals, DNS to odd domains, services listening on all interfaces (`0.0.0.0`/`[::]`) that should be localhost-only.
**Don't use** telnet/ftp/rsh for anything real; credentials travel in clear text. Use `ssh`, `sftp`, `https`.

## 5. Labs
**Easy**
1. Record your IP, gateway, and DNS servers. Ping the gateway and `127.0.0.1`.
2. `dig example.com` and read each section. What is the TTL?
3. `curl -I https://example.com` and explain the status and headers.

**Medium**
4. Start a local web server on `127.0.0.1:8080`, find it with `ss -tulpn`, fetch with `curl` and `wget`, then stop it.
5. Generate an SSH key pair; set up key login to `localhost` (`ssh-copy-id localhost` after installing/starting `openssh-server`), test it.
6. Use `nc` for a two-terminal chat on `127.0.0.1:4444` (`nc -l 4444` / `nc 127.0.0.1 4444`; use `-p` on traditional netcat).

**Hard (cyber)**
7. Run `nmap -sV localhost`. For each open port: expected? needed? exposed beyond localhost?
8. Capture DNS with `tcpdump` (`sudo tcpdump -i any -nn port 53 -c 10`) while running `dig example.com`; identify the query and answer packets.
9. Harden a lab VM's SSH: key-only login, no root, `AllowUsers`; validate with `sshd -T | grep -Ei 'permitroot|passwordauth'`, reload, confirm password login fails.
10. Using `ss`, write a one-liner that lists listening ports bound to all interfaces: `ss -tuln | grep -E '0\.0\.0\.0|\[::\]'`. Decide which to close or bind to localhost.

## 6. Common mistakes
- Scanning networks without authorization
- Changing firewall/SSH rules on a remote server without a safety net
- Mixing port flags: `ssh` uses `-p`, but `scp` uses uppercase `-P`
- Trusting a hostname instead of verifying fingerprints
- Leaving `PasswordAuthentication yes` on internet-facing hosts

## 7. Quiz
1. Modern replacement for `netstat`? For `ifconfig`?
2. Why is `telnet` unsafe?
3. What does `0.0.0.0:22` in `ss` output mean?
4. Which `sshd_config` lines reduce brute-force risk?
5. What does `tcpdump -w` do?
6. What's the default stance of a good firewall?

<details><summary>Answers</summary>

1. `ss`; `ip`.
2. No encryption: credentials and data are readable in transit.
3. SSH is listening on all IPv4 interfaces.
4. `PasswordAuthentication no`, `PermitRootLogin no`, `MaxAuthTries`, `AllowUsers`.
5. Writes captured packets to a pcap file.
6. Deny by default, allow only what's required.
</details>

## 8. Mastery checklist
- [ ] I map interfaces, routes, DNS and listening sockets
- [ ] I use curl, ssh, scp/sftp/rsync with confidence
- [ ] I run basic scans/captures only where authorized
- [ ] I harden SSH and verify with `sshd -T`
- [ ] I can configure a basic host firewall

## Next → `17-searching-for-files.md`
