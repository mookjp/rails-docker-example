#!/bin/bash
export SECRET_KEY_BASE=$(bundle exec rake secret) && \
    bundle exec rake db:migrate && \
    /opt/nginx/sbin/nginx
