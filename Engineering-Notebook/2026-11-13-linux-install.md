# Linux Installation and Log Notes

## Questions

### 1. Why can't Windows reach `10.0.2.15` directly in NAT mode?

In the usual VirtualBox NAT setup, `10.0.2.15` is a private address assigned
inside the guest's virtual network. NAT lets the guest initiate connections
outward, but Windows does not have a direct route back to that guest address.
To connect from Windows, configure a port-forwarding rule (for example, forward
a host port to the guest's SSH port), or choose a network mode that provides
host-to-guest connectivity, such as host-only or bridged networking.

### 2. What is the difference between a snapshot and a backup?

A snapshot records a VM's state at a point in time so you can roll the VM back
to that state. It is useful before a change, but it usually depends on the
original VM files and storage, so it is not a separate disaster-recovery copy.
A backup is a separate copy of important files or the whole VM that can be
restored if the original is lost or damaged. Use snapshots for short-term
rollback and backups for recovery; one does not replace the other.

### 3. Why does a server install ship without a desktop?

A server is commonly managed remotely or from a terminal, so a graphical
desktop is not needed by default. Leaving it out reduces resource use and the
number of installed components that need maintenance, and can reduce the
system's attack surface. A desktop can usually be installed later if there is
a specific need for one.

## Notes Questions

### 1. What does `-rw-r-----` allow, and for whom?

The first character, `-`, means this is a regular file. The remaining
characters describe permissions in owner, group, and other order:

- Owner: `rw-` — read and write.
- Group: `r--` — read only.
- Others: `---` — no access.

So the file's owner can read and modify it, members of its group can read it,
and everyone else has no access.

### 2. Why does `auth.log` belong to `syslog` and `adm`, not to your user?

`auth.log` contains system authentication events and is managed by the system
logging service, so it is typically owned by the logging account (`syslog`) and
assigned to the `adm` group. This lets the logging service write the file and
allows authorized administrators or users in `adm` to read it without making
it accessible to every user. Your regular account is not automatically given
access because authentication logs can contain sensitive system activity.

### 3. Why do the failed-login lines matter for your detector?

Failed-login entries provide events a detector can count and analyze. Their
timestamps, attempted account names, and source addresses can help identify
repeated attempts or patterns across accounts and time. A single failure can
be a typo or other benign mistake, so it should not automatically be treated
as an attack; the detector should look for patterns and thresholds and report
enough context to investigate.