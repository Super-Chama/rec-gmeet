FROM ubuntu:20.04

RUN apt-get update && apt-get clean && apt-get install -yq gnupg curl \
    x11vnc \
    xvfb \
    fluxbox \
    wmctrl

RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -yq google-chrome-stable

RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome

WORKDIR /home/chrome
USER chrome

COPY entry.sh /

ENTRYPOINT ["sh", "/entry.sh"]
