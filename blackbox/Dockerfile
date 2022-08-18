FROM blackbox_exporter

COPY blackbox.yml /usr/local/etc/blackbox/

CMD ["--config.file=/usr/local/etc/blackbox/blackbox.yml", "--log.level=debug"]
