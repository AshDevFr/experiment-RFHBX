FROM ruby:4.0.2-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      libyaml-dev \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install && \
    # Ensure extensions is a directory, not a file — Docker volume
    # initialisation copies the image contents into the named volume and
    # fails with "mkdir extensions: file exists" when Bundler leaves a
    # placeholder file instead of a directory.
    rm -f /usr/local/bundle/extensions 2>/dev/null; \
    mkdir -p /usr/local/bundle/extensions

COPY . .
RUN chmod +x bin/*

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Use bundle exec to bypass shebang issues from bind-mounted scripts
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
