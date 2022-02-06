const ffmpeg = require("fluent-ffmpeg");
const puppeteer = require("puppeteer-core");

const meetURL = "https://meet.google.com";
const meetCode = process.env.MEET_CODE;
const meetUsername = process.env.MEET_USER || "Aaron";
const meetTimeout = process.env.MEET_TIMEOUT || 10000;
const globalTimeout = process.env.PUP_TIMEOUT || 5000;

console.info(
  `Meet code = ${meetCode}`,
  `Meet user = ${meetUsername}`,
  `Meet Timeout = ${meetTimeout}`,
  `Global Timeout = ${globalTimeout}`
);

const launchPuppeteer = async () => {
  // connect with chrome instance
  // defaultViewport will auto adjust
  const browser = await puppeteer.connect({
    browserURL: `http://localhost:9222`,
    defaultViewport: null,
  });

  // Set camera, mic, notification access. prevents popup!
  const context = browser.defaultBrowserContext();
  await context.overridePermissions(meetURL, [
    "camera",
    "microphone",
    "notifications",
  ]);

  // Launches meeting page
  const page = await browser.newPage();
  await page.goto(`${meetURL}/${meetCode}`, {
    waitUntil: "networkidle2",
    timeout: globalTimeout
  });
  page.setDefaultTimeout(globalTimeout);

  // Enter username to join
  await page.type("input[type=text]", meetUsername, { delay: 20 });

  // Ready to join, click join
  const joinButton = await page.$x("//span[text()='Ask to join']");
  await joinButton[0].click();

  // End call button should appear if successfully joined.
  // waiting in the meeting lobby untill someone allow to join
  await page
    .waitForSelector('button[aria-label="Leave call"]', {
      timeout: meetTimeout,
    })
    .catch(() => {
      throw new Error("Couldn't join meeting, lobbyTimeout");
    });

  console.info("Joined meeting " + meetCode);
  await page.waitForXPath("//span[text()='Return to home screen']", {
    timeout: 0,
  });
  console.info("Meeting ended " + meetCode);
  await page.close();
};

const launchFfmpeg = () => {
  return ffmpeg()
    .addInput(":1")
    .inputFormat("x11grab")
    .inputOptions(["-r 30", "-s 960x540"])
    .addInput("1")
    .inputFormat("pulse")
    .inputOptions("-ac 2")
    .outputOptions([
      "-c:a pcm_s16le",
      "-c:v libx264rgb",
      "-preset ultrafast",
      "-crf 0",
      "-threads 0",
      "-async 1",
      "-vsync 1",
    ])
    .on("start", () => {
      console.info("video recording started...");
    })
    .on("end", () => {
      console.info("video recording finished...");
    })
    .on("error", (err) => {
      throw new Error(err);
    })
    .save(
      `/home/chrome/videos/recording_${meetCode}_${new Date().valueOf()}.mkv`
    );
};

(async function () {
  try {
    if (meetCode) {
      const ffmpegCommad = launchFfmpeg();
      await launchPuppeteer();
      // end recording
      // https://github.com/fluent-ffmpeg/node-fluent-ffmpeg/issues/673
      ffmpegCommad.ffmpegProc.stdin.write("q");
    }
    // process.exit();
  } catch (error) {
    console.error(error);
    process.exit();
  }
})();
