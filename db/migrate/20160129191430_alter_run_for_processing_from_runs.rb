class AlterRunForProcessingFromRuns < ActiveRecord::Migration
  def up
    change_column_default :runs, :run_for_processing, false 
  end

  def down
    change_column_default :runs, :run_for_processing, nil
  end
end
