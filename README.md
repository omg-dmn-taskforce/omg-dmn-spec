Machine-readable files of OMG's DMN specification
=================================================

How we work in this repository
------------------------------

Numbers of issues and proposals MUST be referenced in commit messages:

    DMN11-30/DMN11-95 Add Definitions/@exporter, @exporterVersion
    

For each ballot we create a new branch based on the previous ballot:

    git checkout -b ballot-04

Each JIRA issue of a ballot contains links to Git commits. These commits are cherry-picked into the branch for the ballot:

    git cherry-pick --edit -x --signoff a34075294278990316f877c5549d02ed6829f058

One can check if an issue is mentioned in a commit using:

    git log --all --grep 89
    git log --all --grep 11-89

The branch for the ballot is pushed to GitHub using:

    git push --set-upstream origin ballot-04

In the commit message one may add links back to JIRA:

```
Issue: http://solitaire.omg.org/browse/DMN11-30
Proposal: http://solitaire.omg.org/browse/DMN11-95
```

Committing changes on behalf of someone else:

    git commit --author="Bruce Silver <bruce@example.com>" --template=commit-message-template.txt
    git commit --author="Bruce Silver <bruce@example.com>" --reedit-message=HEAD