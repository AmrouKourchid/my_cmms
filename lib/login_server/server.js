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
  const clientQuery = 'SELECT * FROM client WHERE email = ? AND password = ?';

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
          db.query(clientQuery, [email, password], (err, clientResults) => { // Ensure this query is correctly nested
            if (err) {
              console.error('MySQL error:', err);
              res.status(500).send('Error checking login details');
              return;
            }

            if (clientResults.length > 0) {
              const client = clientResults[0];
              const user = { email, role: 'client', id: client.id };
              const token = jwt.sign(user, SECRET_KEY, { expiresIn: '1h' });
              res.status(200).json({ message: 'Login successful', token, role: 'client' });
            } else {
              res.status(401).send('Invalid email or password');
            }
          });
        }
      });
    }
  });
});

// API to register a new worker with image
app.post('/registerPerson', authenticateToken, upload.single('image'), (req, res) => {
  const { name, email, password, role, ssn } = req.body;
  const image = req.file ? req.file.buffer : null;
  const table = role === 'client' ? 'client' : 'worker'; // Determine the table based on role

  const query = `INSERT INTO ${table} (name, email, password, role, ssn, image) VALUES (?, ?, ?, ?, ?, ?)`;

  db.query(query, [name, email, password, role, ssn, image], (err, results) => {
    if (err) {
      console.error(`Error registering ${role}:`, err);
      res.status(500).send(`Error registering ${role}`);
      return;
    }

    res.status(200).json({ message: `${role.charAt(0).toUpperCase() + role.slice(1)} registered successfully` });
  });
});

// API to delete a worker
app.delete('/deleteWorker', authenticateToken, (req, res) => {
  const { id } = req.body;

  const deleteWorkerQuery = 'DELETE FROM worker WHERE id = ?';
  db.query(deleteWorkerQuery, [id], (err, results) => {
    if (err) {
      console.error('Error deleting worker:', err);
      res.status(500).send('Error deleting worker');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Worker not found');
      return;
    }

    res.status(200).send('Worker deleted successfully');
  });
});

// API to fetch all workers
app.get('/people', authenticateToken, (req, res) => {
  const query = `
    (SELECT id, name, image, 'worker' AS role FROM worker)
    UNION ALL
    (SELECT id, name, image, 'client' AS role FROM client)
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching people:', err);
      res.status(500).send('Error fetching people');
      return;
    }

    const people = results.map(person => ({
      id: person.id,
      name: person.name,
      image: person.image ? person.image.toString('base64') : null,
      role: person.role
    }));

    res.status(200).json(people);
  });
});

// API to create a new work order
app.post('/createWorkOrder', authenticateToken, upload.array('images', 10), (req, res) => {
  const { worker_id, asset_id, name, start_date, end_date, description } = req.body;
  const status = 'open';
  const images = req.files.map(file => file.buffer.toString('base64')); // Convert to base64

  if (!worker_id || !asset_id) {
    res.status(400).send('Worker ID and Asset ID are required');
    return;
  }

  const query = 'INSERT INTO worker_orders (worker_id, asset_id, name, start_date, end_date, description, status, images) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';

  db.query(query, [worker_id, asset_id, name, start_date, end_date, description, status, JSON.stringify(images)], (err, results) => {
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

// API to fetch all work orders with assigned worker and asset details
app.get('/allWorkOrders', authenticateToken, (req, res) => {
  const query = `
    SELECT wo.id, wo.name, DATE_FORMAT(wo.start_date, '%Y-%m-%d') as start_date, 
           DATE_FORMAT(wo.end_date, '%Y-%m-%d') as end_date, wo.description, wo.status, 
           w.name as assigned_to, a.name as asset_name
    FROM worker_orders wo
    JOIN worker w ON wo.worker_id = w.id
    JOIN asset a ON wo.asset_id = a.id
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

// API to fetch worker details
app.get('/workerDetails', authenticateToken, (req, res) => {
  const workerId = req.user.id;

  const query = 'SELECT id, name, image FROM worker WHERE id = ?';

  db.query(query, [workerId], (err, results) => {
    if (err) {
      console.error('Error fetching worker details:', err);
      res.status(500).send('Error fetching worker details');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Worker not found');
      return;
    }

    const worker = results[0];
    res.status(200).json({
      id: worker.id,
      name: worker.name,
      image: worker.image ? worker.image.toString('base64') : null,
    });
  });
});

// API to update work order status
app.put('/updateWorkOrderStatus/:id', authenticateToken, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const workerId = req.user.id;

  const query = 'UPDATE worker_orders SET status = ? WHERE id = ? AND worker_id = ?';

  db.query(query, [status, id, workerId], (err, results) => {
    if (err) {
      console.error('Error updating work order status:', err);
      res.status(500).send('Error updating work order status');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Work order not found or not authorized');
      return;
    }

    res.status(200).json({ message: 'Work order status updated successfully' });
  });
});

// API to delete a work order
app.delete('/deleteWorkOrder/:id', authenticateToken, (req, res) => {
  const { id } = req.params;

  // Check if the work order exists and the asset ID matches
  const checkQuery = 'SELECT * FROM worker_orders WHERE id = ?';
  db.query(checkQuery, [id], (err, results) => {
    if (err) {
      console.error('Error checking work order:', err);
      res.status(500).send('Error checking work order');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Work order not found');
      return;
    }

    // Delete the work order
    const deleteQuery = 'DELETE FROM worker_orders WHERE id = ?';
    db.query(deleteQuery, [id], (err, results) => {
      if (err) {
        console.error('Error deleting work order:', err);
        res.status(500).send('Error deleting work order');
        return;
      }

      res.status(200).json({ message: 'Work order deleted successfully' });
    });
  });
});

// API to add a new asset
app.post('/addAsset', authenticateToken, upload.single('image'), (req, res) => {
  const { name, status } = req.body;
  const image = req.file ? req.file.buffer : null;



    // Insert the new asset
    const query = 'INSERT INTO asset (name, status, image) VALUES (?, ?, ?)';
    db.query(query, [name, status, image], (err, results) => {
      if (err) {
        console.error('Error adding asset:', err);
        res.status(500).send('Error adding asset');
        return;
      }

      res.status(200).json({ message: 'Asset added successfully' });
    });
});


// API to delete an asset
app.delete('/deleteAsset/:id', authenticateToken, (req, res) => {
  const { id } = req.params;

  // Delete the asset
  const deleteQuery = 'DELETE FROM asset WHERE id = ?';
  db.query(deleteQuery, [id], (err, results) => {
    if (err) {
      console.error('Error deleting asset:', err);
      res.status(500).send('Error deleting asset');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Asset not found');
      return;
    }

    res.status(200).json({ message: 'Asset deleted successfully' });
  });
});

// API to fetch all assets
app.get('/fetchAssets', authenticateToken, (req, res) => {
  const query = 'SELECT id, name, status, image FROM asset';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching assets:', err);
      res.status(500).send('Error fetching assets');
      return;
    }

    const assets = results.map(asset => ({
      id: asset.id,
      name: asset.name,
      status: asset.status,
      image: asset.image ? asset.image.toString('base64') : null,
    }));

    res.status(200).json(assets);
  });
});

