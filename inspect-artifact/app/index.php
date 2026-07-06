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


$id=$_GET['delete'];


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

<html>

<head>


<title>
Employee Management
</title>



<style>


body{


font-family:Arial;

background:#f2f4f8;

margin:0;

}



.container{


width:90%;

max-width:900px;

margin:40px auto;


}



.header{


background:#232f3e;

color:white;

padding:20px;

border-radius:10px;


}



.card{


background:white;

padding:20px;

margin-top:20px;

border-radius:10px;

box-shadow:0 3px 10px #ccc;


}



input{


padding:12px;

width:90%;

margin:8px;


}



button{


background:#ff9900;

color:white;

border:0;

padding:12px 25px;

cursor:pointer;

border-radius:5px;


}



table{


width:100%;

border-collapse:collapse;


}


th{


background:#232f3e;

color:white;

padding:12px;


}


td{


padding:10px;

background:white;

border-bottom:1px solid #ddd;


}



.delete{


color:red;

font-weight:bold;

}


.count{


font-size:40px;

color:#232f3e;


}



</style>


</head>



<body>


<div class="container">



<div class="header">


<h1>
👨‍💼 Employee Management System
</h1>


<p>
AWS EC2 + PHP + MySQL Demo
</p>


</div>



<div class="card">


<h2>
Total Employees
</h2>


<div class="count">

<?= $total ?>

</div>


</div>




<div class="card">


<h2>
Add Employee
</h2>



<form method="POST">


<input
type="text"
name="name"
placeholder="Employee Name"
required>


<br>


<input

type="text"

name="address"

placeholder="Employee Address"

required>


<br>


<button name="add">

Add Employee

</button>



</form>


</div>




<div class="card">


<h2>
Search Employee
</h2>


<form>


<input

name="search"

placeholder="Search by name"

value="<?= $search ?>">



<button>

Search

</button>


</form>


</div>




<div class="card">


<h2>
Employee Records
</h2>



<table>


<tr>


<th>ID</th>

<th>Name</th>

<th>Address</th>

<th>Date</th>

<th>Action</th>


</tr>



<?php while($row=$result->fetch_assoc()): ?>


<tr>


<td>

<?= $row['id'] ?>

</td>



<td>

<?= htmlspecialchars($row['name']) ?>

</td>


<td>

<?= htmlspecialchars($row['address']) ?>

</td>



<td>

<?= $row['created_at'] ?>

</td>



<td>


<a class="delete"

href="?delete=<?= $row['id'] ?>"

onclick="return confirm('Delete employee?')">

Delete

</a>


</td>


</tr>



<?php endwhile; ?>



</table>



</div>


</div>


</body>


</html>


<?php

$conn->close();

?>