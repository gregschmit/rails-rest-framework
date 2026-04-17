# Authentication / Authorization

REST Framework takes no opinion on *how* you authenticate — that decision lives with your Rails
app. Any approach that works in a normal Rails controller works here: a `before_action` that
sets `current_user`, Devise's `authenticate_user!`, `authenticate_with_http_token`, JWT, HTTP
basic, whatever you already have. CSRF is already skipped
(`skip_before_action :verify_authenticity_token`) on every controller that includes
`RESTFramework::Controller`, so token-based flows require no extra setup.

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  before_action :authenticate   # Or `authenticate_user!` for Devise, etc.
end
```

The rest of this section is about the two things the framework *does* help with: scoping the
recordset to the current user, and returning auth errors in the framework's JSON format.

## Scoping with `get_recordset`

Once you have `current_user`, restrict the recordset so users only see their own records.
Override `get_recordset` on the instance:

```ruby
class Api::MoviesController < ApiController
  self.model = Movie

  def get_recordset
    current_user.movies
  end
end
```

Because the framework's `show`, `update`, and `destroy` all look up records through
`get_recordset` (via `get_record`), this single override is enough to make the controller
tenant-aware for **all** built-in actions — no extra policy code needed. Bulk `update_all` and
`destroy_all` also operate on the scoped recordset, so a user can't bulk-destroy someone else's
records.

Records filtered out of the recordset return `404`, not `403` — existence-hiding rather than
leaking that the record exists but is inaccessible. This is usually what you want.

### Auto-Associating New Records

With `create_from_recordset = true` (the default), new records inherit conditions from the
recordset. Combined with a user-scoped `get_recordset`, `POST`s automatically associate to the
current user without you needing to set `user_id`:

```ruby
def get_recordset
  current_user.movies   # POST /api/movies will auto-set user_id to current_user.id.
end
```

### Policy Libraries

If you use Pundit or CanCanCan, `get_recordset` is where they plug in:

```ruby
# Pundit
def get_recordset
  policy_scope(Movie)
end

# CanCanCan
def get_recordset
  Movie.accessible_by(current_ability)
end
```

Per-action authorization (e.g., `authorize(record)` for Pundit, `authorize!(:update, record)`
for CanCanCan) goes in a `before_action` or in overridden action methods, the same way you'd
use them in any Rails controller.

## Returning Good Error Responses

The framework rescues common `ActiveRecord` errors into a consistent JSON shape
(`{ message:, errors?: }`). Aim for the same shape when returning auth errors so clients only
parse one format.

### 401 vs. 403

- **`401 Unauthorized`** — the request isn't authenticated (missing or invalid credentials).
  Use `head(:unauthorized)` when the authentication callback fails.
- **`403 Forbidden`** — the request is authenticated, but the user isn't allowed to do this.
  Use `render(api: { message: "..." }, status: :forbidden)`.

This distinction matters: a browser client may redirect on `401` but surface an error on `403`.

### Rescuing Policy Exceptions

Pundit and CanCanCan raise exceptions on policy failures; rescue them on the parent controller
so they render as JSON instead of HTML:

```ruby
class ApiController < ApplicationController
  include RESTFramework::Controller

  rescue_from Pundit::NotAuthorizedError do |_|
    render(api: { message: "Not authorized." }, status: :forbidden)
  end

  # Or for CanCanCan:
  # rescue_from CanCan::AccessDenied do |e|
  #   render(api: { message: e.message }, status: :forbidden)
  # end
end
```
