#!/bin/sh
mv DMN15.xmi DMN16.xmi
sed -i 's#20230324/DMN15.xmi#20240513/DMN16.xmi#' DMN16.xmi # namespace
sed -i 's/DMN15.xmi/DMN16.xmi/' DMN16.xmi # in shortDescription
sed -i 's/version 20230324/version 20240513/' DMN16.xmi # in shortDescription
# namespace without HTTPS
sed -i 's#xmlns:uml="http://www.omg.org/spec/UML/20131001"#xmlns:uml="http://www.omg.org/spec/UML/20161101"#' DMN16.xmi
# XMI file with HTTPS
sed -i 's#http://www.omg.org/spec/UML/20131001/PrimitiveTypes.xmi#https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#' DMN16.xmi
