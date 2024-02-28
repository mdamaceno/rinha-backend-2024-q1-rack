max_threads_count = ENV.fetch("APP_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("APP_MIN_THREADS") { max_threads_count }

threads min_threads_count, max_threads_count

port 3000
environment "production"
worker_timeout 30000
