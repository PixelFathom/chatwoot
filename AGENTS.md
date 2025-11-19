# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chatwoot is an open-source customer support platform built with Ruby on Rails backend and Vue.js frontend. It's a full-stack application with enterprise features, multi-tenancy support, and extensive integrations.

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev` (starts Rails backend + Sidekiq + Vite)
- **Rails Only**: `bin/rails s -p 3000`
- **Frontend Only**: `bin/vite dev`
- **Background Jobs**: `bundle exec sidekiq -C config/sidekiq.yml`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch` (uses Vitest with jsdom)
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Build SDK**: `BUILD_MODE=library pnpm build:sdk` (creates single-file JavaScript SDK)

## Architecture Overview

### Backend Structure (Rails)
- **Rails 7.1** with Ruby 3.4.4
- **Multi-layered**: Controllers → Services → Models with background jobs (Sidekiq)
- **Enterprise**: `enterprise/` directory overlay for paid features (mixed into main app paths)
- **Services Pattern**: Business logic in `app/services/` organized by domain
- **Background Jobs**: `app/jobs/` with Sidekiq for async processing
- **API**: RESTful APIs with JSON responses, uses `jbuilder` for view rendering

### Frontend Structure (Vue.js)
- **Vue 3** with Composition API and `<script setup>`
- **Modular**: Multiple entry points (dashboard, widget, portal, SDK)
- **State Management**: Vuex store in `app/javascript/dashboard/store/`
- **Components**:
  - `components/` (legacy, being deprecated)
  - `components-next/` (new components, especially message bubbles)
  - `v3/` (Vue 3 migration components)
- **Build System**: Vite with vite-plugin-ruby for Rails integration
- **Testing**: Vitest with @vue/test-utils

### Key Directories
- `app/controllers/` - API controllers (RESTful endpoints)
- `app/services/` - Business logic layer
- `app/models/` - ActiveRecord models with relationships
- `app/jobs/` - Background job processing
- `app/javascript/dashboard/` - Main dashboard Vue app
- `app/javascript/widget/` - Customer-facing chat widget
- `app/javascript/sdk/` - JavaScript SDK for integration
- `enterprise/` - Enterprise-only features (overlaid onto main app)
- `spec/` - RSpec tests following Rails testing patterns

## Development Environment

### Dependencies
- **Runtime**: Ruby 3.4.4, Node 23.x, pnpm 10.x
- **Database**: PostgreSQL with Redis for caching/sessions
- **Background Jobs**: Sidekiq with Redis
- **Asset Pipeline**: Vite for frontend assets
- **Process Management**: Overmind (foreman alternative) for development

### Key Services
- Rails backend on port 3000
- Vite dev server for hot reloading
- Sidekiq for background job processing
- PostgreSQL for primary data
- Redis for sessions, caching, and job queues

## Code Style & Patterns

### Ruby/Rails
- **Style**: RuboCop rules (150 character max line length)
- **Services**: Use service objects in `app/services/` for business logic
- **Jobs**: Use Sidekiq jobs for async operations
- **Models**: Validate presence/uniqueness, add proper indexes
- **Controllers**: Keep thin, delegate to services
- **Exception Handling**: Use custom exceptions in `lib/custom_exceptions/`

### Vue.js/JavaScript
- **Style**: ESLint (Airbnb base + Vue 3 recommended)
- **Vue API**: Always use Composition API with `<script setup>` at the top
- **Components**: Use PascalCase for component names
- **Events**: Use camelCase for event names
- **State**: Vuex for global state, composables for reusable logic
- **Testing**: Vitest with Vue Test Utils for component testing

### Styling
- **Tailwind Only**:
  - Do not write custom CSS
  - Do not use scoped CSS
  - Do not use inline styles
  - Always use Tailwind utility classes
- **Colors**: Refer to `tailwind.config.js` and `theme/colors.js` for color definitions
- **Dark Mode**: Uses `class` strategy with Radix UI colors

## Internationalization (i18n)

- **Backend**: Update `en.yml` files only (community handles other languages)
- **Frontend**: Update `en.json` files only
- **No Hardcoded Strings**: Use i18n helpers in all templates and components
- **Translation Process**: Managed via Crowdin at translate.chatwoot.com

## Enterprise & Multi-tenancy

- **Enterprise Directory**: `enterprise/` contains paid features
- **Path Overlays**: Enterprise views/controllers/models override core ones
- **Feature Flags**: Use `flag_shih_tzu` gem for feature toggles
- **Account-based**: Multi-tenant architecture with account-scoped data

## Development Guidelines

### General
- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Break down complex tasks into small, testable units
- Remove dead/unreachable/unused code
- Don't write multiple versions or backups — pick best approach
- Don't reference Claude in commit messages

### Component Migration
- Use `components-next/` for new message bubble components
- Legacy `components/` directory is being deprecated
- Follow existing patterns in `components-next/` for consistency

### Testing Strategy
- Avoid writing specs unless explicitly asked
- Focus on integration tests for critical user flows
- Use factories for test data setup
- Mock external service calls in tests

### Performance Considerations
- Use database indexes for commonly queried fields
- Background jobs for time-intensive operations
- Redis caching for frequently accessed data
- Optimize N+1 queries with `includes` or `preload`