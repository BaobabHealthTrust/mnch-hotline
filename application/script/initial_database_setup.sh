#!/bin/bash

usage(){
  echo "Usage: $0 ENVIRONMENT SITE"
  echo
  echo "ENVIRONMENT should be: development|test|production"
  echo "Available SITES:"
  ls -1 db/data
} 

ENV=$1
SITE=$2

if [ -z "$ENV" ] || [ -z "$SITE" ] ; then
  usage
  exit
fi

set -x # turns on stacktrace mode which gives useful debug information

if [ ! -x config/database.yml ] ; then
  cp config/database.yml.example config/database.yml
fi

USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['database']"`

echo "DROP DATABASE $DATABASE;" | mysql --user=$USERNAME --password=$PASSWORD
echo "CREATE DATABASE $DATABASE;" | mysql --user=$USERNAME --password=$PASSWORD

#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/schema.sql
#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/openmrs_metadata.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/openmrs_1_5_2_concept_server_full_db.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/schema_bart2_additions.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/defaults.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/drug_ingredient.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/pharmacy.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/drop_patient_start_date_function.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/create_patient_start_date_function.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/data/${SITE}/${SITE}.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/data/${SITE}/tasks.sql


#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/alter_global_property.sql
#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/create_sessions.sql
#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/create_weight_for_heights.sql
#mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/create_weight_height_for_ages.sql

#rake openmrs:bootstrap:load:defaults RAILS_ENV=$ENV
#rake openmrs:bootstrap:load:site SITE=$SITE RAILS_ENV=production#

echo "After completing database setup, you are advised to run the following:"
echo "rake test"
echo "rake cucumber"
