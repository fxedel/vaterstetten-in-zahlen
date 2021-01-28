## Development

### Initial setup

Make sure the following packages are installed:

```sh
apt install r-recommended libcurl4-openssl-dev libssl-dev libxml2-dev
```

Then, start an R session and install the needed R packages:

```R
install.packages("renv")
renv::restore()
```

### Start web server

```sh
Rscript server.R
```
