# Local validation of XMI files against the (locally patched) XMI.xsd.
# See xsd/XMI.xsd for the list of patches vs. the upstream OMG schema.

XMIS := $(wildcard *.xmi)

.PHONY: all validate lint

all: lint validate

lint:
	xmllint --noout $(XMIS)

validate:
	@for f in $(XMIS); do \
		xmllint --noout --schema XMI.xsd "$$f" || exit 1; \
	done
