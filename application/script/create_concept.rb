#
# Usage: sudo script/runner -e <ENV> script/reset_views.rb --complete  
# (needs sudo to write to log files)
# 
# Default ENV is development
# e.g.: script/runner -e production script/reset_views.rb 
#       script/runner script/reset_views.rb


  def sql
    date_created = Time.now().strftime('%Y-%m-%d %H:%M:%S')
    concept_id = 7007
    concept_name_id = 9730
    concept_ans = []
    set = []
    concept_set_sql = ''
    ['TB NOT SUSPECTED', 'TB SUSPECTED','CONFIRMED TB NOT ON TREATMENT', 'CONFIRMED TB ON TREATMENT','TB STATUS'].each{|concept_name|

      case concept_name
        when "TB NOT SUSPECTED"
          short_name = "noSusp"
        when "TB SUSPECTED"
          short_name = "susp"
        when "CONFIRMED TB NOT ON TREATMENT"
          short_name = "noRx"
        when "CONFIRMED TB ON TREATMENT"
          short_name = "Rx"
      end

      !concept_id+=1
      !concept_name_id+=1

      puts concept_name_id

      if concept_name == "TB STATUS"
        uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
        concept_sql =<<EOF
INSERT INTO concept (concept_id,retired,datatype_id,class_id,is_set,creator,date_created,uuid)
VALUE(#{concept_id},0,4,7,1,1,'#{date_created}','#{uuid}');
EOF
        concept_set_id = 1357
        concept_ans.each{|ans|
          !concept_set_id+=1
          uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
          concept_set_sql =<<EOF
INSERT INTO concept_set (concept_set_id,concept_id,concept_set,creator,date_created,uuid)
VALUE(#{concept_set_id},#{concept_id},#{ans},1,'#{date_created}','#{uuid}');
EOF
        set << concept_set_sql
        }

        uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
        concept_set_sql =<<EOF
INSERT INTO concept_set (concept_set_id,concept_id,concept_set,creator,date_created,uuid)
VALUE(#{concept_set_id+=1},#{concept_id},#{ConceptName.find_by_name('UNKNOWN').concept_id},1,'#{date_created}','#{uuid}');

EOF
        set << concept_set_sql
      else
        uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
        concept_sql =<<EOF
INSERT INTO concept (concept_id,retired,short_name,datatype_id,class_id,is_set,creator,date_created,uuid)
VALUE(#{concept_id},0,'#{short_name}',5,4,0,1,'#{date_created}','#{uuid}');
EOF
      end

        uuid = ActiveRecord::Base.connection.select_one("SELECT UUID() as uuid")['uuid']
        concept_name_sql =<<EOF
INSERT INTO concept_name (concept_id,concept_name_id,name,creator,date_created,voided,uuid)
VALUE(#{concept_id},#{concept_name_id},'#{concept_name}',1,'#{date_created}',0,'#{uuid}');
EOF
      concept_ans << concept_id
   
    puts "add .........."
    `echo "#{concept_sql + concept_name_sql + set.to_s}" >> /home/ace/Desktop/sql.sql` unless concept_set_sql.blank?
    `echo "#{concept_sql + concept_name_sql}" >> /home/ace/Desktop/sql.sql` if concept_set_sql.blank?
    }
  end

  sql
