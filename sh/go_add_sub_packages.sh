#!/bin/bash
IFS=$'\n'

source_folder="${SOURCE_FOLDER}"
if [[ -z "${source_folder}" ]]; then
    source_folder="${GITHUB_WORKSPACE}"
fi

arr=($(find "${source_folder}" -mindepth 1 -maxdepth 1 -type d))

for el in "${arr[@]}"; do
    src="${el}"
    pkg="$(echo "${el}" | grep -Po "^.*(?=/.*/)" | grep -Po "[^/]+$")"
    subpkg="$(echo "${el}" | grep -Po "[^/]+$")"
    trg="${GOROOT}/src/${pkg}/${subpkg}"

    echo -e "Try to make symlink\n\t${src} -> ${trg}"
    if [[ ! -f "${trg}" ]] && [[ ! -d "${trg}" ]] && [[ ! -L "${trg}" ]]; then
        cmd="ln -s \"${src}\" \"${trg}\""
        echo "${cmd}"
        eval "${cmd}"
    else
        echo "Target exists. Can not make symlink at ${trg}"
        exit 1
    fi
done
