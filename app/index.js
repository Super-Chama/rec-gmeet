const puppeteer = require("puppeteer-core");

const chromeHost = "127.0.0.1";
const chromePort = "9222";
const meetURL = "https://meet.google.com";
const meetCode = "kay-shnj-pvd";
const meetUsername = "Jordan";
const lobbyTimeout = 10000;

const launchPuppeteer = async () => {
  // connect with chrome instance
  // defaultViewport will auto adjust
  const browser = await puppeteer.connect({
    browserURL: `http://${chromeHost}:${chromePort}`,
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
  });

  // Enter username to join
  await page.type("input[type=text]", meetUsername, { delay: 20 });

  // Ready to join, click join
  const joinButton = await page.$x("//span[text()='Ask to join']");
  await joinButton[0].click();

  // End call button should appear if successfully joined.
  // waiting in the meeting lobby untill someone allow to join
  const quitButton = await page
    .waitForXPath("//i[text()='call_end']", {
      timeout: lobbyTimeout,
    })
    .catch(() => {
      throw new Error("Couldn't join meeting, lobbyTimeout");
    });

  if (quitButton[0]) {
    console.info("Joined meeting " + meetCode);
  }
  await page.waitForTimeout(15000);
  await page.screenshot({ path: `screenshots/${new Date()}.png` });
  await page.close();
};

(function () {
  try {
    await launchPuppeteer();
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit();
  }
})();
