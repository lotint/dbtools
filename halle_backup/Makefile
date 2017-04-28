CURPATH = $(shell pwd)
CREADER = $(CURPATH)/read_config.py
DBS = $(shell .env/bin/python $(CREADER) sections $(CURPATH)/databases.yml)
TODAY = $(shell date +'%Y_%m_%d')

ifndef FOLDER
FOLDER = pg_dump
endif

ifndef NDAYS
NDAYS = 10
endif

all: prepare $(DBS)
	tar -c tmp/ > ./$(FOLDER)/$(TODAY).tar
	rm -rf ./tmp
	find ./$(FOLDER) -mtime +$(NDAYS) -delete
	lftp -e 'mirror -c -R ./$(FOLDER) test_dump/$(FOLDER); bye;' ftp://u146710:3ojBx2zbPcWCj3tw@u146710.your-storagebox.de
.env:
	virtualenv -p python3 .env
prepare: .env
	.env/bin/pip install -r requirements.txt
	mkdir -p ./$(FOLDER)
$(DBS): % : dir_%
	psql -d $@ -f get_backup_tables.sql
	for i in $(shell psql -d $@ -c "SELECT * FROM backup.get_tables()" -t); do \
		psql -d $@ -c "SELECT backup.save_state('$$i')"; \
		pg_dump -Fc -t $$i -d $@ -f tmp/dir_$@/$$i.dump; \
		done
dir_%:
	mkdir -p tmp/$@

