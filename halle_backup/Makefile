DBS = $(shell cat databases.yml)
all:  $(DBS)
$(DBS):
	@$(eval TABLES = $(shell python dbdump.py $@))
	@mkdir -p pg_dumps/$@
	@pg_dump -Fd -t $(TABLES) -d $@ -f pg_dumps/$@
clean:
	@rm -rf ./pg_dumps