// API to fetch details of a single work order
app.get('/workOrder/:id', authenticateToken, (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT wo.id, wo.name, DATE_FORMAT(wo.start_date, '%Y-%m-%d') as start_date, 
           DATE_FORMAT(wo.end_date, '%Y-%m-%d') as end_date, wo.description, wo.status, 
           w.name as assigned_to, a.name as asset_name, wo.images
    FROM worker_orders wo
    JOIN worker w ON wo.worker_id = w.id
    JOIN asset a ON wo.asset_id = a.id
    WHERE wo.id = ?
  `;

  db.query(query, [id], (err, results) => {
    if (err) {
      console.error('Error fetching work order details:', err);
      res.status(500).send('Error fetching work order details');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Work order not found');
      return;
    }

    const workOrder = results[0];
    workOrder.images = workOrder.images ? JSON.parse(workOrder.images) : [];

    res.status(200).json(workOrder);
  });
});

// API to create a new report
app.post('/createReport', authenticateToken, upload.array('pictures', 10), (req, res) => {
  const { worker_id, work_order_id, Question1, Question2, Question3, Question4, Question5, Question6 } = req.body;
  const pictures = req.files.map(file => file.buffer.toString('base64')); // Convert to base64

  const query = 'INSERT INTO reports (worker_id, work_order_id, Question1, Question2, Question3, Question4, Question5, Question6, pictures) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';

  db.query(query, [parseInt(worker_id), parseInt(work_order_id), Question1, Question2, Question3, Question4, Question5, Question6, JSON.stringify(pictures)], (err, results) => {
    if (err) {
      console.error('Error creating report:', err);
      res.status(500).send('Error creating report');
      return;
    }

    // Update the work order status to 'closed'
    const updateQuery = 'UPDATE worker_orders SET status = ? WHERE id = ? AND worker_id = ?';
    db.query(updateQuery, ['closed', parseInt(work_order_id), parseInt(worker_id)], (err, results) => {
      if (err) {
        console.error('Error updating work order status:', err);
        res.status(500).send('Error updating work order status');
        return;
      }

      res.status(200).json({ message: 'Report created and work order status updated to closed' });
    });
  });
});
// API to create a new report
app.post('/createReport', authenticateToken, upload.array('pictures', 10), (req, res) => {
  const { worker_id, work_order_id, Question1, Question2, Question3, Question4, Question5, Question6 } = req.body;
  const pictures = req.files.map(file => file.buffer.toString('base64')); // Convert to base64

  const query = 'INSERT INTO reports (worker_id, work_order_id, Question1, Question2, Question3, Question4, Question5, Question6, pictures) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';

  db.query(query, [worker_id, work_order_id, Question1, Question2, Question3, Question4, Question5, Question6, JSON.stringify(pictures)], (err, results) => {
    if (err) {
      console.error('Error creating report:', err);
      res.status(500).send('Error creating report');
      return;
    }

    
    app.get('/reportByWorkOrderId/:workOrderId', authenticateToken, (req, res) => {
      const { workOrderId } = req.params;
    
      const query = `
        SELECT r.*, w.name as worker_name
        FROM reports r
        JOIN worker w ON r.worker_id = w.id
        WHERE r.work_order_id = ?
      `;
    
      db.query(query, [workOrderId], (err, results) => {
        if (err) {
          console.error('Error fetching report:', err);
          res.status(500).send('Error fetching report');
          return;
        }
    
        if (results.length === 0) {
          res.status(404).send('Report not found');
          return;
        }
    
        const report = results[0];
        report.pictures = report.pictures ? JSON.parse(report.pictures) : [];
        res.status(200).json(report);
      });
    });

    // Update the work order status to 'closed'
    const updateQuery = 'UPDATE worker_orders SET status = ? WHERE id = ? AND worker_id = ?';
    db.query(updateQuery, ['closed', work_order_id, worker_id], (err, results) => {
      if (err) {
        console.error('Error updating work order status:', err);
        res.status(500).send('Error updating work order status');
        return;
      }

      res.status(200).json({ message: 'Report created and work order status updated to closed' });
    });
  });
});
app.get('/reportByWorkOrderId/:workOrderId', authenticateToken, (req, res) => {
  const { workOrderId } = req.params;

  const query = `
    SELECT r.question1, r.question2, r.question3, r.question4, r.question5, r.question6, w.name as worker_name, r.pictures
    FROM reports r
    JOIN worker w ON r.worker_id = w.id
    WHERE r.work_order_id = ?
  `;

  db.query(query, [workOrderId], (err, results) => {
    if (err) {
      console.error('Error fetching report:', err);
      res.status(500).send('Error fetching report');
      return;
    }

    if (results.length === 0) {
      res.status(404).send('Report not found');
      return;
    }

    const report = results[0];
    report.pictures = report.pictures ? JSON.parse(report.pictures) : [];
    res.status(200).json(report);
  });
});

// API to handle client login




app.post('/createWorkRequest', authenticateToken, (req, res) => {
  const { client_id, site, asset_id, date_of_fault, description } = req.body;

  const query = 'INSERT INTO work_request (client_id, site, asset_id, date_of_fault, description) VALUES (?, ?, ?, ?, ?)';

  db.query(query, [client_id, site, asset_id, date_of_fault, description], (err, results) => {
    if (err) {
      console.error('Error creating work request:', err);
      res.status(500).send('Error creating work request');
      return;
    }
    res.status(200).json({ message: 'Work request created successfully' });
  });
});
// API to fetch all work requests with client details
app.get('/workRequests', authenticateToken, (req, res) => {
  const query = `
    SELECT wr.id, wr.site, wr.asset_id, wr.date_of_fault, wr.description, c.name as client_name, a.name as asset_name
    FROM work_request wr
    JOIN client c ON wr.client_id = c.id
    JOIN asset a ON wr.asset_id = a.id
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching work requests:', err);
      res.status(500).send('Error fetching work requests');
      return;
    }

    res.status(200).json(results);
  });
});

