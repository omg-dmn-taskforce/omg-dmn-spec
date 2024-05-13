#!/bin/bash
set -euxo pipefail

# recursively search all DMN and XSD files in the current directory and migtrate them
# from an old set of namespace to a new set of namespaces
# requires `sponge` which can be installed via `sudo apt install moreutils`
# usage: run `xsd/migrate-to-new-namespaces.sh` from the root of the project

XSD_DIR="$(dirname $0)"

source "$XSD_DIR/dmn-namespace-utils.sh"

#find_dmn13_files() {
#    grep -Hirl $DMN13 --exclude='*.biodi.dmn' --exclude='test-xsd*' --exclude='dmn-namespace-utils.sh' --exclude='migrate-to-new-namespaces.sh' --exclude='DMN13.xsd' --exclude-dir=.git --exclude-dir=target
#}

#find_dmn13_files

# (grep -Hirl 'http://www.omg.org/spec/DMN/20151101/dmn.xsd' --exclude='*.biodi.dmn' --exclude='test-xsd*' --exclude='migrate-to-new-namespaces.sh' --exclude='DMN12.xsd' && find -iname '*.xsd') | xargs sed -i \
#   -e 's#http://www.omg.org/spec/DMN/20151101/dmn.xsd#http://www.omg.org/spec/DMN/20180521/MODEL/#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DMNDI#http://www.omg.org/spec/DMN/20180521/DMNDI/#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DI#http://www.omg.org/spec/DMN/20180521/DI/#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DC#http://www.omg.org/spec/DMN/20180521/DC/#' \
#   -e 's#http://www.omg.org/spec/FEEL/20140401#http://www.omg.org/spec/DMN/20180521/FEEL/#'
  
# (grep -Hirl 'http://www.omg.org/spec/DMN/20151101/dmn.xsd' --exclude '*.biodi.dmn' --exclude='test-xsd*' && find -iname '*.xsd') | xargs sed -i \  
#   -e 's#http://www.omg.org/spec/DMN/20151101/dmn.xsd#http://www.omg.org/spec/DMN/20180521/DMN12.xsd#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DMNDI#http://www.omg.org/spec/DMN/20180521/DMNDI12.xsd#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DI#http://www.omg.org/spec/DMN/20180521/DI.xsd#' \
#   -e 's#http://www.omg.org/spec/DMN/20151101/DC#http://www.omg.org/spec/DMN/20180521/DC.xsd#'

# grep -Hirl 'http://www.omg.org/spec/FEEL/20140401' --exclude=DMN11.xsd  --exclude='migrate-to-new-namespaces.sh'
# grep -Hirl 'http://www.omg.org/spec/FEEL/20140401' --exclude=DMN11.xsd  --exclude='migrate-to-new-namespaces.sh' | xargs sed -i -e 's#http://www.omg.org/spec/FEEL/20140401#http://www.omg.org/spec/DMN/20180521/FEEL/#'

upgrade_dmn_13_to_dmn_14() {
    sed \
        -e "s#$DMN13#$DMN14#g" \
        -e "s#$FEEL13#$FEEL14#g" \
        "$1"
}

upgrade_dmn_14_to_dmn_15() {
    sed \
        -e "s#$DMN14#$DMN15#g" \
        -e "s#$FEEL14#$FEEL15#g" \
        -e "s#$DMNDI13#$DMNDI15#g" \
        "$1"
}

upgrade_dmn_15_to_dmn_16() {
    sed \
        -e "s#$DMN15#$DMN16#g" \
        -e "s#$FEEL15#$FEEL16#g" \
        "$1"
}

declare -i NUMBER_OF_FILES=0
while IFS= read -r -d '' DMN_FILE; do
    NUMBER_OF_FILES+=1
    echo "$NUMBER_OF_FILES: $DMN_FILE"
    upgrade_dmn_15_to_dmn_16 "$DMN_FILE" | sponge "$DMN_FILE"
done < <(find . '(' -iname '*.dmn*.xml' -or -iname '*.dmn' -or -name 'DMN*1*.xsd' ')' -type f -print0)
