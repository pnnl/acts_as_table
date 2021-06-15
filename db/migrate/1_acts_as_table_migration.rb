if ::ActiveRecord.gem_version >= ::Gem::Version.new('5.0')
  class ActsAsTableMigration < ::ActiveRecord::Migration[4.2]; end
else
  class ActsAsTableMigration < ::ActiveRecord::Migration; end
end

ActsAsTableMigration.class_eval do
  def self.up
    create_table ActsAsTable.row_models_table do |t|
      t.integer :root_record_model_id, index: true, null: false

      t.string :name, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.column_models_table do |t|
      t.references :row_model, index: true, foreign_key: { to_table: ActsAsTable.row_models_table }, null: true
      t.integer :position, index: true, null: false, default: 1

      t.string :name, null: false
      t.string :separator, null: false, default: ','

      t.timestamps null: false
    end

    create_table ActsAsTable.record_models_table do |t|
      t.references :row_model, index: true, foreign_key: { to_table: ActsAsTable.row_models_table }, null: false

      t.string :class_name, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.lenses_table do |t|
      t.references :record_model, index: true, foreign_key: { to_table: ActsAsTable.record_models_table }, null: false

      t.references :column_model, index: true, foreign_key: { to_table: ActsAsTable.column_models_table }

      t.string :method_name, null: false
      t.string :default_value

      t.timestamps null: false
    end

    create_table ActsAsTable.foreign_keys_table do |t|
      t.references :record_model, index: true, foreign_key: { to_table: ActsAsTable.record_models_table }, null: false

      t.references :column_model, index: true, foreign_key: { to_table: ActsAsTable.column_models_table }

      t.string :method_name, null: false
      t.string :primary_key, null: false, default: 'id'
      t.string :default_value
      t.boolean :polymorphic, null: false, default: false

      t.timestamps null: false
    end

    create_table ActsAsTable.foreign_key_maps_table do |t|
      t.references :foreign_key, index: true, foreign_key: { to_table: ActsAsTable.foreign_keys_table }, null: false
      t.integer :position, index: true, null: false, default: 1

      t.string :source_value, null: false
      t.string :target_value, null: false
      t.boolean :regexp, null: false, default: false
      t.boolean :ignore_case, null: false, default: false
      t.boolean :multiline, null: false, default: false
      t.boolean :extended, null: false, default: false

      t.timestamps null: false
    end

    create_table ActsAsTable.primary_keys_table do |t|
      t.references :record_model, index: true, foreign_key: { to_table: ActsAsTable.record_models_table }, null: false

      t.references :column_model, index: true, foreign_key: { to_table: ActsAsTable.column_models_table }

      t.string :method_name, null: false, default: 'id'

      t.timestamps null: false
    end

    create_table ActsAsTable.belongs_tos_table do |t|
      t.references :row_model, index: true, foreign_key: { to_table: ActsAsTable.row_models_table }, null: false

      t.integer :source_record_model_id, index: true, null: false
      t.integer :target_record_model_id, index: true, null: false

      t.string :macro, null: false, default: 'belongs_to'
      t.string :method_name, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.has_manies_table do |t|
      t.references :row_model, index: true, foreign_key: { to_table: ActsAsTable.row_models_table }, null: false

      t.integer :source_record_model_id, index: true, null: false

      t.string :macro, null: false, default: 'has_many'
      t.string :method_name, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.has_many_targets_table do |t|
      t.references :has_many, index: true, foreign_key: { to_table: ActsAsTable.has_manies_table }, null: false
      t.integer :position, index: true, null: false, default: 1

      t.references :record_model, index: true, foreign_key: { to_table: ActsAsTable.record_models_table }, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.tables_table do |t|
      t.references :row_model, index: true, foreign_key: { to_table: ActsAsTable.row_models_table }, null: false

      t.timestamps null: false

      t.integer :records_count, null: false, default: 0
    end

    create_table ActsAsTable.records_table do |t|
      t.references :table, index: true, foreign_key: { to_table: ActsAsTable.tables_table }, null: false
      t.references :record_model, index: true, foreign_key: { to_table: ActsAsTable.record_models_table }, null: false
      t.integer :position, index: true, null: false, default: 1

      t.references :base, polymorphic: true, index: true

      t.boolean :record_model_changed, null: false, default: false

      t.timestamps null: false

      t.integer :record_errors_count, null: false, default: 0
      t.integer :values_count, null: false, default: 0
    end

    create_table ActsAsTable.record_errors_table do |t|
      t.references :record, index: true, foreign_key: { to_table: ActsAsTable.records_table }, null: false

      t.references :value, index: true, foreign_key: { to_table: ActsAsTable.values_table }

      t.string :attribute_name, null: false
      t.string :message, null: false

      t.timestamps null: false
    end

    create_table ActsAsTable.values_table do |t|
      t.references :record, index: true, foreign_key: { to_table: ActsAsTable.records_table }, null: false
      t.references :value_provider, polymorphic: true, index: true, null: false

      t.references :column_model, index: true, foreign_key: { to_table: ActsAsTable.column_models_table }
      t.integer :position, index: true

      t.text :source_value
      t.text :target_value
      t.boolean :value_provider_changed, null: false, default: false

      t.timestamps null: false

      t.integer :record_errors_count, null: false, default: 0
    end

    add_foreign_key ActsAsTable.belongs_tos_table, ActsAsTable.record_models_table, column: 'source_record_model_id'
    add_foreign_key ActsAsTable.belongs_tos_table, ActsAsTable.record_models_table, column: 'target_record_model_id'
    add_foreign_key ActsAsTable.has_manies_table, ActsAsTable.record_models_table, column: 'source_record_model_id'
    add_foreign_key ActsAsTable.row_models_table, ActsAsTable.record_models_table, column: 'root_record_model_id'
  end

  def self.down
    drop_table ActsAsTable.belongs_tos_table
    drop_table ActsAsTable.column_models_table
    drop_table ActsAsTable.foreign_key_maps_table
    drop_table ActsAsTable.foreign_keys_table
    drop_table ActsAsTable.has_manies_table
    drop_table ActsAsTable.has_many_targets_table
    drop_table ActsAsTable.lenses_table
    drop_table ActsAsTable.primary_keys_table
    drop_table ActsAsTable.record_errors_table
    drop_table ActsAsTable.record_models_table
    drop_table ActsAsTable.records_table
    drop_table ActsAsTable.row_models_table
    drop_table ActsAsTable.tables_table
    drop_table ActsAsTable.values_table
  end
end
