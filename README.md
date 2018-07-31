# pbdCS 

* **Version:** 0.2-0
* **License:** [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause)
* **Author:** Drew Schmidt and Wei-Chen Chen
* **Project home**: https://github.com/RBigData/pbdCS
* **Bug reports**: https://github.com/RBigData/pbdCS/issues

A client/server framework for the pbdR packages. The client is actually the same as the client from the **remoter** package.


## Installation

<!-- You can install the stable version from CRAN using the usual `install.packages()`:

```r
install.packages("pbdCS")
```

In order to be able to create and connect to secure servers, you need to also install the **sodium** package.  The use of **sodium** is optional because it is a non-trivial systems dependency, but it is highly recommended.  You can install it manually with a call to `install.packages("sodium")` or by installing **remoter** via:

```r
install.packages("pbdCS", dependencies=TRUE)
``` -->

The development version is maintained on GitHub, and can easily be installed by any of the packages that offer installations from GitHub:

```r
remotes::install_github("RBigData/pbdCS")
```

To simplify installations on cloud systems, we also have a [Docker container](https://github.com/RBigData/pbdr-cs) available.




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
