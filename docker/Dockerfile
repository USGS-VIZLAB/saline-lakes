FROM rocker/geospatial:4.1.2

# Disable the annoying bell on WSL2
RUN sed -i 's/^# set bell-style none$/set bell-style none/' /etc/inputrc
RUN echo 'set visualbell' >> /root/.vimrc

# Add DOI CA to local CAs so that SSL can work over VPN
COPY DOIRootCA2.crt /usr/local/share/ca-certificates
RUN update-ca-certificates
ENV CURL_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt

## Necessary R packages
#
## R will default to pulling the latest R packages at the time the image is
## built. To pin R packages to their release as of a specific date, (for
## instance when pinning to the last working version in preparation for
## operationalization) set CRAN_DATE and CRAN_REPO below.
#
#ARG CRAN_DATE=2022-05-27
#ARG CRAN_REPO=https://packagemanager.rstudio.com/cran/__linux__/focal/$CRAN_DATE
#RUN echo "options(repos = c(CRAN = '${CRAN_REPO}'))" >> "${R_HOME}/etc/Rprofile.site"
RUN install2.r --error --skipinstalled \
  clustermq \
  dataRetrieval \
  nhdplusTools \
  openxlsx \
  rmapshaper \
  retry \
  sbtools \
  scico \
  snakecase \
  targets \
  tryCatchLog \
  && rm -rf /tmp/downloaded_packages /tmp/*.rds /tmp/Rtmp*

# Dark mode by default. This will work on 4.2.x but on newer versions it may
# obscure new options, or it might break if they change how the preferences are
# encoded in JSON.
RUN mkdir -p /home/rstudio/.config/rstudio && \
  chown -R rstudio:rstudio /home/rstudio/.config
COPY --chown=rstudio:rstudio rstudio-prefs.json /home/rstudio/.config/rstudio
