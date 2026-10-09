const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8082;
const HTML_FILE = path.join(__dirname, 'web_demo', 'index.html');

const server = http.createServer((req, res) => {
  fs.readFile(HTML_FILE, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Lỗi nạp file giao diện demo: ' + err.message);
      return;
    }
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache'
    });
    res.end(data);
  });
});

// Bind to 0.0.0.0 so physical phones on the same Wi-Fi can connect
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n======================================================');
  console.log('📱 VKU EXPENSE OCR — MÁY CHỦ DEMO CHO ĐIỆN THOẠI THẬT');
  console.log('======================================================');
  console.log('1. Trên máy tính, bạn có thể mở:  http://localhost:' + PORT);
  console.log('2. Trên ĐIỆN THOẠI (cùng Wi-Fi), bạn mở: http://192.168.1.109:' + PORT);
  console.log('======================================================\n');
});
