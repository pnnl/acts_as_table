module ActsAsTable
  # ActsAsTable record model (value provider).
  #
  # @!attribute [rw] class_name
  #   Returns the ActiveRecord model class name for this ActsAsTable record model.
  #
  #   @return [String]
  class RecordModel < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProvider::InstanceMethods
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.record_models_table

    acts_as_table_value_provider

    # Returns the ActsAsTable row model for this ActsAsTable record model.
    belongs_to :row_model, **{
      class_name: 'ActsAsTable::RowModel',
      inverse_of: :record_models,
      required: true,
    }

    # Returns the ActsAsTable singular macro associations where this ActsAsTable record model is the source of the association.
    has_many :belongs_tos_as_source, **{
      autosave: true,
      class_name: 'ActsAsTable::BelongsTo',
      dependent: :destroy,
      foreign_key: 'source_record_model_id',
      inverse_of: :source_record_model,
      validate: true,
    }

    # Returns the ActsAsTable singular macro associations where this ActsAsTable record model is the target of the association.
    has_many :belongs_tos_as_target, **{
      autosave: true,
      class_name: 'ActsAsTable::BelongsTo',
      dependent: :destroy,
      foreign_key: 'target_record_model_id',
      inverse_of: :target_record_model,
      validate: true,
    }

    # Returns the ActsAsTable foreign keys for this ActsAsTable record model.
    has_many :foreign_keys, **{
      autosave: true,
      class_name: 'ActsAsTable::ForeignKey',
      dependent: :destroy,
      foreign_key: 'record_model_id',
      inverse_of: :record_model,
      validate: true,
    }

    # Returns the ActsAsTable collection macro associations where this ActsAsTable record model is the source of the association.
    has_many :has_manies_as_source, **{
      autosave: true,
      class_name: 'ActsAsTable::HasMany',
      dependent: :destroy,
      foreign_key: 'source_record_model_id',
      inverse_of: :source_record_model,
      validate: true,
    }

    # Returns the ActsAsTable collection macro associations where this ActsAsTable record model is the target of the association.
    has_many :has_manies_as_target, -> { readonly }, **{
      source: :has_many,
      through: :has_many_targets,
    }

    # Returns the ActsAsTable collection macro association targets for this ActsAsTable record model.
    has_many :has_many_targets, **{
      autosave: true,
      class_name: 'ActsAsTable::HasManyTarget',
      dependent: :destroy,
      foreign_key: 'record_model_id',
      inverse_of: :record_model,
      validate: true,
    }

    # Returns the ActsAsTable attribute accessors for this ActsAsTable record model.
    has_many :lenses, **{
      autosave: true,
      class_name: 'ActsAsTable::Lense',
      dependent: :destroy,
      foreign_key: 'record_model_id',
      inverse_of: :record_model,
      validate: true,
    }

    # Returns the ActsAsTable primary keys for this ActsAsTable record model.
    has_many :primary_keys, **{
      autosave: true,
      class_name: 'ActsAsTable::PrimaryKey',
      dependent: :destroy,
      foreign_key: 'record_model_id',
      inverse_of: :record_model,
      validate: true,
    }

    # Returns the ActsAsTable records that have been provided by this ActsAsTable record model.
    has_many :records, **{
      class_name: 'ActsAsTable::Record',
      dependent: :restrict_with_exception,
      foreign_key: 'record_model_id',
      inverse_of: :record_model,
    }

    # Returns the ActsAsTable row models where this ActsAsTable record model is the root.
    has_many :row_models_as_root, **{
      class_name: 'ActsAsTable::RowModel',
      dependent: :restrict_with_exception,
      foreign_key: 'root_record_model_id',
      inverse_of: :root_record_model,
    }

    validates :class_name, **{
      presence: true,
    }

    validate :base_must_be_reachable

    validate :class_name_must_constantize, **{
      if: ::Proc.new { |record_model| record_model.class_name.present? },
    }

    # Get the value for the given record using the given options.
    #
    # @param [ActiveRecord::Base, nil] base
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    def get_value(base = nil, **options)
      unless base.nil? || self.class_name.eql?(base.class.name)
        raise ::ArgumentError.new("record - invalid class - expected: #{self.class_name.inspect}, found: #{base.inspect}")
      end

      # @return [Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>]
      value_by_value_provider = self.each_acts_as_table_value_provider(nil, except: [:row_model, :row_models_as_root]).inject({}) { |acc, value_provider|
        acc[value_provider] ||= base.nil? ? ActsAsTable.adapter.wrap_value_for(value_provider, base, nil, nil) : ActsAsTable.adapter.get_value_for(value_provider, base, **options)
        acc
      }

      ActsAsTable.adapter.wrap_value_for(self, base, nil, value_by_value_provider)
    end

    # Set the new value for the given record using the given options.
    #
    # @param [ActiveRecord::Base, nil] base
    # @param [Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>] new_value_by_value_provider
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    def set_value(base = nil, new_value_by_value_provider = {}, **options)
      unless base.nil? || self.class_name.eql?(base.class.name)
        raise ::ArgumentError.new("record - invalid class - expected: #{self.class_name.inspect}, found: #{base.inspect}")
      end

      # @return [Array<Object>]
      value_by_value_provider, changed = *self.each_acts_as_table_value_provider(nil, except: [:row_model, :row_models_as_root]).inject([{}, false]) { |acc, value_provider|
        # @return [Object, nil]
        new_value = new_value_by_value_provider.try(:[], value_provider)

        acc[0][value_provider] ||= base.nil? ? ActsAsTable.adapter.wrap_value_for(value_provider, base, nil, nil) : ActsAsTable.adapter.set_value_for(value_provider, base, new_value, **options)
        acc[1] ||= acc[0][value_provider].changed?
        acc
      }

      ActsAsTable.adapter.wrap_value_for(self, base, nil, value_by_value_provider, changed: changed)
    end

    private

    # @return [void]
    def base_must_be_reachable
      if self.row_model.try(:reachable_record_model?, self) == false
        self.errors.add(:base, :unreachable)
      end

      return
    end

    # @return [void]
    def class_name_must_constantize
      begin
        self.class_name.constantize
      rescue ::NameError
        self.errors.add('class_name', :invalid)
      end

      return
    end
  end
end
