const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// Configuration
const COURSERA_LOGIN_URL = 'https://www.coursera.org/?authMode=login';
const COURSE_URL = 'https://www.coursera.org/learn/course-name'; // replace with your course URL
const DOWNLOAD_PATH = './downloads'; // download directory

const USERNAME = 'your-email@example.com'; // replace with your Coursera email
const PASSWORD = 'your-password'; // replace with your Coursera password

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
  
  // Navigate to the course page
  await page.goto(COURSE_URL);
  await page.waitForSelector('.rc-VideoItem');
  
  // Get all video URLs
  const videoUrls = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('.rc-VideoItem a')).map(a => a.href);
  });

  // Ensure download directory exists
  if (!fs.existsSync(DOWNLOAD_PATH)){
    fs.mkdirSync(DOWNLOAD_PATH);
  }

  // Download videos
  for (const videoUrl of videoUrls) {
    await page.goto(videoUrl);
    await page.waitForSelector('video');
    const videoSrc = await page.evaluate(() => {
      const videoElement = document.querySelector('video');
      return videoElement ? videoElement.src : null;
    });
    
    if (videoSrc) {
      const videoPage = await browser.newPage();
      const videoResponse = await videoPage.goto(videoSrc);
      const videoBuffer = await videoResponse.buffer();
      const videoName = videoUrl.split('/').pop() + '.mp4';
      const filePath = path.join(DOWNLOAD_PATH, videoName);
      fs.writeFileSync(filePath, videoBuffer);
      await videoPage.close();
      console.log(`Downloaded: ${videoName}`);
    } else {
      console.log(`Failed to download video from: ${videoUrl}`);
    }
  }

  await browser.close();
})();
