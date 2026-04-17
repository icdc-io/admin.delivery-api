# Delivery API

## Overview

`delivery-api` is a lightweight Ruby on Rails application that provides a set of HTTP APIs for managing services on OpenShift environments. It does **not** use a database – all operations are performed by interacting directly with the SCM API and the OpenShift API. The service exposes endpoints for checking the status of services, installing, upgrading, downgrading, and removing them.

## Tech Stack

- **Ruby** ~> 3.0 (as defined in `Gemfile`)
- **Rails** ~> 6.1.4 (web framework)
- **Puma** ~> 5.0 (app server)
- **Redis** ~> 5.3 (caching/mutex handling)
- **Rack‑CORS** (CORS handling)
- **dotenv** (environment variable loading)
- **json‑jwt**, **jwt**, **rest‑client** (API communication)
- **Docker** (containerised runtime)
- **Bundler** (dependency management)
- **Rubocop**, **RSpec** (linting and testing)

## Prerequisites

- Ruby 3.x (compatible with the version specified in `Gemfile`)
- Bundler (`gem install bundler`)
- Docker (optional – for containerised development)
- Access credentials for SCM and OpenShift APIs

## Installation & Local Development

```bash

# Install Ruby dependencies
bundle install

# Start the server
rails server -b 0.0.0.0 -p 3000
# Or using the Dockerfile
docker build -t delivery-api .
docker run -p 3000:3000 delivery-api
```

The API will be available at `http://localhost:3000`. Health check endpoint:

```bash
curl http://localhost:3000/up   # → "Up!"
```

### Available API Routes (excerpt)

- `GET /api/v1/services/status` – overall services status
- `GET /api/v1/services/apps` – list of apps
- `GET /api/v1/services` – list all services
- `GET /api/v1/services/:service_name` – details for a specific service
- `POST /api/v1/services/:service_name/install` – install a service
- `PUT /api/v1/services/:service_name/release` – upgrade a service
- `PUT /api/v1/services/:service_name/downgrade` – downgrade a service
- `PUT /api/v1/services/:service_name/update` – apply configuration updates
- `DELETE /api/v1/services/:service_name` – remove a service

## Testing

```bash
# Run the RSpec test suite
bundle exec rspec
```

## License

This project is licensed under the MIT License – see the `LICENSE` file for details.
