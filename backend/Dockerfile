FROM ruby:4.0.2-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
