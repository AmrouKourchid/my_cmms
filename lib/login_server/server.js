const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const multer = require('multer');

const app = express();
const port = 5506;

const SECRET_KEY = 'your_secret_key';

app.use(bodyParser.json());
app.use(cors());

// MySQL connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'mysql',
  database: 'cmms',
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
    return;
  }
  console.log('Connected to MySQL');
});

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Set up multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({ storage });

// API to handle login
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  const query = 'SELECT * FROM administrator WHERE email = ? AND password = ?';

  db.query(query, [email, password], (err, results) => {
    if (err) {
      console.error('MySQL error:', err);
      res.status(500).send('Error checking login details');
      return;
    }

    if (results.length > 0) {
      const user = { email };
      const token = jwt.sign(user, SECRET_KEY, { expiresIn: '1h' });
      res.status(200).json({ message: 'Login successful', token });
    } else {
      res.status(401).send('Invalid email or password');
    }
  });
});

// API to register a new worker with image
app.post('/registerWorker', authenticateToken, upload.single('image'), (req, res) => {
  const { email, password } = req.body;
  const image = req.file ? req.file.buffer : null;
  const query = 'INSERT INTO worker (email, password, image) VALUES (?, ?, ?)';

  db.query(query, [email, password, image], (err, results) => {
    if (err) {
      console.error('Error registering worker:', err);
      res.status(500).send('Error registering worker');
      return;
    }

    res.status(200).json({ message: 'Worker registered successfully' });
  });
});

// API to delete a worker
app.delete('/deleteWorker', authenticateToken, (req, res) => {
  const { email } = req.body;
  const query = 'DELETE FROM worker WHERE email = ?';

  db.query(query, [email], (err, results) => {
    if (err) {
      console.error('Error deleting worker:', err);
      res.status(500).send('Error deleting worker');
      return;
    }

    res.status(200).send('Worker deleted successfully');
  });
});

// API to fetch all workers
app.get('/workers', authenticateToken, (req, res) => {
  const query = 'SELECT email, image FROM worker';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching workers:', err);
      res.status(500).send('Error fetching workers');
      return;
    }

    const workers = results.map(worker => ({
      email: worker.email,
      image: worker.image ? worker.image.toString('base64') : null,
    }));

    res.status(200).json(workers);
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});