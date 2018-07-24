#! /bin/bash
#
# An experimental and temporary workaround for rhbz#1593218.
#
# Author: Satoru SATOH <ssato@redhat.com>
# License: MIT
#
set -e

REPOS_TOPDIR=/var/lib/rhui/remote_share/published/yum/master/yum_distributor/
KEEP=1  # How many recent updateinfo.xml.gz are kept.
DO_REMOVE=no

function show_help () {
    cat << EOH
Usage: $0 [Options...]
Options:
    -k KEEP_NUM   Number of recent updateinfo.xml.gz files to keep,
                  must be greater than 1. [${KEEP}]
    -r            Remove older updateinfo.xml.gz files instead of print them.
    -h            Show this help.
EOH
}

while getopts k:rh OPT
do
    case "${OPT}" in
        k) KEEP=${OPTARG}
           ;;
        r) DO_REMOVE=yes
           ;;
        h) show_help; exit 0
           ;;
        \?) echo "Invalid option!" > /dev/stderr; exit 1
           ;;
    esac
done
shift $((OPTIND - 1))

for repodata_dir in ${REPOS_TOPDIR:?}/*/*/repodata/; do
    removes=$(ls -1t ${repodata_dir}/*-updateinfo.xml.gz | sed "${KEEP:?}d")
    [[ ${DO_REMOVE:?} = "yes" ]] && rm -f ${removes} || {
        _removes=$(echo ${removes} | sed -nr '/[[:blank:]]+/d')
        [[ -n ${_removes} ]] && echo ${_removes} || :
    }
done

# vim:sw=4:ts=4:et: