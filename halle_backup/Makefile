CURPATH = $(shell pwd)
CREADER = $(CURPATH)/read_config.py
DBS = $(shell python $(CREADER) sections $(CURPATH)/databases.yml)
all: $(DBS)
$(DBS): % : dir_%
	@psql -d $@ -f get_backup_tables.sql
	for i in $(shell psql -d $@ -c "SELECT * FROM backup.get_tables()" -t); do \
		psql -d $@ -c "SELECT backup.save_state($$i)"; \
		pg_dump -Fc -t $$i -d $@ -f pg_dumps/dir_$@/$$i.dump; \
		done
dir_%:
	@mkdir -p pg_dumps/$@
clean:
	@rm -rf ./pg_dumps
