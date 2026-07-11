# Containerization Guide

## Overview

This project includes Docker support so the PHP Employee Management Application can run locally without AWS.

The local Docker stack runs:

- PHP 8.2 with Apache
- MySQL 8.0
- The same application environment variables used in AWS:
  - `DB_HOST`
  - `DB_USER`
  - `DB_PASS`
  - `DB_NAME`
  - `AUTH_ADMIN_USER`
  - `AUTH_ADMIN_PASS`

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds the PHP + Apache application image |
| `.dockerignore` | Keeps non-runtime files out of the image build context |
| `docker-compose.yml` | Runs the app and MySQL locally |
| `app/sql/database.sql` | Initializes the local MySQL database |

## Local Requirements

Install Docker Desktop or Docker Engine with Docker Compose support.

Verify:

```bash
docker --version
docker compose version
```

## If Docker Is Not Recognized

If Git Bash or Command Prompt shows:

```text
docker: command not found
```

or:

```text
'docker' is not recognized as an internal or external command
```

Docker Desktop is not installed, not running, or its CLI is not available on `PATH`.

On Windows:

1. Install Docker Desktop for Windows.
2. Start Docker Desktop from the Start menu.
3. Wait until Docker Desktop says the engine is running.
4. Close and reopen Git Bash or Command Prompt.
5. Run:

```bash
docker --version
docker compose version
docker info
```

If Docker Desktop is already installed but the command still fails, restart Windows and check that Docker Desktop is allowed to update the system `PATH`.

## Run Locally

From the repository root:

```bash
docker compose up --build
```

Open:

```text
http://localhost:8080
```

Health check:

```text
http://localhost:8080/healthcheck.php
```

Expected response:

```text
OK
```

## Local Database

The MySQL container uses these development-only values:

| Variable | Value |
| --- | --- |
| `MYSQL_DATABASE` | `employeedb` |
| `MYSQL_USER` | `employee_user` |
| `MYSQL_PASSWORD` | `employee_pass` |
| `MYSQL_ROOT_PASSWORD` | `root_pass` |
| `AUTH_ADMIN_USER` | `admin` |
| `AUTH_ADMIN_PASS` | `ChangeMe123!` |

The MySQL port is exposed locally as:

```text
localhost:3307
```

The data is stored in the Docker volume:

```text
employee_mysql_data
```

## Stop the Stack

```bash
docker compose down
```

Stop and remove the database volume:

```bash
docker compose down -v
```

Use `-v` only when you want to delete local MySQL data.

## Build Image Only

```bash
docker build -t employee-management-app:local .
```

Run the image against an existing database:

```bash
docker run --rm -p 8080:80 \
  -e DB_HOST=<database-host> \
  -e DB_USER=<database-user> \
  -e DB_PASS=<database-password> \
  -e DB_NAME=employeedb \
  employee-management-app:local
```

## Verification Checklist

- App opens at `http://localhost:8080`
- Health check returns `OK`
- Login works with `admin` / `ChangeMe123!`
- Add Employee works
- Search Employee works
- Edit Employee pre-fills name and address
- Update Employee saves changes
- Delete Employee works

## Release Notes

Docker support is intended for local development and portfolio review. The existing AWS EC2 deployment pipeline remains available and unchanged.
