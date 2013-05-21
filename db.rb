namespace :db do
  desc "Snapshots production db and dumps into local development db"
  task :pull, roles: :db, only: { primary: true } do
    prod_config = capture "cat #{shared_path}/config/database.yml"

    prod = YAML::load(prod_config)["production"]
    dev  = YAML::load_file("./config/database.yml")["development"]
    dump = "/tmp/#{Time.now.to_i}-#{application}.psql"

    pg_dump = []
    pg_dump << "export PGPASSWORD=#{prod["password"]} &&" if prod["password"]
    pg_dump << "pg_dump -x -O -Fc"
    pg_dump << "-h #{prod["host"]}" if prod["host"]
    pg_dump << "-U #{prod["username"]}" if prod["username"]
    pg_dump << "#{prod["database"]} -f #{dump}"

    run pg_dump.join(" ")
    get dump, dump
    run "rm #{dump}"

    pg_restore = ["pg_restore -x -O"]
    pg_restore << "-U #{dev["username"]}" if dev["username"]
    pg_restore << "-h #{dev["host"]}" if dev["host"]
    pg_restore << "-d #{dev["database"]}"
    pg_restore << "#{dump}"
    system "rake db:kill_postgres_connections db:create"
    system pg_restore.join(" ")
    system "rm #{dump}"
  end
end