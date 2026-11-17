# SPDX-License-Identifier: 0BSD
# openSUSE userland on an Ubuntu Docker host: NOT a separate openSUSE kernel.
# The image's exact digest is recorded by the runner at benchmark time.
FROM opensuse/tumbleweed:latest
RUN zypper --non-interactive --gpg-auto-import-keys refresh \
 && zypper --non-interactive install --no-recommends \
      cmake gcc-c++ java-17-openjdk-devel \
 && zypper --non-interactive clean --all
WORKDIR /work
