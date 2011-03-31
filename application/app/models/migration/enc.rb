class Enc < OpenMRS
  set_table_name "encounter"

  def name
    EncType.find(:first,:conditions => ['encounter_type_id = ?',self.encounter_type]).name rescue nil
  end

  def observations
    Obs.find(:all,:conditions => ["encounter_id = ?",self.encounter_id])
  end

end
