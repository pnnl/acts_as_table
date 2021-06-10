module ActsAsTable
  # ActsAsTable value.
  #
  # @!attribute [rw] position
  #   Returns the position of this ActsAsTable value or `nil`.
  #
  #   @return [Integer, nil]
  # @!attribute [r] record_errors_count
  #   Returns the number of ActsAsTable record errors for this ActsAsTable value.
  #
  #   @return [Integer]
  # @!attribute [rw] source_value
  #   Returns the source value for this ActsAsTable value.
  #
  #   @return [String, nil]
  # @!attribute [rw] target_value
  #   Returns the target value for this ActsAsTable value.
  #
  #   @return [String, nil]
  # @!attribute [rw] value_provider_changed
  #   Returns `true` if the ActsAsTable value provider changed the value for this ActsAsTable value. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  class Value < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.values_table

    # Returns the ActsAsTable column model that provided this ActsAsTable value or `nil`.
    #
    # @return [ActsAsTable::ColumnModel, nil]
    belongs_to :column_model, **{
      class_name: 'ActsAsTable::ColumnModel',
      inverse_of: :values,
      required: false,
    }

    # Returns the ActsAsTable record for this ActsAsTable value.
    belongs_to :record, **{
      class_name: 'ActsAsTable::Record',
      counter_cache: 'values_count',
      inverse_of: :values,
      required: true,
    }

    # Returns the ActsAsTable value provider that provider the value for this ActsAsTable value.
    #
    # @return [ActsAsTable::ValueProvider::InstanceMethods]
    belongs_to :value_provider, **{
      polymorphic: true,
      required: true,
    }

    # Returns the ActsAsTable record errors for this ActsAsTable value.
    has_many :record_errors, -> { order(attribute_name: :asc, message: :asc) }, **{
      autosave: false,
      class_name: 'ActsAsTable::RecordError',
      dependent: :nullify,
      foreign_key: 'value_id',
      inverse_of: :value,
      validate: false,
    }

    validates :record_id, **{
      uniqueness: {
        scope: ['value_provider_id', 'value_provider_type'],
      },
    }

    # validates :position, **{}

    # validates :source_value, **{}

    # validates :target_value, **{}

    # validates :value_provider_changed, **{}
  end
end
