class AddContextInfoToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :name, :string, index: true, unique: false
    add_column :runs, :data, :jsonb

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.connection.execute(<<-SQL)
          UPDATE runs SET name = created_at::date::varchar
        SQL

        change_column :runs, :name, :string, null: false
      end
      dir.down do |dir|
        # Nothing to do, column getting dropped anyway.
      end
    end

  end
end
