# Base image: Ubuntu 22.04
FROM ubuntu:22.04

# Stop terminal from prompting user input during installation
# ...used due to issue where R installation prompts user input, causing the build to fail
ARG DEBIAN_FRONTEND=noninteractive

# Set /pipeline as the working directory in the container
WORKDIR /pipeline

# Set Bash as the default shell (primarily for Macs which may have zsh set)
SHELL ["/bin/bash", "-c"]

# Install system-level dependencies
RUN apt-get update && apt-get install -y \
    gnupg2 \
    software-properties-common \
    curl \
    r-base \
    libfontconfig1-dev \
    libssl-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    gdebi-core \
    wget \
    pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install Shiny server
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f ss-latest.deb

# Copy all compendium files into the container
COPY . /pipeline

# Install R dependencies via renv.lock and restore() function
RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

# Make all scripts executable (all scripts have either .sh or .R extension)
RUN find /pipeline -type f -iname "*.sh" -exec chmod +x {} \; && \
    find /pipeline -type f -iname "*.R" -exec chmod +x {} \;

# Copy the Shiny app to the Shiny Server directory
RUN mkdir -p /srv/shiny-server/youngbites
COPY visualisations/shiny/youngbites.R /srv/shiny-server/youngbites/

# Expose the application port (for Shiny app)
EXPOSE 3838

# Run the pipeline via jobscript.sh
ENTRYPOINT ["./jobscript.sh"] 

# CMD to start the Shiny Server 
CMD ["shiny-server"]