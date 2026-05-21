const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// Cấu hình kết nối DB lấy trực tiếp từ Environment Variables do ECS nạp vào
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'db_admin',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'webappdb',
  port: 5432,
  // Tự động ngắt kết nối nếu timeout sau 2 giây để tránh kẹt thread
  connectionTimeoutMillis: 2000 
});

// 1. Endpoint quan trọng nhất: HEALTH CHECK cho Application Load Balancer (ALB)
app.get('/health', async (req, res) => {
  try {
    // Kiểm tra xem Container có nói chuyện được với Database không
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'UP', database: 'CONNECTED' });
  } catch (err) {
    // Nếu lỗi DB, vẫn trả về UP nhưng báo cảnh báo, hoặc trả về 500 tùy chiến lược giám sát
    res.status(500).json({ status: 'DOWN', error: err.message });
  }
});

// 2. Business Logic: Lấy danh sách Task công việc từ Database
app.get('/tasks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tasks ORDER BY id DESC');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Khởi chạy server lắng nghe ở Port 8080
app.listen(PORT, () => {
  console.log(`Application is running successfully on port ${PORT}`);
});
