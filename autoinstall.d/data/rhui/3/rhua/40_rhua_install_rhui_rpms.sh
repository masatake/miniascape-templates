#! /bin/bash
#
# Install RHUI Installer RPM
#
# Prerequisites:
# - Access to yum repos of RHEL, RHUI and RH Gluster Storage
# 
set -ex
source ${0%/*}/config.sh   # RHUI_STORAGE_TYPE

test "x${RHUI_STORAGE_TYPE:?}" = "xglusterfs" && \
yum install -y --enablerepo=rhgs-3.3 rhui-installer glusterfs-fuse || \
yum install -y rhui-installer

# Check
rpm -q rhui-installer
rhui-installer --help

# vim:sw=4:ts=4:et:
