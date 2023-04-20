---
layout: default
title: Filtering / Ordering
position: 4
slug: filtering-and-ordering
---
# Filtering and Ordering

While you can control the recordset that the API exposes, sometimes you want the user to control the
records they want to see, or the order of those records. Both filtering and ordering are
accomplished through what we call filters. To control the filter backends that a controller uses,
you can either adjust the `filter_backends` controller attribute or you can override the
`get_filter_backends()` method.

## ModelFilter

This filter provides basic user-controllable filtering of the recordset using query params. For
example, a request to `/api/movies?cool=true` could return movies where `cool` is `true`.

If you include `ModelControllerMixin` into your controller, `ModelFilter` is included in the filter
backends by default.

## ModelOrderingFilter

This filter provides basic user-controllable ordering of the recordset using query params. For
example, a request to `/api/movies?ordering=name` could order the movies by `name` rather than `id`.
`ordering=-name` would invert the ordering. You can also order with multiple parameters with a comma
separated list, like: `ordering=director,-name`.

If you include `ModelControllerMixin` into your controller, `ModelOrderingFilter` is included in the
filter backends by default. You can use `ordering_fields` to controller which fields are allowed to
be ordered by. To adjust the parameter that the user passes, adjust `ordering_query_param`; the
default is `"ordering"`.

## ModelSearchFilter

This filter provides basic user-controllable searching of the recordset using the `search` query
parameter (adjustable with the `search_query_param`). For example, a request to
`/api/movies?search=Star` could return movies where `name` contains the string `Star`. The search is
performed against the `search_fields` attribute, but if that is not set, then the search is
performed against a configurable default set of fields (`search_columns`).
