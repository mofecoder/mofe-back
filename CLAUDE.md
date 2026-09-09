# MOFE Backend

Competitive programming platform (MOFE) backend API built with Rails 8.1 (API-only mode), Ruby 4.0.6, and MySQL 8.0.

## Development Environment

Development uses **Docker Compose**. All commands (rails, bundle, rake, etc.) MUST be run inside the app container:

```sh
docker compose exec app <command>
```

### Starting the environment

```sh
docker compose up --build    # Build and start all services
docker compose up            # Start services (without rebuilding)
docker compose down          # Stop and remove containers
```

### Services

| Service | Image       | Port  |
|---------|-------------|-------|
| app     | Ruby 4.0.6  | 3000  |
| db      | MySQL 8.0   | 3306  |

The database default credentials for development are `root` / `password` on host `db` (inside Docker network) or `127.0.0.1` (from host).

## Common Commands

All commands below should be prefixed with `docker compose exec app`.

### Database

```sh
bundle exec rails db:create      # Create databases
bundle exec rails db:migrate     # Run pending migrations
bundle exec rails db:seed        # Load seed data
bundle exec rails db:reset       # Drop, create, migrate, seed
```

### Testing

The project uses Minitest (Rails default). Fixtures are in `test/fixtures/`.

```sh
bundle exec rails test                         # Run all tests
bundle exec rails test test/models             # Run model tests only
bundle exec rails test test/controllers        # Run controller tests only
bundle exec rails test test/path/to/file.rb    # Run a specific test file
bundle exec rails test test/path/to/file.rb:42 # Run a specific test by line
```

### Other

```sh
bundle exec rails routes    # List all routes
bundle exec rails console   # Open Rails console
bundle install              # Install gem dependencies
```

## Git Branch Naming

- Main branch: `master`
- Feature branches: `feature/#<issue-number>`

## Architecture & Conventions

### API Versioning

The API has two namespaces:

- **`/api/`** (v1, legacy) — Uses `ActiveModelSerializers` for JSON serialization. Authorization is handled manually in controllers.
- **`/v4/`** (current) — Uses `Blueprinter` for serialization and `Pundit` for authorization. **New API endpoints should follow v4 patterns.**

### Authentication

Devise Token Auth. Token headers (`access-token`, `uid`, `client`, `expiry`) are used for authentication. The base controller includes `DeviseTokenAuth::Concerns::SetUserByToken`.

- `authenticate_user!` — requires login
- `authenticate_admin_user!` — requires admin role
- `current_user` — returns the logged-in `User` (delegates to `current_api_user`)

### Authorization (Pundit)

Used in v4 controllers via `V4::ApplicationController` which includes `Pundit::Authorization` and calls `after_action :verify_authorized`.

- Policies live in `app/policies/`
- `ApplicationPolicy` defaults all actions to `false` (deny by default)
- Each policy defines `index?`, `show?`, `create?`, `update?`, `destroy?` and a `Scope` class

### Serialization (Blueprinter)

Used in v4 controllers. Blueprints live in `app/blueprints/`.

- Use `view` blocks to define different response shapes (e.g., `:problem`, `:problem_detail`)
- Use `include_view` to compose views
- Use `association` for nested resources
- Use `preload` option on fields/associations to specify eager loading

### Soft Deletes (Discard)

All models inherit `Discard::Model` via `ApplicationRecord`. Soft-deleted records have a non-null `deleted_at` column and are excluded by the default scope (`kept`).

- Use `record.discard` to soft-delete (NOT `record.destroy`)
- Use `record.undiscard` to restore
- Use `Model.with_discarded` to include soft-deleted records in queries

### User Roles

Users have roles defined as an enum: `:member`, `:writer`, `:admin`.

## Key Directory Structure

```
app/
├── blueprints/         # Blueprinter serializers (v4)
├── controllers/
│   ├── api/            # v1 API controllers (legacy)
│   └── v4/             # v4 API controllers (preferred for new code)
├── models/             # ActiveRecord models
├── policies/           # Pundit authorization policies
├── serializers/        # ActiveModelSerializers (legacy, v1)
└── services/           # Service objects
test/
├── controllers/        # Controller tests
├── models/             # Model tests
├── policies/           # Policy tests
└── fixtures/           # Test fixtures (YAML)
```
