# loadwordteam/ghidra-server
ARG ghidra_install_path=/opt/ghidra

# We need an OpenJDK11 image NOT based on alpine (or anything with
# musl libc), this server has problems even with the ARM JVM, let's
# use a very boring flavour.
FROM openjdk:11-jdk AS builder

ARG ghidra_install_path
ARG ghidra_url=https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.1.1_build/ghidra_10.1.1_PUBLIC_20211221.zip
ARG ghidra_sha256=d4ee61ed669cec7e20748462f57f011b84b1e8777b327704f1646c0d47a5a0e8
ARG ghidra_version=10.1.1_PUBLIC
ARG ghidra_repo_path=/srv/repositories

ENV LANG=C.UTF-8 \
    GHIDRA_HOME=${ghidra_install_path} \
    GHIDRA_REPO_DIR=${ghidra_repo_path}

ADD $ghidra_url ghidra.zip

RUN apt-get -qq update \
    && apt-get -y install \
        locales \
        gettext-base \ 
        ncat \
    && echo "${ghidra_sha256} ghidra.zip" | sha256sum -c \
    && unzip -qo ghidra.zip \
    && rm ghidra.zip \
    && mkdir -p /opt \
    && mv "ghidra_${ghidra_version}" "${ghidra_install_path}" \
    && rm "${ghidra_install_path}/server/server.conf" \
    && rm -rf /var/lib/apt/lists/* \
    # Set timezone to UTC by default
    && ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
    # Use unicode
    && locale-gen C.UTF-8 || true

WORKDIR "${ghidra_install_path}/server"
COPY ./server.conf.tmpl /
COPY entrypoint.sh /

EXPOSE 13100 13101 13102

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./ghidraSvr", "console"]

