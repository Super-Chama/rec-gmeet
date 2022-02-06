<h1 align="center">Rec Gmeet <img width="60px" src="https://sensa-co.s3-eu-west-1.amazonaws.com/emojis/camera.svg" alt="boomerang"/></h1>
<p align="center"><i>Dockerized puppeteer script to record google meet!</i></p>


[![Docker](https://github.com/Super-Chama/rec-gmeet/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Super-Chama/rec-gmeet/actions/workflows/docker-publish.yml)

## :sparkles: Inspired By
* zoomrec - https://github.com/kastldratza/zoomrec
* docker-selenium - https://github.com/elgalu/docker-selenium
* chrome-docker - https://github.com/stephen-fox/chrome-docker
* ctf-screenshotter - https://github.com/LiveOverflow/ctf-screenshotter

## :wrench: Built With (read dockerfile for full info)

* [puppeteer](https://pptr.dev/)
* [fluent-ffmpeg](https://github.com/fluent-ffmpeg/node-fluent-ffmpeg)

## :running: Getting Started

* With VNC (VNC can be used to check manually within container)
  ```sh
  docker run -p 5900:5900 --user chrome --privileged -e MEET_CODE='your-gmeet-code' chamaabe/rec-gmeet:latest
  ```
* Without VNC
  ```sh
  docker run MEET_CODE='your-gmeet-code' chamaabe/rec-gmeet:latest
  ```

## :pencil: License

This project is licensed under [MIT](https://opensource.org/licenses/MIT) license.

## :man_astronaut: Show your support

Give a :star: if this project helped you!
