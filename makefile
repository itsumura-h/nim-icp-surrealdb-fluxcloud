exec:
	docker compose start
	docker compose exec app bash

stop:
	docker compose stop

diff:
	git diff --cached > .diff

migrate:
	nim c -r migrate/migrate.nim

run:
	icp network stop || true
	rm -rf .icp
	icp network start -d
