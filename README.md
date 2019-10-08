Machine-readable files of OMG's DMN specification
=================================================

The main goal of working with GitHub is to have a clear diff for each change to the DMN XML schema that can be linked in the DMN RTF report.

## Namespace URIs

Namespace URIs will change in every schema file that changes in a revision.
The URIs are based on the RTF Report Due Date which can be found in the
[Work in Progress page](https://www.omg.org/schedule/) of the revision.
For example the DMN 1.3 RTF Report is due on November 11, 2019 and
therefore the Namespace URI is `https://www.omg.org/spec/DMN/20191111/MODEL/`.

How we work in this repository
------------------------------

* Each proposal (JIRA issue) that contains XSD changes MUST contain a link to a Git commit, before it is scheduled for a ballot.
* One commit per issue (if there is more they MUST be squashed with `git rebase`)
* Before an issue can go into a ballot it needs to me merged into the master branch, so that the link to a diff does not change any more
* [Tags](https://github.com/omg-dmn-taskforce/omg-dmn-spec/releases/tag/1.2-ballot-02) can be used to mark the results of ballots, after they are closed
* The order of commits within a ballot does not matter
* Commits of different ballots must be in the order of the ballots they belong to (`git rebase` can be used to reorder commits as needed)
* Commits that have not been in a ballot MUST appear after the ones that have been in ballots in the master branch
* JIRA MUST only reference one commit. If a commit as been amended, the link in JIRA needs to be changed, before the issue is scheduled for a ballot.
* Numbers of issues and proposals MUST be referenced in commit messages, e.g.:

        DMN11-30/DMN11-95 Add Definitions/@exporter, @exporterVersion

* In the commit message one MAY add links back to JIRA:

        Issue: http://solitaire.omg.org/browse/DMN11-30
        Proposal: http://solitaire.omg.org/browse/DMN11-95


Hints
-----
You can use the following [commit message template](commit-message-template.txt):
```
DMN12-/DMN12-

Issue: http://solitaire.omg.org/browse/DMN12-
Proposal: http://solitaire.omg.org/browse/DMN12-
```
    git commit --template=commit-message-template.txt

One can check if an issue is mentioned in a commit using:

    git log --all --grep 89
    git log --all --grep 11-89

Committing changes on behalf of someone else:

    git commit --author="Bruce Silver <bruce@example.com>" --template=commit-message-template.txt
    git commit --author="Bruce Silver <bruce@example.com>" --reedit-message=HEAD