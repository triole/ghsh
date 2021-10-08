#!/bin/bash

architectures=(
    "linux_armv6l:GOOS=linux GOARCH=arm GOARM=6"
    "linux_armv7l:GOOS=linux GOARCH=arm GOARM=7"
    "linux_armv64:GOOS=linux GOARCH=arm64"
    "linux_i686:GOOS=linux GOARCH=386"
    "linux_x86_64:GOOS=linux GOARCH=amd64"
    "freebsd_arm64:GOOS=freebsd GOARCH=arm64"
    "freebsd_i686:GOOS=freebsd GOARCH=386"
    "freebsd_x86_64:GOOS=freebsd GOARCH=amd64"
    "darwin_arm64:GOOS=darwin GOARCH=arm64"
    "darwin_x86_64:GOOS=darwin GOARCH=amd64"
)

app_name=$(pwd | grep -Po "[^/]+$")
ld_author=$(grep -Po "(?<=name\s=\s).*" ~/.gitconfig)
ld_git_commit_no=$(git rev-list "origin/master" --count --)
ld_git_commit_hash=$(git rev-parse HEAD)
ld_date=$(LANG=en_us_88591 date)

source_folder="${SOURCE_FOLDER}"
target_folder="${TARGET_FOLDER}"

if [[ -z "${source_folder}" ]]; then
    source_folder="${GITHUB_WORKSPACE}"
fi
if [[ -z "${target_folder}" ]]; then
    target_folder="build"
fi

gobin="${GO_BIN_PATH}"
if [[ ! -f "${gobin}" ]]; then
    gobin="$(which go)"
fi

goversion="$(${gobin} version | grep -Po "(?<=go)[0-9\.]+")"

debug="false"
for val in "$@"; do
    if [[ "${val}" =~ ^-+(d|debug)$ ]]; then
        debug="true"
    fi
done

function rcmd() {
    echo "${1}"
    if [[ "${debug}" == "false" ]]; then
        eval ${1}
    fi
}

cd "${source_folder}"
rcmd "${gobin} mod init ${app_name}"
rcmd "${gobin} mod tidy"

for arch in "${architectures[@]}"; do
    arch_name="$(echo "${arch}" | grep -Po ".*(?=:)")"
    arch="$(echo "${arch}" | grep -Po "[^:]+$")"
    rcmd "CGO_ENABLED=0 ${arch} ${gobin} build -o ${target_folder}/${arch_name}/${app_name} \
        -ldflags \
        \"-s -w -X 'main.BUILDTAGS={
            _subversion: ${ld_git_commit_no}, author: ${ld_author},
            build date: ${ld_date}, git hash: ${ld_git_commit_hash},
            go version: ${goversion}
        }'\" \
        src/*.go"
done

find "$(realpath ${target_folder})" -type f -executable \
    -exec echo '' \; \
    -exec md5sum {} \; \
    -exec file {} \;
