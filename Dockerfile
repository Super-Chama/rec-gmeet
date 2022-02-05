FROM ubuntu:20.04

#========================
# OS packages
#========================
# locales & tzdata
#   configs default locale and timezone
# gnupg & ca-certificates
#   singing gpg packages
# x11vnc
#   minimal VNC server to connect with container
# xvfb
#   virtual display server with X11 display server protocol
# fluxbox
#   lite window manager supporting X Window System
# wmctrl
#   interact with fluxbox, for controlling window manager
# pulseaudio & pavucontrol
#   virtual audio channels and sound control
# ffmpeg & libavcodec-extra
#   capturing and encoding xvfb stream
# curl
#   transfer URL data using various Internet protocols
RUN apt-get update && apt-get clean && apt-get install -y locales tzdata && \
    locale-gen en_US.UTF-8 && \
    apt-get install --no-install-recommends -yq gnupg curl \
    ca-certificates \
    x11vnc \
    xvfb \
    fluxbox \
    eterm \
    wmctrl \
    pulseaudio \
    pavucontrol \
    ffmpeg \
    libavcodec-extra && \
    apt-get autoremove --purge -y && \
    apt-get autoclean -y && \
    apt-get clean -y

#========================
# Google chrome stable
#========================
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -yq google-chrome-stable

#========================
# Node 16x
#========================
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs

#========================
# Setup default user
#========================
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video,pulse-access chrome \
    && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome

WORKDIR /home/chrome
USER chrome

#========================
# Setup node app
#========================
COPY package*.json index.js ./
RUN npm ci --only=production && npm cache clean --force

COPY entry.sh /

ENTRYPOINT ["sh", "/entry.sh"]
