# Authentication Guide

## Overview

The Employee Management Application includes simple PHP session authentication.

Authentication protects the employee dashboard and CRUD operations. The public health check endpoint remains separate in `healthcheck.php` so AWS, Docker, and Kubernetes health probes continue to work.

## How It Works

- `index.php` starts a PHP session.
- A `users` table is created automatically if it does not exist.
- If the `users` table is empty, the app seeds one admin user.
- Passwords are stored with PHP `password_hash()`.
- Login verification uses `password_verify()`.
- Successful login regenerates the session ID.
- Logout clears and destroys the session.

## Users Table

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Admin Seed Variables

| Variable | Purpose |
| --- | --- |
| `AUTH_ADMIN_USER` | Initial admin username |
| `AUTH_ADMIN_PASS` | Initial admin password |

If these variables are not set, the local/demo defaults are:

```text
admin
ChangeMe123!
```

Use stronger values for AWS or any shared environment.

## Important Behavior

The admin user is seeded only when the `users` table is empty.

Changing `AUTH_ADMIN_USER` or `AUTH_ADMIN_PASS` after the first seed does not automatically update an existing database user. To reseed in a demo environment, clear the `users` table or recreate the local database volume.

## Docker

`docker-compose.yml` sets local demo credentials:

```yaml
AUTH_ADMIN_USER: admin
AUTH_ADMIN_PASS: ChangeMe123!
```

Open:

```text
http://localhost:8080
```

Then sign in before testing employee CRUD.

## Kubernetes

`k8s/secret.example.yaml` includes:

```yaml
AUTH_ADMIN_USER: admin
AUTH_ADMIN_PASS: ChangeMe123!
```

For real environments, create a Kubernetes Secret manually instead of committing real credentials.

## AWS EC2 Deployment

The GitHub Actions workflow passes optional secrets:

```text
AUTH_ADMIN_USER
AUTH_ADMIN_PASS
```

The deployment script writes them into Apache environment configuration.

Recommended GitHub repository secrets:

```text
AUTH_ADMIN_USER=<your-admin-user>
AUTH_ADMIN_PASS=<strong-password>
```

Do not share screenshots or logs that expose these values.

## Verification

1. Open the app.
2. Confirm the login page appears.
3. Sign in with the configured admin credentials.
4. Confirm the employee dashboard loads.
5. Confirm Logout returns to the login page.
6. Confirm unauthenticated access to `index.php` shows the login page.
7. Confirm `healthcheck.php` still returns `OK`.
