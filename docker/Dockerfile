# Build environment for Covert Action: DOSBox-X runs MSC 5.1, MASM 5.10 and LINK.
# The image holds only the sources and tools: no game files and no Microsoft files.
# The toolchain is mounted at run time at /covert/toolchain/msc51.
#
#   docker build -f docker/Dockerfile -t covert-recomp .
#
# Build all 18 executables into ./out:
#   docker run --rm -v "/path/to/msc51:/covert/toolchain/msc51:ro" \
#       -v "$PWD/out:/covert/build/out" covert-recomp
# ...and check them against an original game directory: add
#       -v "/path/to/game:/covert/resources/Covert:ro"
# Unpack a release (GOG installers, eXoDOS zip, floppy sets) into ./game:
#   docker run --rm -v "/path/to/releases:/in:ro" -v "$PWD/game:/out" covert-recomp \
#       tools/extract_game.py "/in/<installer or archive>" /out
# -e NO_PATCHES=1 builds FINAL.EXE without the copy-protection patch (the 1990
# floppy release).
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends dosbox-x python3 innoextract 7zip \
 && rm -rf /var/lib/apt/lists/*

# DOSBox-X runs headless
ENV SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy DOSBOX=/usr/bin/dosbox-x

WORKDIR /covert
COPY . .
RUN chmod +x tools/*.sh tools/rebuild/*.sh tools/drivers/*.sh tools/extract_game.py

CMD ["tools/build_all.sh"]
