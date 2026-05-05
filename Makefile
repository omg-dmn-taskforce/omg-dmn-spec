# Local validation of DMN XSDs and examples.
# Mirrors CI in .github/workflows/main.yml, but uses the XML catalog so that
# https://www.omg.org/spec/{DMN,SCE}/... schemaLocations resolve to local files.

export XML_CATALOG_FILES := $(CURDIR)/catalog.xml

.PHONY: all lint-xsd lint-examples lint-catalog validate ci-local package clean

all: lint-xsd lint-examples validate

lint-xsd:
	xmllint --noout xsd/*.xsd

# Checks well-formedness of both catalogs and verifies that every namespace
# mapping in xsd/catalog.xml resolves to the expected public URL.
lint-catalog:
	xmllint --noout catalog.xml xsd/catalog.xml
	@echo "Checking public catalog namespace mappings in xsd/catalog.xml:"
	@xmlcatalog xsd/catalog.xml "https://www.omg.org/spec/DMN/" | grep -v "^No entry for SYSTEM "
	@xmlcatalog xsd/catalog.xml "https://www.omg.org/spec/DMN/DMNDI/" | grep -v "^No entry for SYSTEM "
	@xmlcatalog xsd/catalog.xml "https://www.omg.org/spec/SCE/DI/" | grep -v "^No entry for SYSTEM "
	@xmlcatalog xsd/catalog.xml "https://www.omg.org/spec/SCE/DC/" | grep -v "^No entry for SYSTEM "

lint-examples:
	find examples -type f -name '*.dmn' -print0 | xargs -0 -n1 -t xmllint --noout

validate:
	find examples -type f -name '*.dmn' -print0 | xargs -0 -n1 -t xmllint --noout --schema xsd/DMN.xsd

# Run the GitHub Actions workflow locally in Docker via `act`
# (https://github.com/nektos/act). Requires Docker and `act` on PATH.
# Uses whatever runner image is pinned in ~/.config/act/actrc (act prompts
# on first run). xmllint-action is itself a Docker action, so the micro
# image (node:16-buster-slim) is sufficient.
ci-local:
	@command -v act >/dev/null || { echo "act not found — install from https://github.com/nektos/act"; exit 1; }
	act push --workflows .github/workflows/main.yml

package: submission submission/DMN-examples.zip submission/DMN-diagrams.zip
	cp -f xsd/*.xsd xsd/catalog.xml submission/
	cp -f xmi/*.xmi submission/
	cp -f xmi/*.mdzip submission/

submission:
	mkdir -p submission

submission/DMN-examples.zip: submission
	@command -v zip >/dev/null || { echo "zip not found"; exit 1; }
	rm -f $@
	cd examples && zip -rq ../$@ .

submission/DMN-diagrams.zip: submission
	@command -v zip >/dev/null || { echo "zip not found"; exit 1; }
	rm -f $@
	zip -jq $@ meta-model/*.svg

clean:
	rm -rf submission
