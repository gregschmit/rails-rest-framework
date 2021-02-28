---
layout: default
title: Pagination
position: 5
slug: pagination
---
# Pagination

For large result sets, you may need to provide pagination. You can configure the paginator for a
controller by setting the `paginator_class` to the paginator you want to use.

## PageNumberPaginator

This is a simple paginator which splits a recordset into pages and allows the user to select the
desired page using the `page` query parameter (e.g., `/api/movies?page=3`). To adjust this query
parameter, set the `page_query_param` controller attribute.

By default the user can adjust the page size using the `page_size` query param. To adjust this query
parameter, you can set the `page_size_query_param` controller attribute, or set it to `nil` to
disable this functionality. By default, there is no upper limit to the size of a page a user can
request. To enforce an upper limit, set the `max_page_size` controller attribute.
