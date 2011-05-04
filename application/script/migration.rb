
  def migrate
    User.current_user = User.find(1)
    migration = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['migration']
    PatAddress.establish_connection(migration)
    PatName.establish_connection(migration)
    PatIdentifier.establish_connection(migration)
    PatIdentifierType.establish_connection(migration)
    Pat.establish_connection(migration)
    Orders.establish_connection(migration)
    DrugOrders.establish_connection(migration)
    Enc.establish_connection(migration)
    EncType.establish_connection(migration)
    Obs.establish_connection(migration)
    Relationships.establish_connection(migration)
    Users.establish_connection(migration) 
    Locations.establish_connection(migration) 

    DataMigration.create_users
    DataMigration.create_locations
    DataMigration.migrate_data
  end
  User.current_user = User.find(1)
  migrate

