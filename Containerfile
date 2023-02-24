FROM quay.io/fedora-ostree-desktops/silverblue:37

# Delete some silly repos

RUN rm /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    rm /etc/yum.repos.d/google-chrome.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo && \
    rm /etc/yum.repos.d/rpmfusion-nonfree-steam.repo

# Install ffmpeg

RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-37.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-37.noarch.rpm

RUN ostree container commit

RUN rpm-ostree install ffmpeg

RUN rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release

RUN ostree container commit

# Get snapper running on /var/home

RUN rpm-ostree install snapper

RUN ostree container commit

COPY snapper /etc/snapper/configs/home

RUN mkdir /etc/conf.d && \
    echo "SNAPPER_CONFIGS=\"home\"" > /etc/conf.d/snapper

# Layer some packages
COPY layers .

RUN cat layers | xargs rpm-ostree install -y

# Start up some services
RUN sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable rpm-ostree-countme.timer && \
    systemctl enable snapper-timeline.timer && \
    systemctl enable snapper-cleanup.timer

# Cleanup and finalize
RUN rm layers && \
    rm -rf /tmp/* /var/* && \
    ostree container commit
