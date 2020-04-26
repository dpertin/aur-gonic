
# AUR Gonic PKGBUILD

[![Build Status](https://cloud.drone.io/api/badges/dpertin/aur-gonic/status.svg)](https://cloud.drone.io/dpertin/aur-gonic)

This repo contains the required files to generate an Archlinux package of
[gonic](https://github.com/sentriz/gonic),
a lightweight music streaming server written in Go, which implements the
[Subsonic API](http://www.subsonic.org/pages/api.jsp).

## Automation script

The script `update_pkg.sh` can be used to automate the package building and
updating processes. Its workflow is as follows:
1. Check if a new version is available from the original repository (or build a
   specific version if '-v' argument is provided);
2. Clone the related AUR repo in a new directory and move to it;
3. Update the required files:
   - Update `PKGBUILD` (pkgver, md5sums)
   - Update `.SRCINFO`
4. Try to build the package:
   - If success and set to update: the script commits and push to GitHub. From
     there, Drone CI will try to build the package on a bare ArchLinux container.
   - If failure: send an email.

```
./update_pkg.sh usage:
      -h | --help)        # Display help.
      -f | --file)        # Path to a PKGBUILD file (default: "./PKGBUILD").
      -u | --update)      # Update GitHub repository (default: false).
      -v | --version)     # If a specific semantic version is required (e.g. 0.8.5).
      -V | --verbose)     # Enable verbose mode (default: false).
```

