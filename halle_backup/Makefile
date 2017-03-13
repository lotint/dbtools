DBS = $(shell cat databases.yml)
all: $(DBS)
$(DBS): % : dir_%
	@$(shell make DB=$@ -f Makefile_t)
dir_%:
	@mkdir -p pg_dumps/$@
clean:
	@rm -rf ./pg_dumps
