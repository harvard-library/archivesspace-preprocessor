class AlterRunForProcessingFromRuns < ActiveRecord::Migration[4.2]
  def up
    change_column_default :runs, :run_for_processing, false 
  end

  def down
    change_column_default :runs, :run_for_processing, nil
  end
end
