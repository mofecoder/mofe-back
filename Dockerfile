FROM ruby:2.6.3 as build

WORKDIR /app
COPY Gemfile ./
COPY Gemfile.lock ./

RUN gem install bundler
RUN bundle install

COPY . .

EXPOSE 3000
ENTRYPOINT ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
