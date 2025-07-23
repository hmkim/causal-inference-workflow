FROM rocker/r-ver:4.3.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages for causal inference
RUN R -e "install.packages(c('remotes', 'devtools'), repos='https://cran.rstudio.com/')"
RUN R -e "install.packages(c('ggplot2', 'dplyr', 'tidyr', 'broom', 'patchwork'), repos='https://cran.rstudio.com/')"
RUN R -e "install.packages(c('MatchIt', 'WeightIt', 'cobalt', 'marginaleffects'), repos='https://cran.rstudio.com/')"
RUN R -e "install.packages(c('dagitty', 'ggdag', 'causaldata'), repos='https://cran.rstudio.com/')"

CMD ["R"]
