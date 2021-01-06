module ActsAsTable
  # ActsAsTable collection macro association target.
  #
  # @!attribute [rw] position
  #   Returns the position of this ActsAsTable collection macro association target.
  #
  #   @return [Integer]
  class HasManyTarget < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.has_many_targets_table

    # Returns the ActsAsTable collection macro association for this target.
    belongs_to :has_many, **{
      class_name: 'ActsAsTable::HasMany',
      inverse_of: :has_many_targets,
      required: true,
    }

    # Returns the ActsAsTable record model for this ActsAsTable collection macro association target.
    belongs_to :record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :has_many_targets,
      required: true,
    }

    validates :position, **{
      numericality: {
        greater_than_or_equal_to: 1,
        only_integer: true,
      },
      presence: true,
      uniqueness: {
        scope: ['has_many_id'],
      },
    }
  end
end
