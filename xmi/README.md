# DMN UML Meta Model

## XMI generation

- Ensure you have the Strict UML XMI Exporter plugin installed - under Help -> Resources/Plugins (no cost)
- open *.mdzip
- from File menu select Export to -> UML Clean XMI File
- make the Package the top level element, by deleting the uml:Model and changing packagedElement to be uml:Package (Hint: this can also be done be reverting changes in Git, e.g. when on a branch compare with master [VSCode right-click on file -> Open Changes -> Open Changes with Branch or Tag...])
- Run `./clean-xmi.sh`


