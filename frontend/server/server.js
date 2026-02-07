const express = require('express');
const compression = require('compression');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;

// Enable gzip compression
app.use(compression());

// Serve static files from the Flutter web build
app.use(express.static(path.join(__dirname, 'web'), {
  maxAge: '1d',
  etag: true,
}));

// Handle client-side routing - serve index.html for all routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`ToolKUDU Web running on port ${PORT}`);
});
