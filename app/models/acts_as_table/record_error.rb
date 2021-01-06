module ActsAsTable
  # ActsAsTable record error.
  #
  # @!attribute [rw] attribute_name
  #   Returns the attribute name for this ActsAsTable record error.
  #
  #   @note The attribute name for model-level errors is "base".
  #
  #   @return [String]
  # @!attribute [rw] message
  #   Returns the message for this ActsAsTable record error.
  #
  #   @return [String]
  class RecordError < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.record_errors_table

    # Returns the ActsAsTable record for this error.
    belongs_to :record, **{
      class_name: 'ActsAsTable::Record',
      counter_cache: 'record_errors_count',
      inverse_of: :record_errors,
      required: true,
    }

    # Returns the ActsAsTable value for this error or `nil`.
    #
    # @return [ActsAsTable::Value, nil]
    belongs_to :value, **{
      class_name: 'ActsAsTable::Value',
      counter_cache: 'record_errors_count',
      inverse_of: :record_errors,
      required: false,
    }

    validates :attribute_name, **{
      presence: true,
    }

    validates :message, **{
      presence: true,
      uniqueness: {
        scope: ['record_id', 'attribute_name'],
      },
    }
  end
end
