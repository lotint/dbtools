CURPATH = $(shell pwd)
CREADER = $(CURPATH)/read_config.py
DBS = $(shell python $(CREADER) sections $(CURPATH)/databases.yml)
all: $(DBS)
$(DBS): % : dir_%
	@for i in $(shell python dbdump.py $@); do \
		pg_dump -Fc -t $$i -d $@ -f pg_dumps/dir_$@/$$i.dump; \
		done
dir_%:
	@mkdir -p pg_dumps/$@
clean:
	@rm -rf ./pg_dumps
