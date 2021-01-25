## Development

### Initial setup

Make sure the following packages are installed:

```sh
apt install r-recommended libcurl4-openssl-dev libssl-dev
```

Then, start an R session and install the needed R packages:

```R
install.packages("packrat")
packrat::restore()
```

### Start web server

```sh
Rscript server.R
```
