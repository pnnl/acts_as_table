module ActsAsTable
  # ActsAsTable foreign key (value provider).
  #
  # @!attribute [rw] default_value
  #   Returns the default value for this ActsAsTable foreign key.
  #
  #   @return [String, nil]
  # @!attribute [rw] method_name
  #   Returns the method name for this ActsAsTable foreign key (a `:belongs_to` association).
  #
  #   @return [String]
  # @!attribute [rw] polymorphic
  #   Returns 'true' if this ActsAsTable foreign key is polymorphic. Otherwise, returns `false`. By default, this is `false`.
  #
  #   @return [Boolean]
  # @!attribute [rw] primary_key
  #   Returns the name of the method that returns the primary key used for the association. By default, this is `id`.
  #
  #   @return [String]
  class ForeignKey < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProvider::InstanceMethods
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.foreign_keys_table

    acts_as_table_value_provider

    # Returns the ActsAsTable column model for this ActsAsTable foreign key or `nil`.
    #
    # @return [ActsAsTable::ColumnModel, nil]
    belongs_to :column_model, **{
      class_name: 'ActsAsTable::ColumnModel',
      inverse_of: :foreign_keys,
      required: false,
    }

    # Returns the ActsAsTable record model for this ActsAsTable foreign key.
    belongs_to :record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :foreign_keys,
      required: true,
    }

    # Returns the maps for this ActsAsTable foreign key.
    has_many :foreign_key_maps, -> { order(position: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::ForeignKeyMap',
      dependent: :destroy,
      foreign_key: 'foreign_key_id',
      inverse_of: :foreign_key,
      validate: true,
    }

    # Returns the ActsAsTable values that have been provided by this ActsAsTable foreign key.
    has_many :values, **{
      as: :value_provider,
      class_name: 'ActsAsTable::Value',
      dependent: :restrict_with_exception,
      foreign_key: 'value_provider_id',
      foreign_type: 'value_provider_type',
      inverse_of: :value_provider,
    }

    accepts_nested_attributes_for :foreign_key_maps, **{
      allow_destroy: true,
    }

    validates :default_value, **{
      presence: {
        unless: :column_model,
      },
    }

    validates :method_name, **{
      presence: true,
    }

    # validates :polymorphic, **{}

    validates :primary_key, **{
      presence: true,
    }

    validate :method_name_must_be_belongs_to_association, **{
      if: ::Proc.new { |foreign_key| foreign_key.method_name.present? },
    }

    # @return [Regexp]
    CAPTURE_GROUP_INDEX_REGEXP = ::Regexp.new("#{Regexp.quote('\\')}(0|[1-9][0-9]*)").freeze

    # @return [String]
    POLYMORPHIC_SEPARATOR = ':'.freeze

    protected

    # @param [ActiveRecord::Base, nil] base
    # @return [Object, nil]
    def _get_value(base = nil)
      if base.nil?
        nil
      else
        base.send(:"#{self.method_name}").try { |record|
          record.try(:"#{self.primary_key}").try { |record_id|
            if self.polymorphic?
              record_class_name = record.class.name
              record_table_name = ActsAsTable.adapter.tableize_for(self, record.class.name)

              if record_table_name.nil? || (record_table_name.is_a?(::String) && record_table_name.include?(POLYMORPHIC_SEPARATOR))
                raise "invalid record table name - #{record_table_name.inspect}"
              end

              [record_table_name, record_id].join(POLYMORPHIC_SEPARATOR)
            else
              record_id
            end
          }
        }
      end
    end

    # @param [Object, nil] new_value
    # @return [Object, nil]
    def _modify_set_value_before_default(new_value = nil)
      if new_value.nil?
        new_value
      elsif self.polymorphic?
        # @return [Array<String>]
        array = new_value.split(POLYMORPHIC_SEPARATOR)

        # @return [String]
        record_table_name = array[0]

        # @return [String]
        record_id = array[1..-1].join(POLYMORPHIC_SEPARATOR)

        self.foreign_key_maps.each do |foreign_key_map|
          # @return [Regexp]
          source_value_as_regexp = foreign_key_map.source_value_as_regexp

          unless (md = source_value_as_regexp.match(record_id)).nil?
            return foreign_key_map.target_value.gsub(CAPTURE_GROUP_INDEX_REGEXP) { |other_md|
              # @return [Integer]
              i = other_md[1].to_i

              [record_table_name, md[i]].join(POLYMORPHIC_SEPARATOR)
            }
          end
        end

        [record_table_name, record_id].join(POLYMORPHIC_SEPARATOR)
      else
        self.foreign_key_maps.each do |foreign_key_map|
          # @return [Regexp]
          source_value_as_regexp = foreign_key_map.source_value_as_regexp

          unless (md = source_value_as_regexp.match(new_value)).nil?
            return foreign_key_map.target_value.gsub(CAPTURE_GROUP_INDEX_REGEXP) { |other_md|
              # @return [Integer]
              i = other_md[1].to_i

              md[i]
            }
          end
        end

        new_value
      end
    end

    # @param [ActiveRecord::Base, nil] base
    # @param [Object, nil] new_value
    # @return [Array<Object>]
    def _set_value(base = nil, new_value = nil)
      if base.nil?
        [
          nil,
          false,
        ]
      elsif self.polymorphic?
        # @return [Object, nil]
        orig_value = _get_value(base)

        # @return [Class]
        klass = self.record_model.class_name.constantize

        # @return [ActiveRecord::Reflection::MacroAssociation]
        reflection = klass.reflect_on_association(self.method_name)

        unless reflection.polymorphic?
          raise "invalid reflection (monomorphic) - #{reflection.inspect}"
        end

        # @return [Array<String>]
        array = new_value.split(POLYMORPHIC_SEPARATOR)

        # @return [String]
        record_table_name = array[0]

        # @return [String]
        record_id = array[1..-1].join(POLYMORPHIC_SEPARATOR)

        # @return [String]
        record_class_name = ActsAsTable.adapter.classify_for(self, record_table_name)

        # @return [ActiveRecord::Base, nil]
        new_target_record = record_class_name.try(:constantize).try(:"find_by_#{self.primary_key}", record_id)

        # @return [Boolean]
        changed = !self.column_model.nil? && !(orig_value.nil? ? new_target_record.nil? : (new_target_record.nil? ? false : (orig_value == new_target_record.send(self.primary_key))))

        [
          new_target_record.try { |record| [record_table_name, base.send(:"#{self.method_name}=", record).try(self.primary_key)].join(POLYMORPHIC_SEPARATOR) },
          changed,
        ]
      else
        # @return [Object, nil]
        orig_value = _get_value(base)

        # @return [Class]
        klass = self.record_model.class_name.constantize

        # @return [ActiveRecord::Reflection::MacroAssociation]
        reflection = klass.reflect_on_association(self.method_name)

        # @return [ActiveRecord::Base, nil]
        new_target_record = reflection.klass.send(:"find_by_#{self.primary_key}", new_value)

        # @return [Boolean]
        changed = !self.column_model.nil? && !(orig_value.nil? ? new_target_record.nil? : (new_target_record.nil? ? false : (orig_value == new_target_record.send(self.primary_key))))

        [
          base.send(:"#{self.method_name}=", new_target_record).try(self.primary_key),
          changed,
        ]
      end
    end

    private

    # @param [Class] klass
    # @param [String] column_name
    # @return [Boolean]
    def _column?(klass, column_name)
      klass.column_names.include?(column_name.to_s)
    end

    # @return [void]
    def method_name_must_be_belongs_to_association
      self.record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |klass|
        # @return [ActiveRecord::Reflection::MacroReflection]
        reflection = klass.reflect_on_association(self.method_name)

        if reflection.nil?
          self.errors.add('method_name', :required)
        elsif reflection.macro == :belongs_to
          if self.polymorphic?
            unless reflection.polymorphic?
              self.errors.add('method_name', :invalid)
            end

            unless self.primary_key.eql?('id')
              self.errors.add('primary_key', :invalid)
            end
          else
            if reflection.polymorphic?
              self.errors.add('method_name', :invalid)
            end

            self.primary_key.try { |primary_key|
              if _column?(reflection.klass, primary_key)
                self.default_value.try { |default_value|
                  unless reflection.klass.exists?({ primary_key => default_value, })
                    self.errors.add('default_value', :required)
                  end
                }

                self.foreign_key_maps.each do |foreign_key_map|
                  foreign_key_map.target_value.try { |target_value|
                    unless reflection.klass.exists?({ primary_key => target_value, })
                      foreign_key_map.errors.add('target_value', :required)
                    end
                  }
                end
              else
                self.errors.add('primary_key', :required)
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
