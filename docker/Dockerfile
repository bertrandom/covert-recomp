# Build environment for Covert Action: DOSBox-X runs MSC 5.1, MASM 5.10 and LINK.
# The image holds only the sources and tools: no game files and no Microsoft files.
#
#   docker build -f docker/Dockerfile -t covert-recomp .
#
# Put the Microsoft C 5.1 and MASM 5.10 disk archives (.7z) in a folder and mount it
# at /work; the toolchain is set up from them (their SHA-1 is checked first; cached
# in msc51/ there), and all 18 executables are built into out/ there, each checked
# against the original release's SHA-1:
#   docker run --rm -v "/path/to/folder:/work" covert-recomp
# (Docker Desktop: Run > Optional settings > Volumes: host folder -> /work.)
# A ready toolchain can be mounted at /covert/toolchain/msc51 instead.
# -e NO_PATCHES=1 builds FINAL.EXE without the copy-protection patch (the 1990
# floppy release).
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends dosbox-x python3 7zip \
 && rm -rf /var/lib/apt/lists/*

# DOSBox-X runs headless
ENV SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy DOSBOX=/usr/bin/dosbox-x

WORKDIR /covert
COPY . .
RUN chmod +x docker/entrypoint.sh tools/*.sh tools/rebuild/*.sh tools/drivers/*.sh tools/*.py

ENTRYPOINT ["docker/entrypoint.sh"]
