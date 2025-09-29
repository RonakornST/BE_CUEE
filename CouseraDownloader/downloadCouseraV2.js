const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// Configuration
const COURSERA_LOGIN_URL = 'https://www.coursera.org/?authMode=login';
const SPECIALIZATION_URL = 'https://www.coursera.org/programs/program-8-wchpm/learn/linux-system-programming-introduction-to-buildroot?authProvider=chulalongkorn-faculty-of-engineering&specialization=advanced-embedded-linux-development'; // replace with your specialization URL
const DOWNLOAD_PATH = './downloads'; // download directory

const USERNAME = '6430332921@student.chula.ac.th'; // replace with your Coursera email
const PASSWORD = '4W627635'; // replace with your Coursera password

async function getCourseUrls(page) {
  await page.goto(SPECIALIZATION_URL);
  await page.waitForSelector('.rc-DomainNav a');
  const courseUrls = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('.rc-DomainNav a')).map(a => a.href);
  });
  return courseUrls;
}

async function downloadVideosFromCourse(page, courseUrl) {
  await page.goto(courseUrl);
  await page.waitForSelector('.rc-VideoItem');

  // Get all video URLs
  const videoUrls = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('.rc-VideoItem a')).map(a => a.href);
  });

  for (const videoUrl of videoUrls) {
    await page.goto(videoUrl);
    await page.waitForSelector('video');
    const videoSrc = await page.evaluate(() => {
      const videoElement = document.querySelector('video');
      return videoElement ? videoElement.src : null;
    });

    if (videoSrc) {
      const videoPage = await page.browser().newPage();
      const videoResponse = await videoPage.goto(videoSrc);
      const videoBuffer = await videoResponse.buffer();
      const videoName = videoUrl.split('/').pop() + '.mp4';
      const courseName = courseUrl.split('/').pop();
      const coursePath = path.join(DOWNLOAD_PATH, courseName);
      if (!fs.existsSync(coursePath)) {
        fs.mkdirSync(coursePath, { recursive: true });
      }
      const filePath = path.join(coursePath, videoName);
      fs.writeFileSync(filePath, videoBuffer);
      await videoPage.close();
      console.log(`Downloaded: ${videoName} from course ${courseName}`);
    } else {
      console.log(`Failed to download video from: ${videoUrl}`);
    }
  }
}

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  // Login to Coursera
  await page.goto(COURSERA_LOGIN_URL);
  await page.waitForSelector('input[name=email]');
  await page.type('input[name=email]', USERNAME);
  await page.type('input[name=password]', PASSWORD);
  await page.click('button[type=submit]');
  await page.waitForNavigation();

  // Ensure download directory exists
  if (!fs.existsSync(DOWNLOAD_PATH)) {
    fs.mkdirSync(DOWNLOAD_PATH);
  }

  // Get all course URLs in the specialization
  const courseUrls = await getCourseUrls(page);
  console.log(`Found ${courseUrls.length} courses in the specialization`);

  // Download videos from each course
  for (const courseUrl of courseUrls) {
    await downloadVideosFromCourse(page, courseUrl);
  }

  await browser.close();
})();
