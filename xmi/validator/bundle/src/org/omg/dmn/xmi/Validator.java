package org.omg.dmn.xmi;

import java.io.File;

import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.URIConverter;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.uml2.uml.UMLPackage;
import org.eclipse.uml2.uml.resource.UMLResource;

/**
 * Equinox application entry point. Loads each OMG-published UML 2.5.1 XMI file
 * passed as an argument, runs the EMF {@link Diagnostician} on every root
 * {@link EObject}, and reports diagnostics. Exit code 1 on error, 0 on success.
 *
 * URI redirection policy applied at startup:
 *   - OMG namespace URI for UML 2.5.1 → Eclipse UML2's UMLPackage (so that
 *     <code>xmi:type="uml:Property"</code> etc. resolves to the typed metamodel).
 *   - The future-version OMG URLs declared by this repository's XMI files
 *     (https://www.omg.org/spec/DMN/{date}/DMN.xmi and DMNDI.xmi) → local files.
 *     These are work-in-progress versions not yet published to omg.org.
 *   - Stable external OMG URLs (PrimitiveTypes.xmi etc.) are left alone and
 *     fetched live by EMF's default URIConverter when proxies resolve.
 */
public final class Validator implements IApplication {

    @Override
    public Object start(IApplicationContext context) {
        Object rawArgs = context.getArguments().get(IApplicationContext.APPLICATION_ARGS);
        String[] args = rawArgs instanceof String[] ? (String[]) rawArgs : new String[0];
        if (args.length == 0) {
            System.err.println("usage: Validator <xmi-file>...");
            return Integer.valueOf(2);
        }

        registerUMLPackages();
        registerLocalRedirects(args);

        int errors = 0;
        for (String arg : args) {
            File f = new File(arg);
            if (!f.exists()) {
                System.err.println(arg + ": file not found");
                errors++;
                continue;
            }
            errors += validate(f);
        }
        return errors > 0 ? Integer.valueOf(1) : IApplication.EXIT_OK;
    }

    @Override
    public void stop() {}

    private static void registerUMLPackages() {
        EPackage.Registry.INSTANCE.put(UMLPackage.eNS_URI, UMLPackage.eINSTANCE);
        EPackage.Registry.INSTANCE.put(
                "http://www.omg.org/spec/UML/20161101", UMLPackage.eINSTANCE);
        Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap()
                .put("xmi", UMLResource.Factory.INSTANCE);
        Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap()
                .put("uml", UMLResource.Factory.INSTANCE);
    }

    private static void registerLocalRedirects(String[] args) {
        for (String arg : args) {
            File f = new File(arg);
            if (!f.exists()) continue;
            URI fileUri = URI.createFileURI(f.getAbsolutePath());
            String name = f.getName();
            if (name.startsWith("DMN16") || name.equals("DMN.xmi")) {
                URIConverter.URI_MAP.put(
                        URI.createURI("https://www.omg.org/spec/DMN/20260504/DMN.xmi"),
                        fileUri);
            }
            if (name.startsWith("DMNDI15") || name.equals("DMNDI.xmi")) {
                URIConverter.URI_MAP.put(
                        URI.createURI("https://www.omg.org/spec/DMN/20260504/DMNDI.xmi"),
                        fileUri);
            }
        }
    }

    private static int validate(File f) {
        System.out.println("== " + f.getPath() + " ==");

        ResourceSet rs = new ResourceSetImpl();
        // Pin the UML resource factory on this ResourceSet's local registry —
        // the global registry doesn't always propagate to a fresh ResourceSet
        // in OSGi mode, and we need UMLResource.Factory specifically (not the
        // generic XMIResourceFactory) to get UML-aware loading.
        rs.getResourceFactoryRegistry().getExtensionToFactoryMap()
                .put("xmi", UMLResource.Factory.INSTANCE);
        rs.getResourceFactoryRegistry().getExtensionToFactoryMap()
                .put("uml", UMLResource.Factory.INSTANCE);
        rs.getPackageRegistry().put(UMLPackage.eNS_URI, UMLPackage.eINSTANCE);
        rs.getPackageRegistry().put("http://www.omg.org/spec/UML/20161101", UMLPackage.eINSTANCE);

        Resource res;
        try {
            res = rs.getResource(URI.createFileURI(f.getAbsolutePath()), true);
        } catch (Exception e) {
            System.err.println("  failed to load: " + e.getMessage());
            return 1;
        }
        EcoreUtil.resolveAll(res);

        int errors = 0;
        for (EObject root : res.getContents()) {
            Diagnostic d = Diagnostician.INSTANCE.validate(root);
            errors += report(d, "  ");
        }
        if (errors == 0) {
            System.out.println("  validates");
        }
        return errors;
    }

    private static int report(Diagnostic d, String indent) {
        int errors = 0;
        if (d.getSeverity() != Diagnostic.OK) {
            String msg = d.getMessage() == null ? "" : d.getMessage();
            // Filter mofext noise — we deliberately don't register that EPackage.
            if (!msg.contains("MOF/20131001") && !msg.contains("mofext")) {
                System.out.println(indent + "[" + sevName(d.getSeverity()) + "]"
                        + sourceTag(d) + " " + msg);
                if (d.getSeverity() == Diagnostic.ERROR) {
                    errors++;
                }
            }
        }
        for (Diagnostic c : d.getChildren()) {
            errors += report(c, indent + "  ");
        }
        return errors;
    }

    private static String sourceTag(Diagnostic d) {
        for (Object data : d.getData()) {
            if (data instanceof EObject e) {
                String id = EcoreUtil.getID(e);
                StringBuilder sb = new StringBuilder(" {").append(e.eClass().getName());
                if (id != null) {
                    sb.append(" id=").append(id);
                }
                return sb.append('}').toString();
            }
        }
        return "";
    }

    private static String sevName(int sev) {
        return switch (sev) {
            case Diagnostic.OK -> "OK";
            case Diagnostic.INFO -> "INFO";
            case Diagnostic.WARNING -> "WARNING";
            case Diagnostic.ERROR -> "ERROR";
            case Diagnostic.CANCEL -> "CANCEL";
            default -> "UNKNOWN(" + sev + ")";
        };
    }
}
