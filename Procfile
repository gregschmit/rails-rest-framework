# For development environment only.
rails: bin/rails server -p 3000 --no-log-to-stdout
worker: bin/rails solid_queue:start
log: tail -f test/log/development.log
