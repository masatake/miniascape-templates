#! /bin/bash
set -x
logdir=/root/setup/logs
logfile=${logdir}/check.sh.log.$(date +%F_%H%M%S)
test -d ${logdir:?} || mkdir -p ${logdir}
(
cat /etc/redhat-release
uname -a
hostname; hostname -s; hostname -f || :
date
cat /proc/cmdline
which chronyc && \
(systemctl status chronyd && systemctl is-enabled chronyd && chronyc sources; chronyc tracking) || \
(which ntpq && systemctl status ntpd && systemctl is-enabled ntpd && ntptime)
/sbin/ip a
/sbin/ip r
df -h
mount -t ext3,ext4,xfs,nfs,vfat,cifs,iso9660 || mount
cat /etc/fstab
for x in pvscan vgscan lvscan; do which $x 2>/dev/null >/dev/null && $x || :; done
free
swapon --summary
test -f /etc/kdump.conf && grep -Ev '^#' /etc/kdump.conf || :
which gendiff 2>/dev/null && gendiff /etc .save || :
for f in $(ls -1t /etc/sysconfig/network-scripts/{ifcfg-*,route*} 2>/dev/null); do
    echo "# ${f##*/}:"
    cat $f
done
for f in $(ls -1 /etc/sysctl.d/*.conf 2>/dev/null); do
    echo "# ${f}:"; cat $f
done
sysctl -a > ${logdir}/sysctl-a.txt 2>/dev/null
for f in $(ls -1 /etc/sudoers.d/* 2>/dev/null); do
    echo "# ${f}:"; cat $f
done
rpm -qa --qf "%{n},%{v},%{r},%{arch},%{e}\n" | sort > ${logdir}/rpm-qa.0.txt
svcs="{{ services.enabled|join(' ')|default('sshd') }}"
test -d /etc/systemd && \
(systemctl list-unit-files --state=enabled; systemctl --failed; for s in $svcs; do systemctl status $s; done) || \
(/sbin/chkconfig --list; for s in $svcs; do service $s status; done)
test -d /etc/yum.repos.d && (
ls -1 /etc/yum.repos.d/*.repo 2>/dev/null || :
which yum >/dev/null && timeout 10 yum repolist || (which dnf >/dev/null && timeout 10 dnf repolist || :)
) || :
users="root {% for u in kickstart.users if kickstart and kickstart.users and u.name %}{{ u.name }} {% endfor %}"
for u in ${users};do id ${u} || :; done
test -d /root/setup && ls -lh /root/setup || :
test -d /root/setup/checks.d && (
for f in $(ls -1 /root/setup/checks.d/[0-9]*.sh); do chmod +x $f; $f; done
)
) 2>&1 | tee ${logfile}
