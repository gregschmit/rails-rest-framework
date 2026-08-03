require "test_helper"

# Pagination `next`/`previous` URLs must be anchored to the request's own host, even when the app's
# `default_url_options` host differs — e.g. an API served on a subdomain. Regression for `next`
# reporting the `default_url_options` host (dropping the subdomain) instead of the request host.
class Api::PaginationHostTest < ActionDispatch::IntegrationTest
  def test_next_url_uses_the_request_host_not_default_url_options
    original = Rails.application.routes.default_url_options.dup
    # A default host that differs from the request (like the infra app's main-domain default).
    Rails.application.routes.default_url_options.merge!(host: "other.example.com", protocol: "http")

    3.times { |i| User.create!(login: "pg_host_#{i}", state: "default", status: "") }

    # `Api::Test::UsersController` paginates with `page_size = 2`, so page 1 has a next page.
    get("/api/test/users.json?page=1", headers: { "HTTP_HOST" => "api.example.com" })
    assert_response(:success)

    next_url = response.parsed_body["next"]
    assert(next_url.present?, "expected a next page")
    assert_equal("api.example.com", URI.parse(next_url).host, "next should use the request host")
  ensure
    Rails.application.routes.default_url_options.clear
    Rails.application.routes.default_url_options.merge!(original)
  end
end
