// Datadog APM Integration
const tracer = require('dd-trace').init({
  service: 'my-node-app',
  env: 'production',
  version: '1.0.0',
  logInjection: true,
  debug: true
});

const express = require('express');
const axios = require('axios');
const app = express();
const port = 3000;

// Middleware to simulate random processing time and errors
app.use((req, res, next) => {
  const randomDelay = Math.floor(Math.random() * 1000); // Random delay between 0-1000ms
  setTimeout(() => {
    if (Math.random() < 0.3) {
      // Simulate a 30% chance of an error
      next(new Error('Something went wrong!'));
    } else {
      next();
    }
  }, randomDelay);
});

// Basic routes
app.get('/', (req, res) => {
  res.send('Hello, world!');
});

app.get('/event', (req, res) => {
  console.log('Simulating a custom event...');
  res.send('Event logged!');
});

app.get('/error', (req, res) => {
  throw new Error('This is a forced error for testing purposes.');
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.message);
  res.status(500).send('Internal Server Error');
});

// Periodic traffic generation
function generateTraffic() {
  const routes = ['/', '/event', '/error'];
  const route = routes[Math.floor(Math.random() * routes.length)];

  axios.get(`http://localhost:${port}${route}`)
    .then(response => {
      console.log(`Automated request to ${route}: ${response.status}`);
    })
    .catch(error => {
      console.error(`Automated request error: ${error.message}`);
    });
}

// Start generating traffic every 5 seconds
setInterval(generateTraffic, 5000);

// Start the server
app.listen(port, () => {
  console.log(`App is running at http://localhost:${port}`);
});