// API to delete a work request
app.delete('/deleteWorkRequest/:id', authenticateToken, (req, res) => {
  const { id } = req.params;

  const deleteQuery = 'DELETE FROM work_request WHERE id = ?';
  db.query(deleteQuery, [id], (err, results) => {
    if (err) {
      console.error('Error deleting work request:', err);
      res.status(500).send('Error deleting work request');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Work request not found');
      return;
    }

    res.status(200).send('Work request deleted successfully');
  });
});

// API to update asset status
app.put('/updateAssetStatus/:id', authenticateToken, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const query = 'UPDATE asset SET status = ? WHERE id = ?';
  db.query(query, [status, id], (err, results) => {
    if (err) {
      console.error('Error updating asset status:', err);
      res.status(500).send('Error updating asset status');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Asset not found');
      return;
    }

    res.status(200).send('Asset status updated successfully');
  });
});
app.get('/getWorkers', authenticateToken, (req, res) => {
  const query = 'SELECT id, name, image FROM worker';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching workers:', err);
      res.status(500).send('Error fetching workers');
      return;
    }
    const workers = results.map(worker => ({
      id: worker.id.toString(), // Convert id to string
      name: worker.name,
      image: worker.image ? worker.image.toString('base64') : null,
    }));
    res.status(200).json(workers);
  });
});


app.delete('/deleteClient', authenticateToken, (req, res) => {
  const { id } = req.body;

  const deleteClientQuery = 'DELETE FROM client WHERE id = ?';
  db.query(deleteClientQuery, [id], (err, results) => {
    if (err) {
      console.error('Error deleting client:', err);
      res.status(500).send('Error deleting client');
      return;
    }

    if (results.affectedRows === 0) {
      res.status(404).send('Client not found');
      return;
    }

    res.status(200).json({ message: 'Client deleted successfully' });
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
