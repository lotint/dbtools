CURPATH = $(shell pwd)
CREADER = $(CURPATH)/read_config.py
DBS = $(shell .env/bin/python $(CREADER) sections $(CURPATH)/databases.yml)
all: prepare $(DBS)
.env:
	virtualenv -p python3 .env
prepare: .env
	.env/bin/pip install -r requirements.txt
$(DBS): % : dir_%
	@psql -d $@ -f get_backup_tables.sql
	for i in $(shell psql -d $@ -c "SELECT * FROM backup.get_tables()" -t); do \
		psql -d $@ -c "SELECT backup.save_state('$$i')"; \
		pg_dump -Fc -t $$i -d $@ -f pg_dumps/dir_$@/$$i.dump; \
		done
dir_%:
	@mkdir -p pg_dumps/$@
clean:
	@rm -rf ./pg_dumps
