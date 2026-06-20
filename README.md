# Linux Server Health Monitoring Script

A Bash-based Linux server health monitoring tool that checks **Disk, Memory, CPU usage, and critical services**, and sends **email alerts** when something goes wrong — with a built-in **alert-once mechanism** so the same issue doesn't spam your inbox every few minutes.

Built as a practical Production Support / Linux Administration project — demonstrates shell scripting, system monitoring, automation via cron, and real-world alerting design.

---

## Table of Contents

- [Features](#features)
- [How Alert-Once Logic Works](#how-alert-once-logic-works)
- [Sample Output](#sample-output)
- [Technologies Used](#technologies-used)
- [Configuration](#configuration)
- [Setup & Usage (Any Server)](#setup--usage-any-server)
- [Scheduling with Cron](#scheduling-with-cron)
- [Troubleshooting](#troubleshooting)
- [Use Cases](#use-cases)
- [Future Enhancements](#future-enhancements)
- [Author](#author)

---

## Features

**Disk Usage Monitoring**
- Monitors root filesystem (`/`) utilization using `df`.
- Sends an email alert when usage crosses the configured threshold.

**Memory Usage Monitoring**
- Calculates memory utilization percentage using `free`.
- Sends an email alert when usage crosses the configured threshold.

**CPU Usage Monitoring**
- Calculates CPU utilization from `top` system statistics.
- Sends an email alert when usage crosses the configured threshold.

**Service Monitoring**
Checks the status of critical Linux services using `systemctl`:
- `httpd`
- `sshd`
- `crond`

Sends an email notification if any service is not active.

**Server Health Report**
Every run prints a summary:
- Hostname
- Current date and time
- Disk usage %
- Memory usage %
- CPU usage %
- Status of monitored services

**Alert-Once Logic (Anti-Spam)**
Disk, Memory, and CPU checks use flag files to ensure **only one alert per incident** — not one alert every single cron run. See below for details.

---

## How Alert-Once Logic Works

A naive monitoring script sends an alert **every time** it runs while a resource is above threshold. If cron runs every 5 minutes and disk stays full for 2 hours, that's 24 identical emails — this causes "alert fatigue" where real alerts get ignored.

This script avoids that using a simple **flag file** per resource:

```
Is resource above threshold?
 ├── YES
 │    ├── Flag file does NOT exist  → send alert email + create flag file
 │    └── Flag file already exists  → do nothing (already alerted, stay quiet)
 └── NO (resource is back to normal)
      └── If flag file exists → delete it
          (so the NEXT time it breaches threshold, a fresh alert is sent)
```

Example timeline for disk usage:

| Time  | Disk % | Flag file exists? | Action                  |
|-------|--------|--------------------|--------------------------|
| 10:00 | 90%    | No                 | Mail sent, flag created |
| 10:05 | 91%    | Yes                | No mail (already alerted) |
| 10:10 | 92%    | Yes                | No mail (already alerted) |
| 10:15 | 70%    | Yes                | Flag deleted (resolved) |
| 10:20 | 85%    | No                 | Mail sent again (new incident) |

> **Note:** Service monitoring (httpd/sshd/crond) does not yet use this logic — see [Future Enhancements](#future-enhancements).

---

## Sample Output

```
===== SERVER HEALTH REPORT =====
Hostname     : server01
Date         : 2026-06-20 18:45:01
Disk Usage   : 44%
Memory Usage : 55%
CPU Usage    : 18%
HTTPD        : active
SSHD         : active
CROND        : active
```

---

## Technologies Used

- Linux (tested on RHEL 8 / CentOS-compatible systems)
- Shell Scripting (Bash)
- AWK
- Mail utility (`mailx` / Postfix — must be configured to actually send mail)
- `systemctl`
- `top`, `df`, `free`

---

## Configuration

All thresholds, the alert email, and flag file paths are set as variables at the **top of `alert.sh`** — nothing else in the script needs to be touched for basic configuration:

```bash
DISK_THRESHOLD=80
MEM_THRESHOLD=80
CPU_THRESHOLD=85
EMAIL="your-email@example.com"

DISK_FLAG="/path/to/disk_alert.flag"
MEM_FLAG="/path/to/mem_alert.flag"
CPU_FLAG="/path/to/cpu_alert.flag"
```

Update these before running on a new server.

---

## Setup & Usage (Any Server)

These steps work on **any RHEL/CentOS-based Linux server** — not tied to one machine. Follow them on whichever server you want to deploy this on.

### 1. Clone the repository
```bash
git clone https://github.com/nitinoneview/linux-server-health-monitor.git
cd linux-server-health-monitor
```

### 2. Make sure `mail` is installed and working
Check if the mail utility is available:
```bash
which mail
```
If not installed (RHEL/CentOS):
```bash
sudo yum install mailx -y
```
Test that mail actually sends (replace with your email):
```bash
echo "test" | mail -s "test subject" your-email@example.com
```
> If this test doesn't arrive, the script's alerts won't either — fix mail delivery first (Postfix/sendmail configuration) before relying on this script.

### 3. Edit configuration in `alert.sh`
Open the script and update the variables at the top — at minimum, change `EMAIL` to your address, and update the flag file paths to match wherever you place this script on the new server:
```bash
nano alert.sh
```

### 4. Make the script executable
```bash
chmod +x alert.sh
```
> This step is **required**. Without execute permission, cron will fail with `Permission denied` even though the script runs fine when called manually as `bash alert.sh`.

### 5. Run it manually to test
```bash
./alert.sh
```
You should see the health report printed to the terminal. Trigger a test alert by temporarily lowering a threshold (e.g. `DISK_THRESHOLD=1`) and re-running.

---

## Scheduling with Cron

To run this automatically in the background (e.g. every 5 minutes), use `cron` instead of running it manually each time.

### 1. Find the full absolute path of the script
```bash
pwd
```
This shows your current directory. Combine it with the filename to get the full path, e.g.:
```
/home/nitin/Project/script/alert.sh
```

> ⚠️ **Always use the full absolute path in cron**, never a relative path like `./alert.sh`. Cron does not run inside your interactive shell — it has no concept of "current directory", so a relative path will fail.

### 2. Open the crontab editor
```bash
crontab -e
```

### 3. Add a line to schedule the script
To run every 5 minutes and save output to a log file:
```
*/5 * * * * /home/nitin/Project/script/alert.sh >> /home/nitin/Project/script/health.log 2>&1
```

**Breaking down this line:**

| Part | Meaning |
|---|---|
| `*/5 * * * *` | Run every 5 minutes (minute / hour / day / month / weekday — all `*` except minute) |
| `/home/nitin/Project/script/alert.sh` | Full path to the script — **must match your actual path on your server** |
| `>> health.log` | Append output to a log file instead of discarding it |
| `2>&1` | Also send error output into the same log file (helpful for debugging) |

Save and exit. Cron will now run the script automatically.

### 4. Verify it's working
After a few minutes, check the log file:
```bash
cat /home/nitin/Project/script/health.log
```
You should see health reports appended over time. If you see errors instead, see [Troubleshooting](#troubleshooting) below.

### Other useful cron schedule examples
| Schedule | Cron expression |
|---|---|
| Every minute | `* * * * *` |
| Every 10 minutes | `*/10 * * * *` |
| Every hour | `0 * * * *` |
| Every day at 9 AM | `0 9 * * *` |

### Deploying on a different/new server
If you move this project to another server, update **two things** before scheduling cron:
1. The full path inside the crontab line itself (Step 3 above) — it must match where you cloned the repo on the new server.
2. The `DISK_FLAG`, `MEM_FLAG`, `CPU_FLAG` paths inside `alert.sh` — these should also point to a writable location on that server (commonly the same folder as the script).

---

## Troubleshooting

**`Permission denied` in cron log**
The script isn't executable. Fix:
```bash
chmod +x /full/path/to/alert.sh
```

**`No such file or directory` in cron log**
The path in your crontab doesn't match where the script actually is, or the log file's parent directory doesn't exist. Double-check with:
```bash
pwd
ls -l alert.sh
```
and make sure the crontab line uses that exact path.

**Script runs manually but not via cron**
Cron uses a minimal environment (limited `$PATH`, no aliases, no working directory). Always use full absolute paths in the crontab line — this is the most common cause of "works manually, fails in cron."

**No emails arriving at all**
Test mail delivery directly, outside the script:
```bash
echo "test" | mail -s "test" your-email@example.com
```
If this doesn't arrive, the issue is with your mail server setup (Postfix/sendmail), not the script.

**Same alert keeps arriving every run**
Check whether the relevant flag file actually exists after an alert fires:
```bash
ls -l /path/to/disk_alert.flag
```
If it's missing even though usage is still above threshold, double-check that the `touch` line in that section of the script points to the correct flag variable for that metric.

---

## Use Cases

- Production Support monitoring
- Linux server health checks
- Infrastructure monitoring
- Learning shell scripting and automation
- Resume / portfolio project for Production Support and Linux Administration roles

---

## Future Enhancements

- [ ] Apply alert-once logic to service monitoring (httpd/sshd/crond) — currently only Disk/Memory/CPU have it
- [ ] Monitor multiple filesystems, not just `/`
- [ ] Load average monitoring
- [ ] Include top CPU/Memory consuming processes in alert emails
- [ ] Consolidated single alert email instead of separate emails per metric
- [ ] Move configuration into a separate `config.conf` file, sourced by the script
- [ ] systemd timer as an alternative to cron

---

## Author

**Nitin**
Production Support Engineer | Linux | Shell Scripting | Oracle Database

GitHub: [nitinoneview](https://github.com/nitinoneview)
