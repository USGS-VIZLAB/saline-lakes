FROM rocker/geospatial:4.2.1

# Disable the annoying bell on WSL2
RUN sed -i 's/^# set bell-style none$/set bell-style none/' /etc/inputrc
RUN echo 'set visualbell' >> /root/.vimrc

# Add DOI CA to local CAs so that SSL can work over VPN
COPY DOIRootCA2.crt /usr/local/share/ca-certificates
RUN update-ca-certificates
ENV CURL_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt

## Necessary R packages
RUN install2.r --error --skipinstalled \
dataRetrieval \
nhdplusTools \
openxlsx \
rmapshaper \
retry \
sbtools \
scico \
scico \
  && rm -rf /tmp/downloaded_packages /tmp/*.rds /tmp/Rtmp*

RUN install2.r --error --skipinstalled \
targets \
  && rm -rf /tmp/downloaded_packages /tmp/*.rds /tmp/Rtmp*

RUN install2.r --error --skipinstalled \
tryCatchLog \
  && rm -rf /tmp/downloaded_packages /tmp/*.rds /tmp/Rtmp*
#
#ARG RETICULATE_MINICONDA_PATH=/home/rstudio/.local/share/r-miniconda
#RUN Rscript -e 'reticulate::install_miniconda()'
#RUN Rscript -e 'tensorflow::install_tensorflow(envname = "r-reticulate")'
#RUN cp -r /root/.conda /home/rstudio/
#RUN chown -R rstudio /home/rstudio/.conda /home/rstudio/.local
#
# Dark mode by default. This will work on 4.2.x but on newer versions it may
# obscure new options, or it might break if they change how the preferences are
# encoded in JSON.
RUN mkdir -p /home/rstudio/.config/rstudio && \
  chown -R rstudio:rstudio /home/rstudio/.config
COPY --chown=rstudio:rstudio rstudio-prefs.json /home/rstudio/.config/rstudio
