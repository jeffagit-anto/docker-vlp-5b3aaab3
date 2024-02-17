# docker-vlp

Docker setup for legacy VLP website at https://vlp.mpiwg-berlin.mpg.de

The website uses
* Zope 2.13 [docker-legacy-zope](https://gitlab.gwdg.de/MPIWG/research-it/docker-legacy-zope) image.
* ZEO instance `zope/zeoVLP`.
* Zope instance `zope/zopeVLP` using the ZEO instance.
* Postgres 10 database (can be initialized using `import-vlpdb.sh`)
* [Varnish](https://varnish-cache.org/) 6.0 cache (configuration `conf/varnish/vlp.vcl`)
* PHP 7.4 with Apache 2.4 (built from `php-apache`, configuration in `conf/apache`)
* [Tomcat](https://tomcat.apache.org/) 9 (webapps in `tomcat`)
* proxy using [traefik](https://github.com/containous/traefik/) in [docker-multi-proxy](https://gitlab.gwdg.de/MPIWG/research-it/docker-multi-proxy)

# Running

* make sure the zope instance tree at `zope/zopeVLP` and `zope/zeoVLP` is accessible to the "zope" user (uid=1000, gid=1000)
* create `.env` file containing at least `POSTGRES_PASSWORD`.

Start containers with
```
docker-compose up -d
```

On first start import database using
```
./import-vlpdb.sh
```

ZEO writes log files in `zope/zeoVLP/log`, other services log to their container.
