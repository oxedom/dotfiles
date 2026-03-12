# Run Backend Database Migrations

# IMPORTANT:

NEVER EVER TOUCH THE PRODUCTION ENVIRONMENT!

This command allows you to run database migrations for the `backend-my-training-app` package in different environments (development, staging).

## Usage

To run migrations, use the following command in the root of the project:

```bash
pnpm backend:migrate <environment>
```

Replace `<environment>` with one of the following:

- `dev`: For development environment (`migrate:up:dev`)
- `staging`: For staging environment (`migrate:up:staging`)

## Examples

Run migrations for the development environment:

```bash
pnpm backend:migrate:up:dev
```
