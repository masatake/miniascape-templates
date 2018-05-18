#! /bin/bash
#
# It does several things to setup RHUI on RHUA.
#
# Prerequisites:
# - rhui-installer was installed from RHUI ISO image
# - CDS are ready and accessible with ssh from RHUA w/o password
# - Gluster FS was setup in CDSes and ready to access from RHUA
#
set -ex

# RHUI_AUTH_OPT, RHUI_CLIENT_CERTS, RHUI_CLIENT_RPMS
source ${0%/*}/config.sh

RHUI_CLIENT_WORKDIR=${1:-/root/setup/clients/}
RHUI_CLIENT_RPMS_DIR=${RHUI_CLIENT_WORKDIR:?}/rpms
RHUI_AUTH_OPT=""  # Force set empty to avoid to password was printed.

# Generate RPM GPG Key pair to sign RHUI client config RPMs built
test -f ~/.rpmmacros || bash -x ${0%/*}/gen_rpm_gpgkey.sh


# List repos available to clients
rhui-manager ${RHUI_AUTH_OPT} client labels

mkdir -p ${RHUI_CLIENT_WORKDIR:?}
while read line
do
    test "x$line" = "x" && continue || :
    name=${line%% *}; repos=${line#* }
    rhui-manager ${RHUI_AUTH_OPT} client cert \
        --name ${name:?} --repo_label ${repos:?} \
        --days 3651 --dir ${RHUI_CLIENT_WORKDIR}/
done << EOC
${RHUI_CLIENT_CERTS:?}
EOC

mkdir -p ${RHUI_CLIENT_RPMS_DIR}
while read line
do
    test "x$line" = "x" && continue || :
    name=${line%% *}; version=${line#* }
    rhui-manager ${RHUI_AUTH_OPT} client rpm \
        --rpm_name ${name:?} --rpm_version ${version:?} \
        --entitlement_cert ${RHUI_CLIENT_WORKDIR}/${name}.crt \
        --private_key ${RHUI_CLIENT_WORKDIR}/${name}.key \
        --dir ${RHUI_CLIENT_RPMS_DIR}/
done << EOC
${RHUI_CLIENT_RPMS:?}
EOC

# Check
find ${RHUI_CLIENT_WORKDIR}/ -type f

# vim:sw=4:ts=4:et:
