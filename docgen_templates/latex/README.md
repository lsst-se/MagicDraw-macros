# Creating requirements documents in Latex from MagicDraw

1. Add `lsst-docgen-template.tex` to your MagicDraw installation using the Report Wizard.
2. Generate a report, selecting the requirements package.
3. Run the Python `mklatex.py` command to do the necessary fixups to make the output compilable.
4. Create a `metadata.tex` file containing the document specific metadata.
5. Build the document using `xelatex`. Your environment should be configured using [lsst-texmf](https://lsst-texmf.lsst.io).

The `metadata.tex` file should contain the following definitions:

```latex
\title{The title}
\author{All the authors}
\setDocRef{LSE-nnn}
\setDocChangeRecord{%
...
}
```

## Notes

* The title is not obtained from the SysML model at this time.
  This is because the title includes the document handle.
  In future the Python code may extract the handle from the title and remove the need for `\setDocRef` and `\title` in the metadata file.
* The date will be inserted automatically from the model version history.
* An attempt is made to detect mentions of other documents.
  These will be added as citations.
* Mentions of requirements will be replaced with internal links to the requirement in the current document.
