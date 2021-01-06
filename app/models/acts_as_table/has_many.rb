module ActsAsTable
  # ActsAsTable collection macro association.
  #
  # @!attribute [rw] macro
  #   Returns the symbolic name for the macro for this ActsAsTable collection macro association.
  #
  #   @note The macro must be either `:has_many` or `:has_and_belongs_to_many`.
  #
  #   @return [String]
  # @!attribute [rw] method_name
  #   Returns the method name for this ActsAsTable collection macro association.
  #
  #   @return [String]
  class HasMany < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.has_manies_table

    # Returns the ActsAsTable row model for this ActsAsTable collection macro association.
    belongs_to :row_model, **{
      class_name: 'ActsAsTable::RowModel',
      inverse_of: :has_manies,
      required: true,
    }

    # Returns the source ActsAsTable record model for this ActsAsTable collection macro association.
    belongs_to :source_record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :has_manies_as_source,
      required: true,
    }

    # Returns the targets for this ActsAsTable collection macro association.
    has_many :has_many_targets, -> { order(position: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::HasManyTarget',
      dependent: :destroy,
      foreign_key: 'has_many_id',
      inverse_of: :has_many,
      validate: true,
    }

    accepts_nested_attributes_for :has_many_targets, **{
      allow_destroy: true,
    }

    validates :macro, **{
      inclusion: {
        in: ['has_many', 'has_and_belongs_to_many'],
      },
      presence: true,
    }

    validates :method_name, **{
      presence: true,
    }

    validate :macro_and_method_name_must_be_valid_association, **{
      if: ::Proc.new { |has_many| has_many.macro.present? && has_many.method_name.present? },
    }

    private

    # @return [void]
    def macro_and_method_name_must_be_valid_association
      self.source_record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |source_klass|
        # @return [ActiveRecord::Reflection::MacroReflection]
        reflection = source_klass.reflect_on_association(self.method_name)

        if reflection.nil?
          self.errors.add('method_name', :required)
        elsif self.macro.eql?(reflection.macro.to_s)
          self.has_many_targets.each do |has_many_target|
            has_many_target.record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |target_klass|
              unless reflection.klass == target_klass
                has_many_target.errors.add('record_model_id', :invalid)
              end
            }
          end
        else
          self.errors.add('method_name', :invalid)
        end
      }

      return
    end
  end
end
