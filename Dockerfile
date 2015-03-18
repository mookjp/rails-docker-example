FROM ruby:2.2.1
MAINTAINER Mook <mookjpy@gmail.com>

# Install nginx with passenger
RUN gem install passenger -v 5.0.4 && \
    apt-get update && \
    apt-get install -y libcurl4-openssl-dev && \
    passenger-install-nginx-module --auto

ADD docker/rails/conf/nginx.conf /opt/nginx/conf/nginx.conf

# Add configuration to set daemon mode off
RUN echo "daemon off;" >> /opt/nginx/conf/nginx.conf

# Install Rails dependencies
RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install --system

ADD . /usr/src/app

# Initialize log
RUN cat /dev/null > /usr/src/app/log/production.log
RUN chmod -R a+w /usr/src/app/log

EXPOSE 80

ENV RAILS_ENV=production

ADD docker/rails/start.sh /usr/src/app/
RUN chmod +x /usr/src/app/start.sh
WORKDIR /usr/src/app/
CMD ["./start.sh"]
