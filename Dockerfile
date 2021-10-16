FROM ruby:2.3.0
RUN apt-get update -qq && apt-get install -y postgresql-client nodejs
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
COPY . /myapp

RUN bundle exec rake assets:precompile
EXPOSE 3000
# Start the main process.
CMD ["./run_script.sh"]
