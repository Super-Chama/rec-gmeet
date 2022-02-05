#!/bin/bash

# Based on: http://www.richud.com/wiki/Ubuntu_Fluxbox_GUI_with_x11vnc_and_Xvfb

main() {
    log_i "Starting xvfb virtual display..."
    launch_xvfb
    log_i "Starting window manager..."
    launch_window_manager
    log_i "Starting pulse audio..."
    launch_pulse_audio
    log_i "Starting VNC server..."
    launch_vnc_server
    log_i "Starting ffmpeg..."
    launch_ffmpeg
    log_i "Starting google chrome..."
    launch_google_chrome
}

launch_xvfb() {
    local xvfbLockFilePath="/tmp/.X1-lock"
    if [ -f "${xvfbLockFilePath}" ]
    then
        log_i "Removing xvfb lock file '${xvfbLockFilePath}'..."
        if ! rm -v "${xvfbLockFilePath}"
        then
            log_e "Failed to remove xvfb lock file"
            exit 1
        fi
    fi

    # Set defaults if the user did not specify envs.
    export DISPLAY=${XVFB_DISPLAY:-:1}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-960x540x24}
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either Xvfb to be fully up or we hit the timeout.
    Xvfb ${DISPLAY} -screen ${screen} ${resolution} &
    local loopCount=0
    until xdpyinfo -display ${DISPLAY} > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            log_e "xvfb failed to start"
            exit 1
        fi
    done
}

launch_window_manager() {
    local timeout=${XVFB_TIMEOUT:-5}

    # Start and wait for either fluxbox to be fully up or we hit the timeout.
    fluxbox &
    local loopCount=0
    until wmctrl -m > /dev/null 2>&1
    do
        loopCount=$((loopCount+1))
        sleep 1
        if [ ${loopCount} -gt ${timeout} ]
        then
            log_e "fluxbox failed to start"
            exit 1
        fi
    done
}

launch_vnc_server() {
    local passwordArgument='-nopw'

    if [ -n "${VNC_SERVER_PASSWORD}" ]
    then
        local passwordFilePath="${HOME}/.x11vnc.pass"
        if ! x11vnc -storepasswd "${VNC_SERVER_PASSWORD}" "${passwordFilePath}"
        then
            log_e "Failed to store x11vnc password"
            exit 1
        fi
        passwordArgument=-"-rfbauth ${passwordFilePath}"
        log_i "The VNC server will ask for a password"
    else
        log_w "The VNC server will NOT ask for a password"
    fi

    x11vnc -display ${DISPLAY} -forever ${passwordArgument} &
}

launch_google_chrome() {
    /usr/bin/google-chrome \
    --disable-dev-shm-usage \
    --start-maximized \
    --disable-background-networking \
    --disable-default-apps \
    --disable-extensions \
    --disable-sync \
    --disable-web-resources \
    --remote-debugging-port=9222 \
    --use-fake-ui-for-media-stream \
    --remote-debugging-address=0.0.0.0 \
    --no-default-browser-check --no-first-run --disable-fre \
    --flag-switches-begin --disable-features=ChromeWhatsNewUI --flag-switches-end \
    --user-data-dir=/home/chrome &
    wait $!
}

launch_pulse_audio() {
    # Cleanup to ensure pulseaudio is stateless
    rm -rf /var/run/pulse /var/lib/pulse /home/chrome/.config/pulse

    # Start audio
    pulseaudio -D --exit-idle-time=-1 --log-level=error

    # Create speaker Dummy-Output
    pactl load-module module-null-sink sink_name=speaker sink_properties=device.description="speaker" > /dev/null
    pactl set-source-volume 1 100%

    # Create microphone Dummy-Output
    pactl load-module module-null-sink sink_name=microphone sink_properties=device.description="microphone" > /dev/null
    pactl set-source-volume 2 100%

    # Map microphone-Output to microphone-Input
    pactl load-module module-loopback latency_msec=1 source=2 sink=microphone > /dev/null
    pactl load-module module-remap-source master=microphone.monitor source_name=microphone source_properties=device.description="microphone" > /dev/null
    # Set microphone Volume
    pactl set-source-volume 3 60%
}

launch_ffmpeg() {
    ffmpeg -nostats -loglevel quiet -f pulse -ac 2 -i 1 -f x11grab -r 30 \
    -s 960x540 -i ${DISPLAY} -acodec pcm_s16le -vcodec libx264rgb -preset ultrafast \
    -crf 0 -threads 0 -async 1 -vsync 1 /home/chrome/test.mkv &
}

log_i() {
    log "[INFO] ${@}"
}

log_w() {
    log "[WARN] ${@}"
}

log_e() {
    log "[ERROR] ${@}"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${@}"
}

control_c() {
    echo ""
    exit
}

trap control_c SIGINT SIGTERM SIGHUP

main

exit
