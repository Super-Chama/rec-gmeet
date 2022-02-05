const puppeteer = require("puppeteer-core");

const meetURL = "https://meet.google.com";
const meetCode = process.env.MEET_CODE;
const meetUsername = process.env.MEET_USER || "Aaron";
const meetTimeout = process.env.MEET_TIMEOUT || 10000;

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
      timeout: meetTimeout,
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

(async function () {
  try {
    meetCode && await launchPuppeteer();
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit();
  }
})();
