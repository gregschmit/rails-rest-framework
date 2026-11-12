require "test_helper"

# The paginator's `next`/`previous` URLs must point back at the exact endpoint the client is using:
# the same host, path, format, and query params, with only the page changed.
#
# `Api::Test::UsersController` paginates with `page_size = 2`, so 3 users guarantee a second page.
class Api::PaginationUrlsTest < ActionDispatch::IntegrationTest
  def setup
    3.times { |i| User.create!(login: "pg_url_#{i}", state: "default", status: "") }
  end

  # Follow a link the way a client would, so the assertion covers the whole round trip.
  def follow(url)
    get(URI.parse(url).request_uri)
    assert_response(:success)
    @response.parsed_body
  end

  def test_urls_use_the_request_host_not_default_url_options
    original = Rails.application.routes.default_url_options.dup
    # A default host that differs from the request (like an API served on a subdomain).
    Rails.application.routes.default_url_options.merge!(host: "other.example.com", protocol: "http")

    get("/api/test/users.json?page=1", headers: { "HTTP_HOST" => "api.example.com" })
    assert_response(:success)

    next_url = response.parsed_body["next"]
    assert(next_url.present?, "expected a next page")
    assert_equal("api.example.com", URI.parse(next_url).host, "next should use the request host")
  ensure
    Rails.application.routes.default_url_options.clear
    Rails.application.routes.default_url_options.merge!(original)
  end

  def test_urls_keep_the_path_format_extension
    get("/api/test/users.json?page=1")
    assert_response(:success)

    next_url = response.parsed_body["next"]
    assert_equal("/api/test/users.json", URI.parse(next_url).path)

    # One hop further: the format must survive every page, not just the first.
    previous_url = self.follow(next_url)["previous"]
    assert_equal("/api/test/users.json", URI.parse(previous_url).path)
  end

  def test_urls_keep_the_format_query_param
    get("/api/test/users?format=json&page=1")
    assert_response(:success)

    next_url = response.parsed_body["next"]
    assert_equal("json", Rack::Utils.parse_query(URI.parse(next_url).query)["format"])

    # One hop further, since the first page could carry the format without the next page doing so.
    previous_url = self.follow(next_url)["previous"]
    assert_equal("json", Rack::Utils.parse_query(URI.parse(previous_url).query)["format"])
  end

  # Params named after routing keys must stay ordinary query params, not route directives that could
  # raise or aim the page URLs at a different collection.
  def test_routing_named_query_params_are_not_routing_directives
    get("/api/test/users.json?page=1&action=whoami&controller=api/test/movies")
    assert_response(:success)

    next_url = URI.parse(response.parsed_body["next"])
    assert_equal("/api/test/users.json", next_url.path)

    query = Rack::Utils.parse_query(next_url.query)
    assert_equal("whoami", query["action"])
    assert_equal("api/test/movies", query["controller"])
    assert_equal("2", query["page"])
  end

  def test_urls_keep_nested_and_repeated_params
    get("/api/test/users.json?page=1&ordering=login&tags[]=a&tags[]=b")
    assert_response(:success)

    query = Rack::Utils.parse_nested_query(URI.parse(response.parsed_body["next"]).query)
    assert_equal("login", query["ordering"])
    assert_equal([ "a", "b" ], query["tags"])
  end
end
