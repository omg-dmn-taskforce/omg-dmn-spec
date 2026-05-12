# Local validation of XMI files against the (locally patched) XMI.xsd.
# See XMI.xsd for the list of patches vs. the upstream OMG schema.

XMIS := $(wildcard *.xmi)
VALIDATOR_DIR := validator
DIAGRAMS_DIR := diagrams

# PlantUML is fetched once into a user cache. Override PLANTUML_JAR to point at
# an existing install (e.g. `brew install plantuml`'s shipped jar).
PLANTUML_VERSION ?= 1.2025.4
PLANTUML_CACHE ?= $(HOME)/.cache/plantuml
PLANTUML_JAR ?= $(PLANTUML_CACHE)/plantuml-$(PLANTUML_VERSION).jar
PLANTUML_URL := https://github.com/plantuml/plantuml/releases/download/v$(PLANTUML_VERSION)/plantuml-$(PLANTUML_VERSION).jar

PUMLS := $(patsubst %.xmi,$(DIAGRAMS_DIR)/%.puml,$(XMIS))
SVGS  := $(patsubst %.xmi,$(DIAGRAMS_DIR)/%.svg,$(XMIS))

.PHONY: all validate lint validate-uml clean-validator puml diagrams clean-diagrams

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

# Generate one .puml per XMI file (covering every UML package it declares),
# then render each as SVG via PlantUML.
puml: $(PUMLS)

$(DIAGRAMS_DIR)/%.puml: %.xmi xmi2puml.py
	@mkdir -p $(DIAGRAMS_DIR)
	@python3 xmi2puml.py $< -o $(DIAGRAMS_DIR)

diagrams: $(SVGS)

$(DIAGRAMS_DIR)/%.svg: $(DIAGRAMS_DIR)/%.puml $(PLANTUML_JAR)
	@java -jar $(PLANTUML_JAR) -tsvg -o $(realpath $(DIAGRAMS_DIR)) $<

$(PLANTUML_JAR):
	@mkdir -p $(PLANTUML_CACHE)
	@echo "Downloading PlantUML $(PLANTUML_VERSION) → $@"
	@curl -fsSL --retry 3 -o $@ $(PLANTUML_URL)

clean-diagrams:
	rm -rf $(DIAGRAMS_DIR)
