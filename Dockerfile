FROM ruby:3.2.2-bookworm as base
LABEL org.opencontainers.image.source=https://github.com/gregschmit/rails-rest-framework
WORKDIR /app
ENV BUNDLE_PATH="/usr/local/bundle"
ENV RAILS_ENV="production"
ENV DISABLE_DATABASE_ENVIRONMENT_CHECK="1"

# Throw-away build stage to reduce size of final image
FROM base as build

# Setup application gems.
COPY .ruby-version .rails-version rest_framework.gemspec Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

# Setup application.
COPY . .
RUN SECRET_KEY_BASE=1 bin/rails runner "RESTFramework::Version.stamp_version"
RUN SECRET_KEY_BASE=1 bin/rails db:reset
RUN SECRET_KEY_BASE=1 LOGS=all bin/rails log:clear tmp:clear
RUN rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
RUN rm -rf .git

# Final stage for app image.
FROM base

# Copy built artifacts: gems, application.
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

EXPOSE 3000
CMD ["bin/rails", "server"]
