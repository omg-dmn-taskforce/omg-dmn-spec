# DMN UML Meta Model

## XMI generation

- Ensure you have the Strict UML XMI Exporter plugin installed - under Help -> Resources/Plugins (no cost)
- open *.mdzip
- from File menu select Export to -> UML Clean XMI File
- make the Package the top level element, by deleting the uml:Model and changing packagedElement to be uml:Package (Hint: this can also be done be reverting changes in Git, e.g. when on a branch compare with master [VSCode right-click on file -> Open Changes -> Open Changes with Branch or Tag...])
- Run `./clean-xmi.sh`

## Validation

`make` (or `make all`) runs envelope validation against the locally patched
`XMI.xsd`. See the patch comment at the top of `XMI.xsd` for what's modified
relative to the upstream OMG schema. This catches XMI structure issues
(`xmi:id` uniqueness, `xmi:idref` resolution, valid `xmi:XMI` shape) but
treats the UML / MOF / StandardProfile content as opaque (`xs:any`), so it
does NOT verify UML semantics like `Property.type` reference integrity,
`Generalization.general` resolution, or required-feature constraints.

### UML semantic validation

`make validate-uml` runs the EMF `Diagnostician` against the XMI files,
executing the UML 2.5.1 metamodel's OCL constraints. The validator is a
three-module Tycho project under `validator/`:

- `validator/bundle/` — the Equinox application (`Validator.java`,
  `plugin.xml`, `MANIFEST.MF`). Loads each XMI via Eclipse UML2 with the
  OMG namespace URIs aliased to Eclipse UML2's metamodel packages, redirects
  the future-version DMN/DMNDI OMG URLs to the local files in this
  repository, and walks the resulting model with `Diagnostician.INSTANCE`.
- `validator/repository/` — `eclipse-repository` packaging that aggregates
  the bundle into a local p2 site at `repository/target/repository/`.
- `validator/pom.xml` — parent that wires `tycho-eclipse-plugin:eclipse-run`
  against two p2 sources: the Eclipse SimRel `2026-03` composite (which
  brings in Eclipse UML2 5.5.x and EMF), and the local site above.

Two-pass orchestration via Make: `mvn install` builds the bundle and the
local p2 site; then `mvn ... eclipse-run -pl . -N` runs the application
against both p2 sources. Binding `eclipse-run` to a phase doesn't work
because the parent's lifecycle fires before children in reactor order.

Requires Java 21 + Maven 3.9. First `mvn install` downloads ~150MB of
Eclipse runtime artifacts into `~/.m2/repository/.cache/tycho`; subsequent
runs use the cache.

#### Why `clean-xmi.sh` adds `xmi:type="uml:PrimitiveType"` on `<type href=…>`

When parsing `<type href="…/PrimitiveTypes.xmi#String"/>`, Eclipse UML2's
loader needs to determine the proxy's EClass during parse. Without an
explicit `xmi:type` attribute it derives the EClass from the metamodel
reference target — `UML.Property.type` → `UML.Type`, which is abstract.
EMF refuses to instantiate abstract classifiers and falls back to
`AnyType`, which then fails the runtime type check on assignment to the
`type` reference. Adding `xmi:type="uml:PrimitiveType"` (which every entity
in `PrimitiveTypes.xmi` is) tells the loader the concrete type up-front and
sidesteps the fallback. The OMG XMI spec allows `xmi:type` on these
elements; MagicDraw simply doesn't emit it.


