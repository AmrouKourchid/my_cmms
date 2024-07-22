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

  const adminQuery = 'SELECT * FROM administrator WHERE email = ? AND password = ?';
  const workerQuery = 'SELECT * FROM worker WHERE email = ? AND password = ?';

  db.query(adminQuery, [email, password], (err, adminResults) => {
    if (err) {
      console.error('MySQL error:', err);
      res.status(500).send('Error checking login details');
      return;
    }

    if (adminResults.length > 0) {
      const user = { email, role: 'admin' };
      const token = jwt.sign(user, SECRET_KEY, { expiresIn: '1h' });
      res.status(200).json({ message: 'Login successful', token, role: 'admin' });
    } else {
      db.query(workerQuery, [email, password], (err, workerResults) => {
        if (err) {
          console.error('MySQL error:', err);
          res.status(500).send('Error checking login details');
          return;
        }

        if (workerResults.length > 0) {
          const worker = workerResults[0];
          const user = { email, role: 'worker', id: worker.id };
          const token = jwt.sign(user, SECRET_KEY, { expiresIn: '1h' });
          res.status(200).json({ message: 'Login successful', token, role: 'worker' });
        } else {
          res.status(401).send('Invalid email or password');
        }
      });
    }
  });
});

// API to register a new worker with image
app.post('/registerWorker', authenticateToken, upload.single('image'), (req, res) => {
  const { name, email, password, role, ssn } = req.body;
  const image = req.file ? req.file.buffer : null;
  const query = 'INSERT INTO worker (name, email, password, role, ssn, image) VALUES (?, ?, ?, ?, ?, ?)';

  db.query(query, [name, email, password, role, ssn, image], (err, results) => {
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
  const { name } = req.body;

  // First, fetch the worker ID based on the name
  const fetchWorkerIdQuery = 'SELECT id FROM worker WHERE name = ?';
  db.query(fetchWorkerIdQuery, [name], (err, results) => {
    if (err) {
      console.error('Error fetching worker ID:', err);
      res.status(500).send('Error fetching worker ID');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Worker not found');
      return;
    }

    const workerId = results[0].id;

    // Delete worker orders associated with the worker
    const deleteWorkerOrdersQuery = 'DELETE FROM worker_orders WHERE worker_id = ?';
    db.query(deleteWorkerOrdersQuery, [workerId], (err, results) => {
      if (err) {
        console.error('Error deleting worker orders:', err);
        res.status(500).send('Error deleting worker orders');
        return;
      }

      // Delete the worker
      const deleteWorkerQuery = 'DELETE FROM worker WHERE id = ?';
      db.query(deleteWorkerQuery, [workerId], (err, results) => {
        if (err) {
          console.error('Error deleting worker:', err);
          res.status(500).send('Error deleting worker');
          return;
        }

        res.status(200).send('Worker deleted successfully');
      });
    });
  });
});

// API to fetch all workers
app.get('/allWorkers', authenticateToken, (req, res) => {
  const query = 'SELECT id, name, image FROM worker';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching workers:', err);
      res.status(500).send('Error fetching workers');
      return;
    }

    const workers = results.map(worker => ({
      id: worker.id,
      name: worker.name,
      image: worker.image ? worker.image.toString('base64') : null,
    }));

    res.status(200).json(workers);
  });
});

// API to create a new work order
app.post('/createWorkOrder', authenticateToken, (req, res) => {
  const { worker_id, name, start_date, end_date, description } = req.body;
  const status = 'open';
  const query = 'INSERT INTO worker_orders (worker_id, name, start_date, end_date, description, status) VALUES (?, ?, ?, ?, ?, ?)';

  db.query(query, [worker_id, name, start_date, end_date, description, status], (err, results) => {
    if (err) {
      console.error('Error creating work order:', err);
      res.status(500).send('Error creating work order');
      return;
    }

    res.status(200).json({ message: 'Work order created successfully' });
  });
});

// API to fetch all workers
app.get('/workers', authenticateToken, (req, res) => {
  const query = 'SELECT name, image FROM worker';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching workers:', err);
      res.status(500).send('Error fetching workers');
      return;
    }

    const workers = results.map(worker => ({
      name: worker.name,
      image: worker.image ? worker.image.toString('base64') : null,
    }));

    res.status(200).json(workers);
  });
});

// API to fetch worker orders
app.get('/workerOrders', authenticateToken, (req, res) => {
  const workerId = req.user.id;
  const query = 'SELECT * FROM worker_orders WHERE worker_id = ?';

  db.query(query, [workerId], (err, results) => {
    if (err) {
      console.error('Error fetching worker orders:', err);
      res.status(500).send('Error fetching worker orders');
      return;
    }

    res.status(200).json(results);
  });
});

// API to fetch all work orders with assigned worker details
app.get('/allWorkOrders', authenticateToken, (req, res) => {
  const query = `
    SELECT wo.id, wo.name, DATE_FORMAT(wo.start_date, '%Y-%m-%d') as start_date, 
           DATE_FORMAT(wo.end_date, '%Y-%m-%d') as end_date, wo.description, wo.status, w.name as assigned_to
    FROM worker_orders wo
    JOIN worker w ON wo.worker_id = w.id
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching work orders:', err);
      res.status(500).send('Error fetching work orders');
      return;
    }

    res.status(200).json(results);
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});