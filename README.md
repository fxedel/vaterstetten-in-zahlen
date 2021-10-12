# Vaterstetten in Zahlen

vaterstetten-in-zahlen.de is an open source project whose goal is to visualize (and gather, if needed) publically available data about the municipality of Vaterstetten.

## Development

### Initial setup

Make sure the following packages are installed:

```sh
apt install r-recommended libcurl4-openssl-dev libgdal-dev libssl-dev libudunits2-dev libxml2-dev gfortran
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

### Tools

If you also want to be able to use the python tools, make sure to have Python 3.8+ installed. Then, install pipenv and install the local dependencies:

```sh
python3 -m pip install --user pipenv
python3 -m pipenv install
```

To run the data poller:

```sh
pipenv run python tools/poll.py [<telegram-token> <telegram-debug-chatid> [<telegram-public-chatid>]]
```

## License

This project is published under the MIT license, see [LICENSE.md](./LICENSE.md). However, there are some exceptions:

* The file [renv/activate.R](./renv/activate.R) is auto-generated by [renv](https://github.com/rstudio/renv/), therefore its copyright holder is RStudio.
* In the data/ directory, all data from external sources (which is the majority) may belong to a different or no specific license. See the `README.md` files in the data directories.
