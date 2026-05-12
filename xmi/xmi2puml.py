#!/usr/bin/env python3
"""Emit one PlantUML class diagram per UML Package in the given XMI files.

PlantUML's `-txmi` flag is export-only — it has no XMI importer. This script
is the minimum shim needed to render the DMN metamodel with PlantUML: it walks
`<uml:Package>` nodes and emits `.puml` text (classes, attributes, enums,
generalizations, associations). PlantUML + Graphviz do the actual layout.

Scope intentionally narrow:
  * Eclipse UML2 / MOF / StandardProfile extensions outside the OMG UML 2.5.1
    metamodel are ignored.
  * Visibility, ordering, derivation, qualifiers, and association classes are
    not modeled — they're not used by the DMN metamodel.
"""
from __future__ import annotations

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field

XMI_NS = "http://www.omg.org/spec/XMI/20131001"
XMI_TYPE = f"{{{XMI_NS}}}type"
XMI_ID = f"{{{XMI_NS}}}id"
XMI_IDREF = f"{{{XMI_NS}}}idref"


@dataclass
class Property:
    name: str
    type_id: str | None
    type_href: str | None
    lower: str = "1"
    upper: str = "1"
    is_static: bool = False
    is_derived: bool = False
    association_id: str | None = None
    aggregation: str | None = None  # "none" | "shared" | "composite"


@dataclass
class Class:
    xmi_id: str
    name: str
    package: str
    is_abstract: bool = False
    attributes: list[Property] = field(default_factory=list)
    generalizations: list[str] = field(default_factory=list)  # parent xmi:ids


@dataclass
class Enum:
    xmi_id: str
    name: str
    package: str
    literals: list[str] = field(default_factory=list)


@dataclass
class Association:
    xmi_id: str
    name: str
    package: str
    member_ends: list[str] = field(default_factory=list)  # property xmi:ids


@dataclass
class Model:
    # Indexed by xmi:id where useful
    classes: dict[str, Class] = field(default_factory=dict)
    enums: dict[str, Enum] = field(default_factory=dict)
    primitive_names: dict[str, str] = field(default_factory=dict)  # id -> name
    associations: dict[str, Association] = field(default_factory=dict)
    properties: dict[str, Property] = field(default_factory=dict)
    # Owning class for each property (for non-association ends, this is the class).
    # For association-owned ends, this maps to "<assoc>" sentinel.
    property_owner_class: dict[str, str] = field(default_factory=dict)
    packages: list[str] = field(default_factory=list)


def literal_value(node: ET.Element, default: str) -> str:
    """Return a uml:LiteralInteger / LiteralUnlimitedNatural string."""
    v = node.attrib.get("value")
    if v is not None:
        return v
    # Missing value attr means "0" for LiteralInteger and "1" for upper bound default.
    return default


def parse_property(prop: ET.Element) -> Property:
    name = prop.attrib.get("name") or ""
    type_id = prop.attrib.get("type")
    type_href = None
    lower, upper = "1", "1"
    for child in prop:
        tag = child.tag.split("}", 1)[-1]
        if tag == "type" and type_id is None:
            type_href = child.attrib.get("href")
        elif tag == "lowerValue":
            lower = literal_value(child, "0")
        elif tag == "upperValue":
            upper = literal_value(child, "1")
    return Property(
        name=name,
        type_id=type_id,
        type_href=type_href,
        lower=lower,
        upper=upper,
        is_static=prop.attrib.get("isStatic") == "true",
        is_derived=prop.attrib.get("isDerived") == "true",
        association_id=prop.attrib.get("association"),
        aggregation=prop.attrib.get("aggregation"),
    )


