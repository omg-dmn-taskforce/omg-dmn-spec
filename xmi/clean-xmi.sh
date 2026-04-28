#!/bin/sh
sed -i 's/DMN16.xmi/DMN.xmi/' *.xmi # in shortDescription
sed -i 's/DMNDI15.xmi/DMNDI.xmi/' *.xmi # in shortDescription
sed -i 's/version 20230324/version 20260504/' *.xmi # in shortDescription
# namespace without HTTPS
sed -i 's#xmlns:uml="http://www.omg.org/spec/UML/20131001"#xmlns:uml="http://www.omg.org/spec/UML/20161101"#' *.xmi
# XMI file with HTTPS
sed -i 's#http://www.omg.org/spec/UML/20131001/PrimitiveTypes.xmi#https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#' *.xmi
