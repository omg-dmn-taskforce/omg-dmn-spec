# Local validation of XMI files against the (locally patched) XMI.xsd.
# See XMI.xsd for the list of patches vs. the upstream OMG schema.

XMIS := $(wildcard *.xmi)
VALIDATOR_DIR := validator

.PHONY: all validate lint validate-uml clean-validator

all: lint validate

lint:
	xmllint --noout $(XMIS)

validate:
	@for f in $(XMIS); do \
		xmllint --noout --schema XMI.xsd "$$f" || exit 1; \
	done

# UML semantic validation via Eclipse UML2 5.5+ resolved through Tycho from the
# Eclipse SimRel 2026-03 p2 repository. Requires Java 21 + Maven 3.9+. First
# run downloads ~150MB of Eclipse runtime; subsequent runs use the local cache.
# The Tycho reactor is built and its p2 site assembled via `mvn install`, then
# `tycho-eclipse-plugin:eclipse-run` is invoked explicitly with both repos visible.
validate-uml:
	@cd $(VALIDATOR_DIR) && mvn -q install
	@cd $(VALIDATOR_DIR) && mvn -q -pl . -N \
		org.eclipse.tycho:tycho-eclipse-plugin:eclipse-run \
		-Dxmi.dir=$(realpath .)

clean-validator:
	@cd $(VALIDATOR_DIR) && mvn -q clean
