mod_for_test_env ?= {% if test is defined %}{{ test.mod_for_test_env }}{% endif %}

all: netregist build

netregist: netregist.stamp
netregist.stamp: $(CURDIR)/net_register.sh
	bash -x $< && touch $@

build: build.stamp
build.stamp: $(CURDIR)/vmbuild.sh
	bash -x $< && touch $@

test-build: test-build.stamp
test-build.stamp: $(CURDIR)/vmbuild-test.sh $(CURDIR)/test.ks.cfg
	bash -x $< && touch $@

## For tests:
setup: $(CURDIR)/test.ks.cfg $(CURDIR)/vmbuild-test.sh

$(CURDIR)/test.ks.cfg: $(CURDIR)/ks.cfg
	$(mod_for_test_env) $< > $@.t && mv $@.t $@

$(CURDIR)/vmbuild-test.sh: $(CURDIR)/vmbuild.sh
	sed -e 's/ks.cfg/test.ks.cfg/g' $< | $(mod_for_test_env) > $@.t && mv $@.t $@

# make ks floppy:
floppy_iso_name ?= {{ '%s' % name_prefix if name_prefix }}{{ '%s' % hostname or name }}-kscfg.iso
floppy_flp_name ?= $(floppy_iso_name:.iso=.flp)

floppy: $(CURDIR)/$(floppy_flp_name)
$(CURDIR)/$(floppy_iso_name): $(CURDIR)/ks.cfg
	mkisofs -R -J -o $(floppy_iso_name) ks.cfg

$(CURDIR)/$(floppy_flp_name): $(CURDIR)/$(floppy_iso_name)
	ln -f $< $@

.PHONY: netregist build floppy
