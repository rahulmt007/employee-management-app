<?php

$host     = getenv('DB_HOST');
$user     = getenv('DB_USER');
$password = getenv('DB_PASS');
$dbname   = getenv('DB_NAME');

$conn = new mysqli(
    $host,
    $user,
    $password,
    $dbname
);

if ($conn->connect_error) {
    die("Database connection failed");
}

// Create table
$conn->query("
CREATE TABLE IF NOT EXISTS employees (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
address VARCHAR(200) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
");

// Add employee
if(isset($_POST['add'])){

$name =
$conn->real_escape_string($_POST['name']);

$address =
$conn->real_escape_string($_POST['address']);

$conn->query("
INSERT INTO employees(name,address)
VALUES('$name','$address')
");

header("Location:index.php");

exit();

}

// Delete employee
if(isset($_GET['delete'])){

$id=(int)$_GET['delete'];

$conn->query(
"DELETE FROM employees WHERE id=$id"
);

header("Location:index.php");

exit();

}

// Search
$search="";

if(isset($_GET['search'])){

$search =
$conn->real_escape_string($_GET['search']);

}

$result=$conn->query("
SELECT *
FROM employees
WHERE name LIKE '%$search%'
ORDER BY created_at DESC
");

// Count
$countResult=$conn->query(
"SELECT COUNT(*) total FROM employees"
);

$total=$countResult
->fetch_assoc()['total'];

?>


<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Management System</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>

<body>

    <header class="topbar">
        <div class="topbar-content">
            <div class="brand">
                <span class="brand-icon">👨‍💼</span>
                <h1>Employee Management System</h1>
            </div>
        </div>
    </header>

    <main class="page">

        <section class="stats-grid">
            <div class="stat-card">
                <div>
                    <p class="stat-label">Total Employees</p>
                    <h2><?= $total ?></h2>
                </div>
                <div class="stat-icon">👥</div>
            </div>
        </section>

        <section class="content-grid">

            <div class="card">
                <div class="card-header">
                    <h2>Add Employee</h2>
                </div>

                <form method="POST" class="form">
                    <div class="form-group">
                        <label for="name">Employee Name</label>
                        <input
                            id="name"
                            type="text"
                            name="name"
                            placeholder="Enter employee name"
                            required>
                    </div>

                    <div class="form-group">
                        <label for="address">Employee Address</label>
                        <input
                            id="address"
                            type="text"
                            name="address"
                            placeholder="Enter employee address"
                            required>
                    </div>

                    <button class="btn btn-primary" name="add">
                        Add Employee
                    </button>
                </form>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>Search Employee</h2>
                </div>

                <form method="GET" class="form search-form">
                    <div class="form-group">
                        <label for="search">Search by Name</label>
                        <input
                            id="search"
                            name="search"
                            placeholder="Search employee by name..."
                            value="<?= htmlspecialchars($search) ?>">
                    </div>

                    <div class="button-row">
                        <button class="btn btn-secondary">
                            Search
                        </button>

                        <?php if($search !== ""): ?>
                            <a class="btn btn-light" href="index.php">Clear</a>
                        <?php endif; ?>
                    </div>
                </form>
            </div>

        </section>

        <section class="card directory-card">
            <div class="card-header table-header">
                <div>
                    <h2>Employee Directory</h2>
                </div>
            </div>

            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>Employee ID</th>
                            <th>Employee Name</th>
                            <th>Address</th>
                            <th>Created</th>
                            <th>Action</th>
                        </tr>
                    </thead>

                    <tbody>
                        <?php if($result->num_rows > 0): ?>
                            <?php while($row=$result->fetch_assoc()): ?>
                                <tr>
                                    <td>
                                        <span class="employee-id">
                                            #<?= $row['id'] ?>
                                        </span>
                                    </td>

                                    <td>
                                        <strong><?= htmlspecialchars($row['name']) ?></strong>
                                    </td>

                                    <td>
                                        <?= htmlspecialchars($row['address']) ?>
                                    </td>

                                    <td>
                                        <?= $row['created_at'] ?>
                                    </td>

                                    <td>
                                        <a
                                            class="delete-link"
                                            href="?delete=<?= $row['id'] ?>">
                                            Delete
                                        </a>
                                    </td>
                                </tr>
                            <?php endwhile; ?>
                        <?php else: ?>
                            <tr>
                                <td colspan="5" class="empty-state">
                                    No employee records found.
                                </td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </section>

    </main>

    <footer class="footer">
        <p>Employee Management System • Version 2.0</p>
    </footer>

    <script src="assets/js/app.js"></script>

</body>
</html>


<?php

$conn->close();

?>
