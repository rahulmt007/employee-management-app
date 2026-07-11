<?php

$host     = getenv('DB_HOST');
$user     = getenv('DB_USER');
$password = getenv('DB_PASS');
$dbname   = getenv('DB_NAME');
$adminUser = getenv('AUTH_ADMIN_USER') ?: 'admin';
$adminPass = getenv('AUTH_ADMIN_PASS') ?: 'ChangeMe123!';
$loginError = "";

$conn = new mysqli(
    $host,
    $user,
    $password,
    $dbname
);

if ($conn->connect_error) {
    die("Database connection failed");
}

class DatabaseSessionHandler implements SessionHandlerInterface
{
    private mysqli $conn;

    public function __construct(mysqli $conn)
    {
        $this->conn = $conn;
    }

    public function open(string $path, string $name): bool
    {
        return true;
    }

    public function close(): bool
    {
        return true;
    }

    public function read(string $id): string|false
    {
        $stmt = $this->conn->prepare("
            SELECT session_data
            FROM sessions
            WHERE id=?
            LIMIT 1
        ");

        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $record = $result->fetch_assoc();
        $stmt->close();

        return $record ? $record['session_data'] : "";
    }

    public function write(string $id, string $data): bool
    {
        $stmt = $this->conn->prepare("
            INSERT INTO sessions(id, session_data, updated_at)
            VALUES(?, ?, NOW())
            ON DUPLICATE KEY UPDATE
                session_data=VALUES(session_data),
                updated_at=NOW()
        ");

        $stmt->bind_param("ss", $id, $data);
        $success = $stmt->execute();
        $stmt->close();

        return $success;
    }

    public function destroy(string $id): bool
    {
        $stmt = $this->conn->prepare("
            DELETE FROM sessions
            WHERE id=?
        ");

        $stmt->bind_param("s", $id);
        $success = $stmt->execute();
        $stmt->close();

        return $success;
    }

    public function gc(int $max_lifetime): int|false
    {
        $expiresBefore = time() - $max_lifetime;

        $stmt = $this->conn->prepare("
            DELETE FROM sessions
            WHERE updated_at < FROM_UNIXTIME(?)
        ");

        $stmt->bind_param("i", $expiresBefore);
        $stmt->execute();
        $affectedRows = $stmt->affected_rows;
        $stmt->close();

        return $affectedRows;
    }
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

// Create sessions table for load-balanced deployments
$conn->query("
CREATE TABLE IF NOT EXISTS sessions (
id VARCHAR(128) PRIMARY KEY,
session_data TEXT NOT NULL,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
");

session_set_save_handler(new DatabaseSessionHandler($conn), true);
session_start();

// Create users table
$conn->query("
CREATE TABLE IF NOT EXISTS users (
id INT AUTO_INCREMENT PRIMARY KEY,
username VARCHAR(100) NOT NULL UNIQUE,
password_hash VARCHAR(255) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
");

// Seed initial admin user
$userCountResult=$conn->query(
"SELECT COUNT(*) total FROM users"
);

$userCount=$userCountResult
->fetch_assoc()['total'];

if((int)$userCount === 0){

$passwordHash=password_hash($adminPass, PASSWORD_DEFAULT);

$stmt=$conn->prepare("
INSERT INTO users(username,password_hash)
VALUES(?,?)
");

$stmt->bind_param("ss", $adminUser, $passwordHash);
$stmt->execute();
$stmt->close();

}

// Logout
if(isset($_GET['logout'])){

session_unset();
session_destroy();

header("Location:index.php");

exit();

}

// Login
if(isset($_POST['login'])){

$loginUsername=trim($_POST['username']);
$loginPassword=$_POST['password'];

$stmt=$conn->prepare("
SELECT id, username, password_hash
FROM users
WHERE username=?
LIMIT 1
");

$stmt->bind_param("s", $loginUsername);
$stmt->execute();
$loginResult=$stmt->get_result();
$userRecord=$loginResult->fetch_assoc();
$stmt->close();

if($userRecord && password_verify($loginPassword, $userRecord['password_hash'])){

session_regenerate_id(true);

$_SESSION['user_id']=$userRecord['id'];
$_SESSION['username']=$userRecord['username'];

header("Location:index.php");

exit();

}

$loginError="Invalid username or password.";

}

$isAuthenticated=isset($_SESSION['user_id']);
$currentUser=$isAuthenticated ? htmlspecialchars($_SESSION['username'], ENT_QUOTES, 'UTF-8') : "";

if(!$isAuthenticated):

?>


<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Management Login</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>

<body class="auth-body">

    <main class="auth-page">
        <section class="auth-card">
            <div class="auth-brand">
                <span class="brand-icon">ID</span>
                <div>
                    <h1>Employee Management System</h1>
                </div>
            </div>

            <?php if($loginError !== ""): ?>
                <div class="alert alert-error">
                    <?= htmlspecialchars($loginError, ENT_QUOTES, 'UTF-8') ?>
                </div>
            <?php endif; ?>

            <form method="POST" class="form">
                <div class="form-group">
                    <label for="username">Username</label>
                    <input
                        id="username"
                        type="text"
                        name="username"
                        placeholder="Enter username"
                        autocomplete="username"
                        required>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input
                        id="password"
                        type="password"
                        name="password"
                        placeholder="Enter password"
                        autocomplete="current-password"
                        required>
                </div>

                <button
                    class="btn btn-primary"
                    type="submit"
                    name="login"
                    value="1">
                    Sign In
                </button>
            </form>
        </section>
    </main>

</body>
</html>


<?php

session_write_close();
$conn->close();

exit();

endif;

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

// Update employee
if(isset($_POST['update'])){

$id=(int)$_POST['id'];

$name =
$conn->real_escape_string($_POST['name']);

$address =
$conn->real_escape_string($_POST['address']);

$conn->query("
UPDATE employees
SET name='$name', address='$address'
WHERE id=$id
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

// Edit employee
$editEmployee=null;

if(isset($_GET['edit'])){

$editId=(int)$_GET['edit'];

$editResult=$conn->query("
SELECT *
FROM employees
WHERE id=$editId
LIMIT 1
");

if($editResult && $editResult->num_rows > 0){

$editEmployee=$editResult->fetch_assoc();

}

}

$isEditing=$editEmployee !== null;
$formName=$isEditing ? htmlspecialchars($editEmployee['name'], ENT_QUOTES, 'UTF-8') : "";
$formAddress=$isEditing ? htmlspecialchars($editEmployee['address'], ENT_QUOTES, 'UTF-8') : "";

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
                <span class="brand-icon">ID</span>
                <h1>Employee Management System</h1>
            </div>

            <div class="topbar-actions">
                <span class="user-pill">
                    <?= $currentUser ?>
                </span>

                <a class="btn btn-topbar" href="?logout=1">
                    Logout
                </a>
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
                    <h2><?= $isEditing ? "Edit Employee" : "Add Employee" ?></h2>
                </div>

                <form id="employee-form" method="POST" class="form">
                    <?php if($isEditing): ?>
                        <input
                            type="hidden"
                            name="id"
                            value="<?= $editEmployee['id'] ?>">
                    <?php endif; ?>

                    <div class="form-group">
                        <label for="name">Employee Name</label>
                        <input
                            id="name"
                            type="text"
                            name="name"
                            placeholder="Enter employee name"
                            value="<?= $formName ?>"
                            required>
                    </div>

                    <div class="form-group">
                        <label for="address">Employee Address</label>
                        <input
                            id="address"
                            type="text"
                            name="address"
                            placeholder="Enter employee address"
                            value="<?= $formAddress ?>"
                            required>
                    </div>

                    <div class="button-row">
                        <?php if($isEditing): ?>
                            <button class="btn btn-primary" name="update">
                                Update Employee
                            </button>

                            <a class="btn btn-light" href="index.php">
                                Cancel
                            </a>
                        <?php else: ?>
                            <button class="btn btn-primary" name="add">
                                Add Employee
                            </button>
                        <?php endif; ?>
                    </div>
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
                                        <div class="action-row">
                                            <a
                                                class="edit-link"
                                                href="?edit=<?= $row['id'] ?>#employee-form">
                                                Edit
                                            </a>

                                            <a
                                                class="delete-link"
                                                href="?delete=<?= $row['id'] ?>">
                                                Delete
                                            </a>
                                        </div>
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
        <p>Employee Management System &bull; Version 3.2.0</p>
    </footer>

    <script src="assets/js/app.js"></script>

</body>
</html>


<?php

session_write_close();
$conn->close();

?>
