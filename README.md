# dockup.sh

Utility bash script to easily run Perl-based [Plack/PSGI](https://plackperl.org/) web apps using [Docker](https://www.docker.com/) without the need for a local installation of Perl.

The script generates and runs the appropriate ```docker run``` commands needed to launch your app using the [rapi/psgi](http://hub.docker.com/r/rapi/psgi/) DockerHub image which does the actual work. See [http://hub.docker.com/r/rapi/psgi/](http://hub.docker.com/r/rapi/psgi/).

See also the [dockup.sh](dockup.sh) script itself for more info, usage and examples.

## instant web install

Run this command to automatically download and install/update to the latest dockup.sh:

```bash
wget -O - http://rapi.io/install-dockup.sh | bash
```

Or

```bash
curl -L http://rapi.io/install-dockup.sh | bash
  ```
