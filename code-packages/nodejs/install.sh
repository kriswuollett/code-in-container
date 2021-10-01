function install_nodejs {
    local PACKAGE="nodejs"
    INSTALL_PATH="${1:?"arg 1 (INSTALL_PATH) not set"}"
    VERSION="${2:?"arg 2 (VERSION) not set"}"
    ORDER="${3:?"arg 3 (ORDER) not set"}"
    test -d "${INSTALL_PATH}" &&
        mkdir -p ${INSTALL_PATH}opt/${PACKAGE}/${VERSION}/linux-x64 ${INSTALL_PATH}etc/profile.d/ &&
        curl https://nodejs.org/dist/v${VERSION}/node-v${VERSION}-linux-x64.tar.xz |
        tar --strip-components=1 --directory=${INSTALL_PATH}opt/${PACKAGE}/${VERSION}/linux-x64 -Jxf - &&
        tee ${INSTALL_PATH}etc/profile.d/${ORDER}-${PACKAGE}-${VERSION}-path.sh 1>/dev/null <<EOF
# Setup ${PACKAGE} ${VERSION} PATH
${PACKAGE}_bin_path="/opt/${PACKAGE}/${VERSION}/linux-x64/bin"
if [ -n "\${PATH##*\${${PACKAGE}_bin_path}}" ] && [ -n "\${PATH##*\${${PACKAGE}_bin_path}:*}" ]; then
    export PATH=\$PATH:\${${PACKAGE}_bin_path}
fi
unset nodejs_bin_path
EOF
}
