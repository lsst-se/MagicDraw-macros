#!/usr/bin/env python3

import re
import sys
import html
from datetime import datetime

# Copyright (C) 2017 Association of Universities for Research in Astronomy

# This product includes software developed by the
# LSST Project (http://www.lsst.org/).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the LSST License Statement and
# the GNU General Public License along with this program.  If not,
# see <https://www.lsstcorp.org/LegalNotices/>.


"""
Fix the contents of the TeX file created by MagicDraw using the requirements
LaTeX template file to allow it to work with LaTeX.

 % mklatex.py magicdraw-output.tex > LSE-nnn.tex

"""

# Common regexes
MATCH_BIBCODE = re.compile(r"(\d{4}[A-Za-z\.\&]{5}[\d\.]{4}[ELPQ-Z\.g][\d\.]{4}[A-Z\.])")

# Read in the entire file into a list so we can do multiple passes through
# the text. A pass is needed to locate all possible requirement ID prefixes
# since a requirement can interally refer to a later ID with a prefix we have
# note yet encountered.
with open(sys.argv[1], "r") as fh:
    document = fh.readlines()

# Pass 1
reqid_roots = set()
for line in document:
    # To be generically useful, we have to work out what requirement
    # ID root is being used in this document -- some documents have multiple
    # roots so we have to keep track of more than one
    root_match = re.search("label{(.*-REQ)-\d+}", line)
    if root_match:
        reqid_roots.add(root_match.group(1))

for reqid_root in reqid_roots:
    print("Using requirement prefix {}".format(reqid_root),
          file=sys.stderr)

# form a pattern match for internal requirements
re_reqids = None
if reqid_roots:
    re_reqids = re.compile(r"((?:{})-\d\d\d\d)".format("|".join(reqid_roots)))

# Pass 2: Modify on the fly and write to standard output
in_table = False
in_list = False
stripping = False
for line in document:
    # Remove html pre wrappers. They can be ignored
    line = re.sub(r"<html><pre>", "", line)
    line = re.sub(r"</pre></html>", "", line)

    # standalone open and close tags can be ignored
    skip_line = False
    for t in ("html", "head", "style", "body", "b"):
        if skip_line:
            break
        if re.search(r"^\s*<{}>\s*$".format(t), line):
            skip_line = True
            break
        if re.search(r"^\s*</{}>\s*$".format(t), line):
            skip_line = True
            break

    # Standalone closing </li> tags should be ignored
    for t in ("li",):
        if skip_line:
            break
        if re.search(r"^\s*</{}>\s*$".format(t), line):
            skip_line = True
            break

    # Style is irrelevant here
    if re.search(r"padding:\d+px", line):
        skip_line = True

    # This line is not needed
    if skip_line:
        continue

    # Remove pre tags
    line = re.sub(r"<pre>", "", line)
    line = re.sub(r"</pre>", "", line)

    # A </b> at the start of a line can probably be removed
    line = re.sub(r"^</b>", "", line)

    # Fix the title to remove the document ref from the title. The Latex
    # style handles the document ref itself and it should not be part
    # of the title
    if "title" in line:
        line = re.sub(r"L\w\w\-\d+ ", "", line)

    # Handle <ol> and <ul> tags
    line = re.sub("<ol>", r"\\begin{enumerate}", line)
    line = re.sub("</ol>", r"\\end{enumerate}", line)
    line = re.sub("<ul>", r"\\begin{itemize}", line)
    line = re.sub("</ul>", r"\\end{itemize}", line)

    # Replace & with \& if this is a section (to void table confusion)
    # May be easier to change to "and" in rth model
    if re.search(r"section\{.* & ", line):
        line = re.sub(r" & ", r" \& ", line)

    # Handle underscores that are surrounded by text
    # but not bib files
    if re.search(r"\w_\w", line) and not line.startswith("\\bibliography{"):
        line = re.sub(r"(\w)_(\w)", r"\1\_\2", line)

    # Sometimes traced requirements have & in their name and we have no
    # control over that part of the model.
    # Try to replace them by assuming none of the tables end in \newline
    if re.search(r" & .*newline$", line):
        line = re.sub(r" & ", r" \& ", line)

    # Remove any spaces between the section{ and beginning of title.
    # Useful for consistent git history as updated template leaves space.
    if re.search(r"section\{ ", line):
        line = re.sub(r"section\{\s+", "section{", line)

    # Handle style tags for bold and italic
    tags = {"b": "textbf", "i": "textit", "li": "item"}
    for t in tags:
        line = re.sub(r"<{0}>(.*?)</{0}>".format(t),
                      r"\\{}{{\1}}".format(tags[t]), line)

    # Newer version of model seems to put <li> tags on line of their own
    # </p> and <p> get converted to blank lines rather than skipped
    # to ensure that a paragraph boundary will really happen in latex
    isolated_tags = {"li": "\\item", "p": ""}
    for t in isolated_tags:
        line = re.sub(r"^\s*<{0}>\s*$".format(t),
                      r"{}".format(isolated_tags[t]), line)
        # the end tag is stripped
        line = re.sub(r"^\s*</{0}>\s*$".format(t), "", line)

    # HTML Entity replacement
    line = html.unescape(line)

    # Quick search for URLs. Do not need to do anything fancy
    # until we find we do. We do not handle <a> tags.
    line = re.sub("(?P<url>https?://[^\s,\)]+)", r"\\url{\1}", line)

    # Replace mentions of document handles with a citation
    # but not if this is defining the document handle itself
    if not re.search(r"(setDocRef|addtohist)", line):
        line = re.sub(r"(L[PDTS]\w\-\d+)", r"\\citeds{\1}", line)

    # Look for ADS bibcodes and turn them into citations
    hasbib = MATCH_BIBCODE.search(line)
    if hasbib:
        bibcode = hasbib.group(1)
        line = line.replace(bibcode, r"\citep{" + bibcode + "}")

    # Use hyperlinks when mentioning requirements from other
    # requirements within the same document
    if re_reqids is not None:
        unique_matches = set(re_reqids.findall(line))
        for reqid in unique_matches:
            if not re.match(r"\\label{" + reqid, line) and \
                    not re.search(r"ID:.*" + reqid, line):
                print("Found internal ref to requirement {}".format(reqid), file=sys.stderr)
                # loop through each match and replace it with latex hyperref
                line = line.replace(reqid, r"\\hyperref[" + reqid + "]{" + reqid + "}")

    # Now that the line is fixed up, look for list
    if re.match(r"\s*\* ", line):
        if not in_table:
            in_table = True
            print("\\begin{itemize}")
        line = re.sub(r"^\s*\*", r"\item", line)
    elif in_table and re.match(r"^\s*$", line):
        in_table = False
        print("\\end{itemize}")

    # Strip leading spaces from requirements text
    if re.match(r"\s+\\textbf{(Discussion|Specification):}", line):
        line = line.lstrip()

    # Strip trailing whitespace
    line = line.rstrip()

    # Template can insert Specification and Discussion text but we need
    # to remove any blank lines after that line. These blank lines are
    # caused by stripping out the useles HTML tags early so we have to
    # filter them out here. We also want to ensure we don't have lots of
    # blank lines together (they appear when we strip tags).
    if not line:
        if stripping:
            continue
        # Compress multiple blank lines into a single blank line
        stripping = True
    else:
        if re.match(r"\\textbf{(Discussion|Specification):}$", line):
            stripping = True
        else:
            stripping = False

    print(line)
