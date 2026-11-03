ARG RUBY_VERSION=4.0.1
FROM ruby:$RUBY_VERSION-slim as base

# Rack app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libsqlite3-dev

# Install application gems
COPY Gemfile* .
RUN bundle install


# Final stage for app image
FROM base

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libsqlite3-0 tor && \
    rm -rf /var/lib/apt/lists/*

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash && \
    chown ruby:ruby /app
USER ruby:ruby

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app

# Copy application code
COPY --chown=ruby:ruby . .

# Reddit blocks datacenter IPs, so the Reddit channel goes through Tor.
ENV REDDIT_PROXY=http://127.0.0.1:9080

# Start Tor in the background, then the server
EXPOSE 8080
CMD ["sh", "-c", "tor --SocksPort 0 --HTTPTunnelPort 127.0.0.1:9080 --DataDirectory /tmp/tor --Log 'notice stdout' & exec bundle exec ruby server.rb"]
