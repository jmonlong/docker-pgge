FROM ubuntu:18.04
MAINTAINER jmonlong@ucsc.edu

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ARG THREADS=4

WORKDIR /build

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
        wget \
        curl \
        less \
        gcc \ 
        samtools \
        tzdata \
        make \
        git \
        sudo \
        pkg-config \
        libxml2-dev libssl-dev libmariadbclient-dev libcurl4-openssl-dev \ 
        apt-transport-https software-properties-common dirmngr gpg-agent \ 
        && rm -rf /var/lib/apt/lists/*

ENV TZ=America/Los_Angeles

## R and pandoc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
        && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
        && apt-get update \
        && apt-get install -y r-base r-base-dev

# RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/XML/XML_3.99-0.3.tar.gz')"

RUN R -e "install.packages(c('tidyverse', 'ggrepel', 'gridExtra'))"

## rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rust.sh && \
	sh rust.sh -y --no-modify-path

ENV PATH /root/.cargo/bin:$PATH

## peanut
RUN git clone https://github.com/pangenome/rs-peanut.git && \
	cd rs-peanut && \
	cargo build --release

ENV PATH /build/rs-peanut/target/release:$PATH

## splitfa
RUN git clone https://github.com/ekg/splitfa.git && \
	cd splitfa && \
	cargo build --release

ENV PATH /build/splitfa/target/release:$PATH

## GraphAligner
RUN wget -O Miniconda-latest-Linux.sh https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh && \
        bash Miniconda-latest-Linux.sh -b -p /miniconda

ENV PATH /miniconda/bin:$PATH

SHELL ["/bin/bash", "-c"] 

RUN conda init bash && source ~/.bashrc && conda update -n base -c defaults conda

RUN git clone --recursive https://github.com/maickrau/GraphAligner && \
        cd GraphAligner && \
        git fetch --tags origin && \
        git checkout "v1.0.12" && \
        git submodule update --init --recursive && \
        conda env create -f CondaEnvironment.yml && \
        source activate GraphAligner && \
        make bin/GraphAligner

ENV PATH /build/GraphAligner/bin:$PATH

## GNU time
RUN wget https://ftp.gnu.org/gnu/time/time-1.9.tar.gz && \
        tar -xzvf time-1.9.tar.gz && \
        cd time-1.9 && \
        ./configure --prefix=/usr && \
        make && \
	make install

## clone pgge repo
RUN git clone https://github.com/pangenome/pgge.git /home/pgge

WORKDIR /home/pgge
