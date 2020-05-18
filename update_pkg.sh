#!/usr/bin/env bash

usage() { echo "$0 usage:" && grep " -. |.*) *#" $0; }

# set default values
pkgbuildFile="./PKGBUILD"
updateMainRepo=false
pushGithubRepo=false
repoPkgVer=$(curl --silent "https://api.github.com/repos/sentriz/gonic/tags" | \
    jq -r '.[0].name' | cut -d 'v' -f 2)
verbose=false

# parse arguments
GET_OPT=$(getopt \
    -o 'f:puv:Vh' \
    --long 'file:,push,update,version:,verbose,help' \
    -- "$@")
eval set -- "${GET_OPT}"

while true; do
    case "$1" in
      -h | --help)        # Display help.
          usage; exit 0;;
      -f | --file)        # Path to a PKGBUILD file (default: "./PKGBUILD").
          pkgbuildFile=$2; shift 2;;
      -p | --push)        # Push to GitHub repository (default: false).
          pushGithubRepo=true; updateMainRepo=true; shift 1;;
      -u | --update)      # Update the main repository (default: false).
          updateMainRepo=true; shift 1;;
      -v | --version)     # If a specific semantic version is required (e.g. 0.8.5).
          repoPkgVer=$2; shift 2;;
      -V | --verbose)     # Enable verbose mode (default: false).
          verbose=true; shift 1;;
      --) shift; break;;
      *) usage; exit 1;;
    esac
done

[ -z "${MAILTO}" ] && echo -e \
    "\e[33m[Warning] MAILTO must be set to receive email alerts\e[0m"

# check if given PKGBUILD file exists
if [[ ! -f "$pkgbuildFile" ]]
then
    echo "\"${pkgbuildFile}\" is not a valid PKGBUILD file (not exists)"
    exit 1
fi

# check if given version is valid
if [[ ! $repoPkgVer =~ ^[0-9]+\.[0-9]+ ]]
then
    echo "\"$2\" is not a valid version number (e.g. 0.8.5)"
    exit 1
fi

source ${pkgbuildFile}


# Compare two semantic version, inspired from
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 0
        fi
    done
    return 1
}

update_package () {
    # update package version
    sed "s/^pkgver=.*/pkgver=${repoPkgVer}/" -i ${pkgbuildFile}

    # update md5 sums
    if hash updpkgsums 2>/dev/null; then
        updpkgsums
    else
        md5sums=$(makepkg -g -p ${pkgbuildFile})
        perl -p0e \
            "s/md5sums=(.*)\n\n\nbuild/${md5sums}\n\n\nbuild/s" \
            -i ${pkgbuildFile}
    fi

    # update .SRCINFO
    mksrcinfo
}

${verbose} && echo "Current AUR version: ${pkgver}"
${verbose} && echo "Main repository version: ${repoPkgVer}"

if vercomp ${pkgver} ${repoPkgVer};
then
    dir_name=$"${pkgname}_${repoPkgVer}"

    echo "[OUT_OF_DATE] New version available"
    echo "Try to build the new package under ${dir_name}"
    [ -d "${dir_name}" ] && rm -rf ${dir_name}
    git clone https://aur.archlinux.org/${pkgname}.git ${dir_name}
    sed \
        "s#https://aur.archlinux.org#ssh+git://aur@aur.archlinux.org#" \
        -i ${dir_name}/.git/config

    pushd ${dir_name}
    update_package

    if makepkg_log=$(makepkg -p ${pkgbuildFile} 2>&1)
    status="succeeded"
    then
        echo "[SUCCESS] Package was successfully built"
        # if update is set, commit and copy indexed files to github directory
        ${pushGithubRepo} && git commit -am "Update to ${repoPkgVer}"
        ${updateMainRepo} && cp $(git ls-files) ../
    else
        echo "[FAILURE] Package building failed"
        status="failed"
    fi

    # send an email
    if [ ! -z "${MAILTO}" ]
    then
        echo "Sending an email to ${MAILTO}..."
        content="Updating from ${pkgver} to ${repoPkgVer}\n\n
        This is the output of makepkg:\n${makepkg_log}"
        echo ${content} | mail -v -s \
            "[${pkgname-${repoPkgVer}}] makepkg ${status}" ${MAILTO}
    fi

    popd
    # if update is set, commit and push to GitHub
    ${pushGithubRepo} && git commit -am "Update to ${repoPkgVer}"
    ${pushGithubRepo} && git push origin master
else
    echo "[UPDATED] Package is up to date"
    # Nothing to do
fi

