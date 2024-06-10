#!/usr/bin/env bash

#INPUT_BASE_URL
GITLAB_USERNAME="kvendingoldo"
GITLAB_PAT_TOKEN="glpat-Y3nmhsg8NTVKy5G5m-M2"
####
set -eux pipefail

GITLAB_HOST="gitlab.alpinelinux.org"
GITLAB_URL="https://gitlab.alpinelinux.org"
GITLAB_API_URL="${GITLAB_URL}/api/v4"

APORTS_PROJECT_ID=1
FORK_PATH="${GITLAB_USERNAME}/aports"






# 1. create fork
#  pkgver=2.0.2
# pkgrel=0
# sha512sums
#sha512sums="
#f7a2b174f6b9d8d7f92111d654374d6c55b641f7e7db93c5579bd1a19fcdeeeedd897d8107c6b586fe2987169f8c075375380af149429367fc995255566d1585  tenv-2.0.2.tar.gz"
#community/limine: upgrade to 7.7.2


function fork_exists() {

    id=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_PAT_TOKEN}" \
        "${GITLAB_API_URL}/api/v4/projects/${GITLAB_USERNAME}%2Faports" | jq '.id')
    if [[ "${id}" == "null" ]]; then
        return 1
    else
        return 0
    fi
}


function clone_fork() {
    git clone "https://oauth2:${GITLAB_PAT_TOKEN}@${GITLAB_HOST}/${GITLAB_USERNAME}/aports.git"
}




function update_project() {
    APKBUILD_FILE="testing/tenv/APKBUILD"

    sed -i "s/^pkgname=.*/pkgname=$NEW_PKGNAME/" "${APKBUILD_FILE}"
    sed -i "s/^pkgver=.*/pkgver=$NEW_PKGVER/" "${APKBUILD_FILE}"
    sed -i "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" "${APKBUILD_FILE}"
    sed -i "s/^sha512sums=.*/sha512sums=$NEW_PKGREL/" "${APKBUILD_FILE}"


    echo "[INFO] Updating project"
}






function main() {
    if fork_exists; then
        echo "[INFO] aports fork already exists. Updating fork..."
        rm -rf ${FORK_PATH} || echo
        clone_fork
        cd ${FORK_PATH}
        git pull upstream master
        git push -f origin master
        cd ..
        update_project
        create_mr
    else
        echo "[INFO] aports fork does not exist. Forking project..."

        aports_id=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_PAT_TOKEN}" \
            "${GITLAB_API_URL}/projects/alpine%2Faports" | jq '.id')

        curl -s --request POST --header "PRIVATE-TOKEN: ${GITLAB_PAT_TOKEN}" \
            --data "namespace=${GITLAB_USERNAME}" "${GITLAB_API_URL}/projects/${aports_id}/fork"

        echo "[INFO] Waiting for fork to complete..."
        sleep 60

        if fork_exists; then
            echo "[INFO] Fork successful. Cloning project..."
            clone_fork
            update_project
            create_mr
        else
            echo "[ERROR] Fork failed. Please check your settings and try again."
        fi
    fi
}

main "${@}"

