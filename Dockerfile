# Dockerfile for image: micro-magic
# 
# Sample docker build command:
# wsl docker build -f "Dockerfile" -t micro-magic "."

FROM containers.mathworks.com/matlab-runtime-utils/matlab-runtime-installer:r2025a-update-1 AS installer
LABEL "mathworks.matlab.runtime.cleanup"="true"

ENV EXTRACTEDDIR="/opt/matlabruntime/unzippedinstaller"

WORKDIR $EXTRACTEDDIR

# Write the installer file
RUN touch ./installInputs.txt
RUN printf "destinationFolder=/tmp/matlabruntime/runtime\nagreeToLicense=yes\n" > ./installInputs.txt
RUN printf "product.MATLAB Base Runtime\n" >> ./installInputs.txt
RUN printf "product.MATLAB Production Server Runtime Addon\n" >> ./installInputs.txt

# Run the installer
RUN ./install -bat true -inputFile ./installInputs.txt

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Etc/UTC"

RUN apt-get update && apt-get install --no-install-recommends -y \
ca-certificates \
gstreamer1.0-plugins-base \
gstreamer1.0-plugins-good \
gstreamer1.0-tools \
libasound2t64 \
libatomic1 \
libc6 \
libcairo-gobject2 \
libcairo2 \
libcap2 \
libcups2t64 \
libdrm2 \
libfontconfig1 \
libfribidi0 \
libgbm1 \
libgdk-pixbuf-2.0-0 \
libgl1 \
libglib2.0-0t64 \
libgstreamer-plugins-base1.0-0 \
libgstreamer1.0-0 \
libgtk-3-0t64 \
libgtk2.0-0t64 \
libice6 \
libltdl7 \
libnettle8t64 \
libnspr4 \
libnss3 \
libpam0g \
libpango-1.0-0 \
libpangocairo-1.0-0 \
libpangoft2-1.0-0 \
libpixman-1-0 \
libsndfile1 \
libtirpc3t64 \
libuuid1 \
libwayland-client0 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxfixes3 \
libxfont2 \
libxft2 \
libxinerama1 \
libxrandr2 \
libxt6t64 \
libxtst6 \
libxxf86vm1 \
net-tools \
procps \
unzip \
x11-xkb-utils \
zlib1g \
&& apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get upgrade -y

RUN [ -d /usr/share/X11/xkb ] || mkdir -p /usr/share/X11/xkb

LABEL "mathworks.matlab.runtime.cleanup"="false"

ENV TZ="Etc/UTC"

COPY --from=installer /tmp/matlabruntime/runtime /opt/matlabruntime

RUN unlink /opt/matlabruntime/R2025a/sys/os/glnxa64/libstdc++.so.6
RUN ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/matlabruntime/R2025a/sys/os/glnxa64/libstdc++.so.6

ENV LD_LIBRARY_PATH="/opt/matlabruntime/R2025a/runtime/glnxa64:/opt/matlabruntime/R2025a/bin/glnxa64:/opt/matlabruntime/R2025a/sys/os/glnxa64:/opt/matlabruntime/R2025a/sys/opengl/lib/glnxa64:/opt/matlabruntime/R2025a/extern/bin/glnxa64"

RUN apt-get update && apt-get upgrade -y

COPY ./applicationFilesForMATLABCompiler /usr/bin/mlrtapp
RUN chmod -R a+rX /usr/bin/mlrtapp/*

RUN if ["$(getent passwd appuser | cut -d: -f1)" = ""] ; then useradd -ms /bin/bash appuser ; fi
USER appuser

ENTRYPOINT ["/opt/matlabruntime/R2025a/bin/glnxa64/muserve", "-a", "/usr/bin/mlrtapp/magiccontainer.ctf"]
