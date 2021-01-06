module ActsAsTable
  # ActsAsTable column model.
  #
  # @!attribute [rw] name
  #   Returns the name for this ActsAsTable column model.
  #
  #   @return [String]
  # @!attribute [rw] position
  #   Returns the position of this ActsAsTable column model.
  #
  #   @return [Integer]
  # @!attribute [rw] separator
  #   Returns the separator for the name of this ActsAsTable column model. By default, this is `,`.
  #
  #   @return [String]
  class ColumnModel < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.column_models_table

    # Returns the ActsAsTable row model for this ActsAsTable column model.
    belongs_to :row_model, **{
      class_name: 'ActsAsTable::RowModel',
      inverse_of: :column_models,
      required: true,
    }

    # Returns the ActsAsTable foreign keys for this ActsAsTable column model.
    has_many :foreign_keys, **{
      autosave: true,
      class_name: 'ActsAsTable::ForeignKey',
      dependent: :nullify,
      foreign_key: 'column_model_id',
      inverse_of: :column_model,
      validate: true,
    }

    # Returns the ActsAsTable attribute accessors for this ActsAsTable column model.
    has_many :lenses, **{
      autosave: true,
      class_name: 'ActsAsTable::Lense',
      dependent: :nullify,
      foreign_key: 'column_model_id',
      inverse_of: :column_model,
      validate: true,
    }

    # Returns the ActsAsTable primary keys for this ActsAsTable column model.
    has_many :primary_keys, **{
      autosave: true,
      class_name: 'ActsAsTable::PrimaryKey',
      dependent: :nullify,
      foreign_key: 'column_model_id',
      inverse_of: :column_model,
      validate: true,
    }

    # Returns the ActsAsTable values that have been provided by this ActsAsTable column model.
    has_many :values, **{
      class_name: 'ActsAsTable::Value',
      dependent: :restrict_with_exception,
      foreign_key: 'column_model_id',
      inverse_of: :column_model,
    }

    validates :name, **{
      presence: true,
    }

    validates :position, **{
      numericality: {
        greater_than_or_equal_to: 1,
        only_integer: true,
      },
      presence: true,
      uniqueness: {
        scope: ['row_model_id'],
      },
    }

    validates :separator, **{
      length: {
        minimum: 1,
      },
    }
  end
end
