# Base image with R version 4.1.2
FROM r-base:4.1.2  

# Set the working directory
WORKDIR /pipeline

# Set Bash as the default shell
SHELL ["/bin/bash", "-c"]

# Install system-level dependencies
RUN apt-get update && apt-get install -y \
    libfontconfig1-dev \
    libssl-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Copy all compendium files into the container
COPY . /pipeline

# Install R dependencies via renv.lock and restore environment
RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

# Make all scripts executable
RUN find /pipeline -type f -iname "*.sh" -exec chmod +x {} \;
RUN find /pipeline -type f -iname "*.R" -exec chmod +x {} \;

# Run the pipeline via jobscript.sh
ENTRYPOINT ["./jobscript.sh"]