def walk_package(node: ET.Element, pkg_name: str, model: Model) -> None:
    """Recurse into a package, indexing classes/enums/associations/properties."""
    model.packages.append(pkg_name)
    for child in node:
        t = child.attrib.get(XMI_TYPE, "")
        cid = child.attrib.get(XMI_ID, "")
        name = child.attrib.get("name", "")
        if t == "uml:Package":
            walk_package(child, name, model)
        elif t == "uml:Class":
            cls = Class(
                xmi_id=cid,
                name=name,
                package=pkg_name,
                is_abstract=child.attrib.get("isAbstract") == "true",
            )
            for ch in child:
                tt = ch.attrib.get(XMI_TYPE, "")
                if tt == "uml:Property":
                    p = parse_property(ch)
                    pid = ch.attrib.get(XMI_ID, "")
                    cls.attributes.append(p)
                    model.properties[pid] = p
                    model.property_owner_class[pid] = cid
                elif tt == "uml:Generalization":
                    parent = ch.attrib.get("general")
                    if parent:
                        cls.generalizations.append(parent)
            model.classes[cid] = cls
        elif t == "uml:Enumeration":
            e = Enum(xmi_id=cid, name=name, package=pkg_name)
            for ch in child:
                if ch.attrib.get(XMI_TYPE, "") == "uml:EnumerationLiteral":
                    lit = ch.attrib.get("name", "")
                    if lit:
                        e.literals.append(lit)
            model.enums[cid] = e
        elif t == "uml:PrimitiveType":
            model.primitive_names[cid] = name or "PrimitiveType"
        elif t == "uml:Association":
            a = Association(xmi_id=cid, name=name, package=pkg_name)
            for ch in child:
                tag = ch.tag.split("}", 1)[-1]
                tt = ch.attrib.get(XMI_TYPE, "")
                if tag == "memberEnd":
                    ref = ch.attrib.get(XMI_IDREF)
                    if ref:
                        a.member_ends.append(ref)
                elif tag == "ownedEnd" and tt == "uml:Property":
                    p = parse_property(ch)
                    pid = ch.attrib.get(XMI_ID, "")
                    model.properties[pid] = p
                    model.property_owner_class[pid] = "<assoc>"
            model.associations[cid] = a


def parse_xmi(path: str) -> Model:
    model = Model()
    root = ET.parse(path).getroot()
    # Top-level uml:Package(s) under xmi:XMI
    for child in root:
        if child.attrib.get(XMI_TYPE, "") == "uml:Package":
            walk_package(child, child.attrib.get("name", "(root)"), model)
    return model


# ---------- PlantUML emission ----------

def short_id(ref: str) -> str:
    """Return a PlantUML-safe alias from an xmi:id."""
    return "C_" + ref.replace("-", "_").replace(".", "_").replace("/", "_")


def primitive_from_href(href: str | None) -> str:
    if not href:
        return "Object"
    return href.rsplit("#", 1)[-1]


def resolve_type(prop: Property, model: Model, all_models: list[Model]) -> tuple[str, bool]:
    """Return (label, is_external_class).

    `is_external_class` is True if the type is a UML Class declared in another
    model file — used to decide whether to draw an association arrow or just
    print the type label.
    """
    if prop.type_href:
        return primitive_from_href(prop.type_href), False
    tid = prop.type_id
    if not tid:
        return "Object", False
    for m in all_models:
        if tid in m.classes:
            return m.classes[tid].name, m is not model
        if tid in m.enums:
            return m.enums[tid].name, m is not model
        if tid in m.primitive_names:
            return m.primitive_names[tid], False
    return "Object", False


def multiplicity(lower: str, upper: str) -> str:
    if lower == upper:
        return lower
    return f"{lower}..{upper}"


