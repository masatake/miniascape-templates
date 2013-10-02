#! /bin/bash
# see also virt-install(1)
#
{%- macro net_option(nic) -%}
network={{ nic.network|default('network') }},model={{ nic.model|default('virtio') }},mac={{ nic.mac|default('RANDOM') }}
{%- endmacro -%}
{%- set virtio_scsi = false -%}{# use virtio-scsi if possible -#}
{%- macro disk_option(disk, create=true) -%}
{%-     if disk.pool is defined -%}
{%-         if disk.vol is defined %}vol={{ disk.pool }}/{{ disk.vol }}{% else %}pool={{ disk.pool }}{% endif -%}
{%-     else %}path={{ disk.path }}
{%-     endif -%}
,format={{ disk.format|default('qcow2') }},cache={{ disk.cache|default('none') }}
{%-     if create %},size={{ disk.size|default('5') }}{% endif -%}{# use pre-built volume if not 'create' flag is set. #}
{%-     if disk.perms is defined %},perms={{ disk.perms }}{% endif -%}
{%-     if disk.format == 'raw' and disk.sparse is defined %},sparse={% if disk.sparse %}true{% else %}false{% endif %}{% endif -%},bus='scsi'
{%- endmacro %}
set -ex
{% block kscfg %}test $# -gt 0 && ks_path=$1 || ks_path=${0%/*}/ks.cfg
kscfg=${ks_path##*/}{% endblock %}
{% block location %}location={{ virtinst.location }}{% endblock %}

virt-install \
{{ virtinst.basic_options }} \
--name={% if name_prefix is defined %}{{ name_prefix }}{% endif %}{% if name is defined %}{{ name }}{% else %}{{ hostname }}{% endif %} \
--connect={{ virtinst.connect }} \
--wait={{ virtinst.waittime }} \
--ram={{ virtinst.ram }} \
--arch={{ virtinst.arch }} \
--vcpus={{ virtinst.vcpus }} {% if virtinst.cpu is defined %}--cpu {{ virtinst.cpu }}{% endif %} \
--graphics {{ virtinst.graphics }} \
--os-type={{ virtinst.os_type }} \
--os-variant={{ virtinst.os_variant }} \
{% if virtinst.cdrom %}--cdrom {{ virtinst.cdrom }}{% if virtinst.extra_args is defined and false %} --extra-args="{{ virtinst.extra_args }}"{% endif %}{% else %}--location=${location} --initrd-inject=${ks_path} --extra-args="ks=file:/${kscfg} ksdevice={{ ksdevice|default('eth0') }} {{ virtinst.extra_args|default('') }}"{% endif %} \
--controller type=scsi,model=virtio-scsi \
{% for disk in disks %}--disk {{ disk_option(disk) }} {% endfor %} \
{% for nic in interfaces %}--network {{ net_option(nic) }} {% endfor %}
