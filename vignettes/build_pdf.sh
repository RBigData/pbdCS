#!/bin/sh

Rscript -e "source('./rmd.r');rmd.convert('pbdCS.Rmd', 'pdf')"
mv -f *.pdf ../inst/doc/
