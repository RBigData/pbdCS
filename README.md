# pbdCS 

* **Version:** 0.1-1
* **URL**: https://github.com/wrathematics/pbdCS
* **License:** [![License](http://img.shields.io/badge/license-BSD%202--Clause-orange.svg?style=flat)](http://opensource.org/licenses/BSD-2-Clause)
* **Author:** Drew Schmidt and Wei-Chen Chen

A client/server framework for the pbdR packages. The client is actually the same as the client from the **remoter** package.


## Installation

#### Stable Version
```r
install.packages("pbdCS")
```

#### Development Version
```r
### Pick your preference
devtools::install_github("RBigData/pbdCS")
ghit::install_github("RBigData/pbdCS")
remotes::install_github("RBigData/pbdCS")
```



## Usage

Launch the batch servers:

```bash
mpirun -np 2 Rscript -e "pbdCS::pbdserver()"
```

Connect the client to the servers by running in an interactive session:

```r
pbdCS::pbdclient()
```

For more information, see the **remoter** and **pbdCS** package vignettes.



## Acknowledgements

The development for this package was supported by the project *Harnessing Scalable Libraries for Statistical Computing on Modern Architectures and Bringing Statistics to Large Scale Computing* funded by the National Science Foundation Division of Mathematical Sciences under Grant No. 1418195.

Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
