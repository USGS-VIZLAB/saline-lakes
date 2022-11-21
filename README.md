Repository for Saline Lakes Data Processing and Visualization Task 

`targets` pipeline that pulls NWIS and WQP data for focal saline lakes, and generates a gap analysis report.

## Environment

This pipeline has specific version requirements. It has been tested to run on R version 4.1.2. The easiest way to get the versions exactly right is to run this through the provided docker image.

## How to Run the Pipeline through Docker
First, download the docker image, or else build it yourself.

```bash
# to build the image yourself
cd saline-lakes/docker
docker-compose build

# to download the docker image from docker hub
docker login
docker pull jrossusgs/saline-lakes:20221115
```

Now you can launch an RStudio session in the container.

```bash
cd saline-lakes
# set the password to whatever you like below, or remove the entire
# "-e PASSWORD=foo" section to use an automatically generated one
docker run --rm -it -e PASSWORD=foo -p 8787:8787 -v $PWD:/saline-lakes jrossusgs/saline-lakes:20221115
```

Now open up a web browser at [http://localhost:8787](http://localhost:8787), and log in with the username "rstudio" and the password set above (e.g. "foo"). You should be in the directory with the code, and can run `targets::tar_make()`.

### Configuring the Dockerized RStudio
If you have RStudio preferences you like, and want the dockerized RStudio to reflect these preferences, you need to make those preferences available when you launch the docker container. Otherwise you'd wind up setting the preferences you like over and over. You can do this by adding a flag to the docker startup, like

```bash
cd saline-lakes
docker run --rm -it -e PASSWORD=foo -p 8787:8787 -v $PWD:/saline-lakes -v /path/to/your/rstudio-prefs.json:/home/rstudio/.config/rstudio/rstudio-prefs.json jrossusgs/saline-lakes:20221115
```

## Disclaimer

This software is in the public domain because it contains materials that originally came from the U.S. Geological Survey, an agency of the United States Department of Interior. For more information, see the official USGS copyright policy at [http://www.usgs.gov/visual-id/credit_usgs.html#copyright](http://www.usgs.gov/visual-id/credit_usgs.html#copyright)

This information is preliminary or provisional and is subject to revision. It is being provided to meet the need for timely best science. The information has not received final approval by the U.S. Geological Survey (USGS) and is provided on the condition that neither the USGS nor the U.S. Government shall be held liable for any damages resulting from the authorized or unauthorized use of the information. Although this software program has been used by the USGS, no warranty, expressed or implied, is made by the USGS or the U.S. Government as to the accuracy and functioning of the program and related program material nor shall the fact of distribution constitute any such warranty, and no responsibility is assumed by the USGS in connection therewith.

This software is provided "AS IS."


[
  ![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)
](http://creativecommons.org/publicdomain/zero/1.0/)
