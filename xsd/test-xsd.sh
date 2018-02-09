#!/bin/bash
# run this script in a directory that contains DMN XML files, e.g. the DMN TCK
# if the diff at the end shows any differences it could indicate an unintended BC break in the XSD

XSD_DIR="$(dirname $0)"

# setup a target dir for temporary files
TARGET_DIR="$XSD_DIR/target"
mkdir -p $TARGET_DIR

validate_as_dmn_11() {
    sed 's#http://www.omg.org/spec/DMN/20180521/MODEL/#http://www.omg.org/spec/DMN/20151101/dmn.xsd#' "$1" | xmllint --schema "$TARGET_DIR/DMN11.xsd" --noout -
}

validate_as_dmn_12() {
    sed 's#http://www.omg.org/spec/DMN/20151101/dmn.xsd#http://www.omg.org/spec/DMN/20180521/MODEL/#' "$1" | xmllint --schema "$XSD_DIR/dmn.xsd" --noout -
}

# download the official DMN 1.1 XML schema for comparison
if [ ! -f "$TARGET_DIR/DMN11.xsd" ]; then
    wget 'http://www.omg.org/spec/DMN/20151101/dmn.xsd' --output-document="$TARGET_DIR/DMN11.xsd" -nc
fi

echo "DMN 1.1 validation results:" > "$TARGET_DIR/validdmn11.log"
echo "DMN 1.2 validation results:" > "$TARGET_DIR/validdmn12.log"

# search all DMN files in the current directory and perform a schema validation with the DMN 1.1 and 1.2 schemas
declare -i NUMBER_OF_FILES=0
for DMN_FILE in $(find '(' -iname '*.dmn*.xml' -o -iname '*.dmn' ')' -type f)
do
    NUMBER_OF_FILES+=1
    echo $DMN_FILE >> "$TARGET_DIR/validdmn11.log"
    echo $DMN_FILE >> "$TARGET_DIR/validdmn12.log"
    validate_as_dmn_11 "$DMN_FILE" >> "$TARGET_DIR/validdmn11.log" 2>&1
    validate_as_dmn_12 "$DMN_FILE" >> "$TARGET_DIR/validdmn12.log" 2>&1
done

# filter out validation errors about intended changes in DMN 1.2
grep -vf "$XSD_DIR/test-xsd-ignore-list-11.txt" "$TARGET_DIR/validdmn11.log" > "$TARGET_DIR/validdmn11.filtered.log"
grep -vf "$XSD_DIR/test-xsd-ignore-list-12.txt" "$TARGET_DIR/validdmn12.log" > "$TARGET_DIR/validdmn12.filtered.log"

# adjust lists of expected elements
sed -i \
    -e 's#: This element is not expected. Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}elementCollection, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}businessContextElement, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}performanceIndicator, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}organizationUnit ).#: This element is not expected. Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}elementCollection, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}businessContextElement, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}performanceIndicator, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}organizationUnit, {http://www.omg.org/spec/DMN/20151101/DMNDI}DMNDI ).#' "$TARGET_DIR/validdmn11.filtered.log" \
    -e 's#: Missing child element(s). Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredDecision, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredInput ).#: Missing child element(s). Expected is one of ( {http://www.omg.org/spec/DMN/20151101/dmn.xsd}description, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}extensionElements, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredDecision, {http://www.omg.org/spec/DMN/20151101/dmn.xsd}requiredInput ).#' \
    -e 's#http://www.omg.org/spec/DMN/20151101/dmn.xsd#http://www.omg.org/spec/DMN/20180521/MODEL/#' \
    "$TARGET_DIR/validdmn11.filtered.log"

# compare the filtered log files
colordiff "$TARGET_DIR/validdmn11.filtered.log" "$TARGET_DIR/validdmn12.filtered.log"

echo "The comparison of XML validation results for $NUMBER_OF_FILES DMN files is done. If the output above shows any differences, it could indicate an unintended break of backwards compatibility in the DMN XML schema."
echo "For more details compare full unfiltered logs with a diff tool e.g.:"
echo "meld $TARGET_DIR/validdmn1?.log"
echo "meld $TARGET_DIR/validdmn1?.filtered.log"