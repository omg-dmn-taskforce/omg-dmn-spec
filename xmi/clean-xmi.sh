#!/bin/sh
sed -i 's/DMN16.xmi/DMN.xmi/' *.xmi # in shortDescription
sed -i 's/DMNDI15.xmi/DMNDI.xmi/' *.xmi # in shortDescription
sed -i 's/version 20230324/version 20260504/' *.xmi # in shortDescription
# namespace without HTTPS
sed -i 's#xmlns:uml="http://www.omg.org/spec/UML/20131001"#xmlns:uml="http://www.omg.org/spec/UML/20161101"#' *.xmi
# XMI file with HTTPS
sed -i 's#http://www.omg.org/spec/UML/20131001/PrimitiveTypes.xmi#https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#' *.xmi
# Leftover MagicDraw stereotype-property type references — replace with the
# canonical OMG PrimitiveTypes equivalents.
#   eee_1045467100323_191782_59 = StandardProfile Boolean (used by useAlternativeInputDataShape)
#   eee_1045467100323_917313_65 = StandardProfile Integer (used by red/green/blue color components)
sed -i 's%UML_Standard_Profile.mdzip#eee_1045467100323_191782_59%https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#Boolean%g' *.xmi
sed -i 's%UML_Standard_Profile.mdzip#eee_1045467100323_917313_65%https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#Integer%g' *.xmi
# Add xmi:type="uml:PrimitiveType" to element-form <type href="…/PrimitiveTypes.xmi#…"/>
# references. Without this, Eclipse UML2's XMI loader can't determine the proxy's
# concrete EClass during parse (UML.Type, the metamodel reference target, is
# abstract → AnyType fallback → IllegalValueException). MagicDraw doesn't emit
# the xmi:type attribute on these elements; the OMG XMI spec allows it, and
# every primitive on PrimitiveTypes.xmi is a uml:PrimitiveType.
sed -i 's%<type href="https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#%<type xmi:type="uml:PrimitiveType" href="https://www.omg.org/spec/UML/20161101/PrimitiveTypes.xmi#%g' *.xmi
