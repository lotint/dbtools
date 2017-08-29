
.DEFAULT_GOAL := all

EXTENSION = pg_address
EXTVERSION   = $(shell grep default_version $(EXTENSION).control | sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")

DATA = sql/$(EXTENSION)--$(EXTVERSION).sql sql/$(EXTENSION)--0.0.2--0.0.3.sql
EXTRA_CLEAN = sql/$(EXTENSION)--$(EXTVERSION).sql


TEST_DATABASE = dbtools_test
TEST_PORT = 5432


all: sql/$(EXTENSION)--$(EXTVERSION).sql


test:
	pg_prove -p $(TEST_PORT) -d $(TEST_DATABASE) tests/smoke.sql


sql/$(EXTENSION)--$(EXTVERSION).sql: sql/$(EXTENSION).sql
	cat $< > $@


PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
