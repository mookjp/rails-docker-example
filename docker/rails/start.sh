#!/bin/bash
export SECRET_KEY_BASE=$(rake secret) && \
    rake db:migrate && \
    /opt/nginx/sbin/nginx
