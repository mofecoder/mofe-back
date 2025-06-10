FROM ruby:3.4.4 as build

WORKDIR /app

RUN gem install bundler

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

COPY . .

EXPOSE 3000
ENTRYPOINT rm -f ./tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0
