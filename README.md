# dockup.sh

Utility bash script to easily run Perl-based [Plack/PSGI](https://plackperl.org/) web apps using [Docker](https://www.docker.com/) without the need for a local installation of Perl.

The script generates and runs the appropriate ```docker run``` commands needed to launch your app using the [rapi/psgi](http://hub.docker.com/r/rapi/psgi/) DockerHub image which does the actual work. See [http://hub.docker.com/r/rapi/psgi/](http://hub.docker.com/r/rapi/psgi/).

See also the [dockup.sh](dockup.sh) script itself for more info, usage and examples.

### Lightning talk at TPC 2018

See also the 5-minute Lightning talk given by @vanstyn on ```dockup.sh``` at The Perl Conference 2018 in Salt Lake City on June 19:

[rapi.io/tpc2018](http://rapi.io/tpc2018)

## instant web install

Run this command to automatically download and install/update to the latest dockup.sh:

```bash
wget -O - http://rapi.io/install-dockup.sh | bash
```

Or

```bash
curl -L http://rapi.io/install-dockup.sh | bash
  ```