def emit_file_puml(
    diagram_name: str,
    model: Model,
    all_models: list[Model],
    title: str,
) -> str:
    """Emit one PlantUML class diagram covering every package in `model`.

    Each UML Package becomes a `package "<name>" { ... }` block. Classes with
    no `name` attribute (XMI stubs) are skipped, along with any generalization
    edges that target them. Generalizations and associations are emitted at
    the top level so they can cross package boundaries.
    """
    # All named classes / enums / associations across packages in this file.
    classes = [c for c in model.classes.values() if c.name]
    class_ids = {c.xmi_id for c in classes}
    assoc_ids = {a.xmi_id for a in model.associations.values()}

    # Group by package, preserving declaration order.
    by_pkg_classes: dict[str, list[Class]] = {p: [] for p in model.packages}
    by_pkg_enums: dict[str, list[Enum]] = {p: [] for p in model.packages}
    for c in classes:
        by_pkg_classes.setdefault(c.package, []).append(c)
    for e in model.enums.values():
        by_pkg_enums.setdefault(e.package, []).append(e)

    out: list[str] = []
    out.append(f"@startuml {diagram_name}")
    out.append(f"title {title}")
    out.append("hide empty members")
    out.append("skinparam classAttributeIconSize 0")
    out.append("skinparam linetype ortho")
    out.append("left to right direction")
    out.append("")

    # Class / enum declarations, grouped by package.
    for pkg in model.packages:
        pkg_classes = by_pkg_classes.get(pkg, [])
        pkg_enums = by_pkg_enums.get(pkg, [])
        if not pkg_classes and not pkg_enums:
            continue
        out.append(f'package "{pkg}" {{')
        for c in sorted(pkg_classes, key=lambda x: x.name):
            mod = "abstract " if c.is_abstract else ""
            out.append(f'  {mod}class "{c.name}" as {short_id(c.xmi_id)} {{')
            for a in c.attributes:
                # Class-typed attributes become arrows; skip them inline.
                if a.type_id and a.type_id in class_ids:
                    continue
                type_label, _ = resolve_type(a, model, all_models)
                mult = multiplicity(a.lower, a.upper)
                mult_part = f" [{mult}]" if mult not in ("1", "1..1") else ""
                out.append(f"    +{a.name} : {type_label}{mult_part}")
            out.append("  }")
        for e in sorted(pkg_enums, key=lambda x: x.name):
            out.append(f'  enum "{e.name}" as {short_id(e.xmi_id)} {{')
            for lit in e.literals:
                out.append(f"    {lit}")
            out.append("  }")
        out.append("}")
        out.append("")

    # Generalizations (cross-package safe — both ends already declared above).
    for c in classes:
        for parent_id in c.generalizations:
            if parent_id not in class_ids:
                continue
            out.append(f"{short_id(parent_id)} <|-- {short_id(c.xmi_id)}")
    out.append("")

    # Class-typed attributes that don't belong to a formal Association.
    for c in classes:
        for a in c.attributes:
            if not a.type_id or a.type_id not in class_ids:
                continue
            if a.association_id and a.association_id in assoc_ids:
                continue
            mult = multiplicity(a.lower, a.upper)
            arrow = "*-->" if a.aggregation == "composite" else (
                "o-->" if a.aggregation == "shared" else "-->"
            )
            label_part = f" : {a.name}" if a.name else ""
            out.append(
                f'{short_id(c.xmi_id)} {arrow} "{mult}" {short_id(a.type_id)}{label_part}'
            )
    out.append("")

    # Formal Associations (binary only — DMN metamodel has no n-ary).
    for a in model.associations.values():
        if len(a.member_ends) != 2:
            continue
        e1_id, e2_id = a.member_ends
        e1 = model.properties.get(e1_id)
        e2 = model.properties.get(e2_id)
        if not (e1 and e2):
            continue
        own1 = model.property_owner_class.get(e1_id, "<assoc>")
        own2 = model.property_owner_class.get(e2_id, "<assoc>")
        if own1 != "<assoc>" and own2 != "<assoc>":
            src, tgt, role = own1, own2, e2
        elif own1 != "<assoc>":
            src, tgt, role = own1, e1.type_id, e1
        elif own2 != "<assoc>":
            src, tgt, role = own2, e2.type_id, e2
        else:
            src, tgt, role = e1.type_id, e2.type_id, e2
        if not (src and tgt and src in class_ids and tgt in class_ids):
            continue
        arrow = "*-->" if role.aggregation == "composite" else (
            "o-->" if role.aggregation == "shared" else "-->"
        )
        mult = multiplicity(role.lower, role.upper)
        label = role.name or a.name or ""
        label_part = f" : {label}" if label else ""
        out.append(
            f'{short_id(src)} {arrow} "{mult}" {short_id(tgt)}{label_part}'
        )

    out.append("")
    out.append("@enduml")
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("xmi", nargs="+", help="Input XMI files")
    ap.add_argument("-o", "--out", required=True, help="Output directory for .puml files")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    models = [parse_xmi(p) for p in args.xmi]

    written = []
    for src, model in zip(args.xmi, models):
        src_base = os.path.splitext(os.path.basename(src))[0]
        puml = emit_file_puml(src_base, model, models, src_base)
        out_path = os.path.join(args.out, f"{src_base}.puml")
        with open(out_path, "w") as f:
            f.write(puml)
        written.append(out_path)

    for p in written:
        print(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
