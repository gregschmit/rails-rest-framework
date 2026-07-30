require "test_helper"

# `page_total_count = false` skips the `COUNT(*)` query: the paginated response omits `count` and
# `total_pages`, and `next` is derived by fetching one extra record rather than from `total_pages`.
class Api::Test::NoTotalCountControllerTest < ActionController::TestCase
  def test_response_omits_count_and_total_pages
    get(:index, as: :json, params: { page: 1 })
    assert_response(:success)

    body = @response.parsed_body
    assert_not(body.key?("count"), "count must be omitted when page_total_count is false")
    assert_not(
      body.key?("total_pages"), "total_pages must be omitted when page_total_count is false"
    )
    assert_equal(1, body["page"])
    assert_equal(2, body["page_size"])
    assert_operator(body["results"].length, :<=, 2)
  end

  def test_next_link_is_derived_without_a_count
    # Three users guarantee a second page (page_size is 2), so `next` must be present on page 1 and
    # `previous` absent — derived purely from the one-extra-record fetch.
    3.times { |i| User.create!(login: "no_count_#{i}", state: "default", status: "") }

    get(:index, as: :json, params: { page: 1 })
    assert_response(:success)
    body = @response.parsed_body

    assert(body["next"].present?, "next should be present when a further page exists")
    assert_nil(body["previous"], "previous should be nil on the first page")
  end

  def test_no_count_query_is_issued
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      queries << payload[:sql]
    end

    get(:index, as: :json, params: { page: 1 })
    assert_response(:success)

    assert(
      queries.none? { |q| q.match?(/SELECT\s+COUNT/i) },
      "no COUNT query should run when page_total_count is false, got: #{queries.inspect}",
    )
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def test_next_link_absent_past_the_end
    get(:index, as: :json, params: { page: 1_000_000 })
    assert_response(:success)
    body = @response.parsed_body

    assert_empty(body["results"])
    assert_nil(body["next"], "next must be nil when no further records exist")
  end
end
