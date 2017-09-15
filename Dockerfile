# Nginx extended with entrypoint script that
# renders Nginx config file templates, resolving
# specifically-marked env vars in them.

# ALl files in /etc/nginx and /etc/nginx/conf.d
# folders that end in .nginx.conf.template are rendered
# into *.nginx.conf files in same location but with
# all instances of ${SOME_VAR} resolved to its env var
# value before writing that file to *.nginx.conf

# Note that only dollar-prefixed-curly-surrounded markup is supported
# since native Nginx files use dollar-prefixed variables natively
# and the goal is NOT to mess with those.
ARG NGINX_VERSION=latest
FROM nginx:${NGINX_VERSION}

RUN echo "alias ll=\"ls -la --color\"" >> ~/.bashrc

EXPOSE 80

# docker_entrypoint pre-runs start of Nginx
# and inits resolve_env_vars.pl which
# finds all files in /etc/nginx and /etc/nginx/conf.d
# that
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/docker_entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

#COPY conf.d/ /etc/nginx/conf.d/
