module ActsAsTable
  # ActsAsTable mapper.
  module Mapper
    # ActsAsTable mapper object (abstract).
    class Base
      # Returns a new ActsAsTable mapper object.
      #
      # @yieldparam [ActsAsTable::Mapper::Base] base
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::Base]
      def initialize(&block)
        if block_given?
          case block.arity
            when 1 then block.call(self)
            else self.instance_eval(&block)
          end
        end
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::BelongsTo} class for the `:belongs_to` macro.
    class BelongsTo < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::BelongsTo} class for the `:belongs_to` macro.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [ActsAsTable::Mapper::RecordModel] target
      # @yieldparam [ActsAsTable::Mapper::BelongsTo] belongs_to
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::BelongsTo]
      def initialize(row_model, column_model_by_key, record_model, method_name, target, &block)
        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @row_model.belongs_tos.build(macro: 'belongs_to', method_name: method_name) do |belongs_to|
          belongs_to.source_record_model = @record_model

          belongs_to.target_record_model = target.send(:instance_variable_get, :@record_model)
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::ForeignKey} class.
    class ForeignKey < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::ForeignKey} class.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [Integer, Symbol, nil] position_or_key
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @option options [#to_s] :primary_key
      # @yieldparam [ActsAsTable::Mapper::ForeignKey] foreign_key
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::ForeignKey]
      def initialize(row_model, column_model_by_key, record_model, method_name, position_or_key = nil, **options, &block)
        options.assert_valid_keys(:default, :primary_key)

        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @foreign_key = @record_model.foreign_keys.build(method_name: method_name, primary_key: options[:primary_key] || 'id', default_value: options[:default]) do |foreign_key|
          unless position_or_key.nil?
            foreign_key.column_model = position_or_key.is_a?(::Symbol) ? @column_model_by_key[position_or_key] : @row_model.column_models[position_or_key - 1]
          end
        end

        super(&block)
      end

      # Builds a new instance of the {ActsAsTable::ForeignKeyMap} class.
      #
      # @note Target values for regular expressions may refer to capture groups.
      #
      # @param [String, Regexp] from
      # @param [Hash<Symbol, Object>] options
      # @option options [String] to
      # @return [ActsAsTable::Mapper::ForeignKey]
      #
      # @example Map from a string to another string.
      #   map 'source', to: 'target'
      #
      # @example Map from a regular expression to a capture group.
      #   map /City:\s+(.+)/i, to: '\1'
      #
      def map(from, **options)
        options.assert_valid_keys(:to)

        @foreign_key.foreign_key_maps.build({
          source_value: from.is_a?(::Regexp) ? from.source : from.to_s,
          target_value: options[:to].to_s,
          regexp: from.is_a?(::Regexp),
          extended: from.is_a?(::Regexp) && ((from.options & ::Regexp::EXTENDED) != 0),
          ignore_case: from.is_a?(::Regexp) && ((from.options & ::Regexp::IGNORECASE) != 0),
          multiline: from.is_a?(::Regexp) && ((from.options & ::Regexp::MULTILINE) != 0),
        })

        self
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::HasMany} class for the `:has_and_belongs_to_many` macro.
    class HasAndBelongsToMany < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::HasMany} class for the `:has_and_belongs_to_many` macro.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [Array<ActsAsTable::Mapper::RecordModel>] targets
      # @yieldparam [ActsAsTable::Mapper::HasAndBelongsToMany] has_and_belongs_to_many
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::HasAndBelongsToMany]
      def initialize(row_model, column_model_by_key, record_model, method_name, *targets, &block)
        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @row_model.has_manies.build(macro: 'has_and_belongs_to_many', method_name: method_name) do |has_many|
          has_many.source_record_model = @record_model

          targets.each_with_index do |target, index|
            has_many.has_many_targets.build(position: index + 1) do |has_many_target|
              has_many_target.record_model = target.send(:instance_variable_get, :@record_model)
            end
          end
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::HasMany} class for the `:has_many` macro.
    class HasMany < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::HasMany} class for the `:has_many` macro.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [Array<ActsAsTable::Mapper::RecordModel>] targets
      # @yieldparam [ActsAsTable::Mapper::HasMany] has_many
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::HasMany]
      def initialize(row_model, column_model_by_key, record_model, method_name, *targets, &block)
        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @row_model.has_manies.build(macro: 'has_many', method_name: method_name) do |has_many|
          has_many.source_record_model = @record_model

          targets.each_with_index do |target, index|
            has_many.has_many_targets.build(position: index + 1) do |has_many_target|
              has_many_target.record_model = target.send(:instance_variable_get, :@record_model)
            end
          end
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::BelongsTo} class for the `:has_one` macro.
    class HasOne < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::BelongsTo} class for the `:has_one` macro.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [ActsAsTable::Mapper::RecordModel] target
      # @yieldparam [ActsAsTable::Mapper::HasOne] has_one
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::HasOne]
      def initialize(row_model, column_model_by_key, record_model, method_name, target, &block)
        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @row_model.belongs_tos.build(macro: 'has_one', method_name: method_name) do |belongs_to|
          belongs_to.source_record_model = @record_model

          belongs_to.target_record_model = target.send(:instance_variable_get, :@record_model)
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::Lense} class.
    class Lense < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::Lense} class.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [#to_s] method_name
      # @param [Integer, Symbol, nil] position_or_key
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @option options [#to_s] :primary_key
      # @yieldparam [ActsAsTable::Mapper::Lense] lense
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::Lense]
      def initialize(row_model, column_model_by_key, record_model, method_name, position_or_key = nil, **options, &block)
        options.assert_valid_keys(:default)

        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @record_model.lenses.build(method_name: method_name, default_value: options[:default]) do |lens|
          unless position_or_key.nil?
            lens.column_model = position_or_key.is_a?(::Symbol) ? @column_model_by_key[position_or_key] : @row_model.column_models[position_or_key - 1]
          end
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::PrimaryKey} class.
    class PrimaryKey < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::PrimaryKey} class.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [ActsAsTable::RecordModel] record_model
      # @param [Integer, Symbol, nil] position_or_key
      # @param [#to_s] method_name
      # @yieldparam [ActsAsTable::Mapper::PrimaryKey] primary_key
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::PrimaryKey]
      def initialize(row_model, column_model_by_key, record_model, position_or_key, method_name = 'id', &block)
        @row_model, @column_model_by_key, @record_model = row_model, column_model_by_key, record_model

        @record_model.primary_keys.build(method_name: method_name) do |primary_key|
          primary_key.column_model = position_or_key.is_a?(::Symbol) ? @column_model_by_key[position_or_key] : @row_model.column_models[position_or_key - 1]
        end

        super(&block)
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::RecordModel} class.
    #
    # @!method attribute(method_name, position_or_key = nil, **options, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::Lense} class.
    #
    #   @param [#to_s] method_name
    #   @param [Integer, Symbol, nil] position_or_key
    #   @param [Hash<Symbol, Object>] options
    #   @option options [Boolean] :default
    #   @option options [#to_s] :primary_key
    #   @yieldparam [ActsAsTable::Mapper::Lense] lense
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::Lense]
    # @!method belongs_to(method_name, target, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::BelongsTo} class for the `:belongs_to` macro.
    #
    #   @param [#to_s] method_name
    #   @param [ActsAsTable::Mapper::RecordModel] target
    #   @yieldparam [ActsAsTable::Mapper::BelongsTo] belongs_to
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::BelongsTo]
    # @!method foreign_key(method_name, position_or_key = nil, **options, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::ForeignKey} class.
    #
    #   @param [#to_s] method_name
    #   @param [Integer, Symbol, nil] position_or_key
    #   @param [Hash<Symbol, Object>] options
    #   @option options [Boolean] :default
    #   @option options [#to_s] :primary_key
    #   @yieldparam [ActsAsTable::Mapper::ForeignKey] foreign_key
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::ForeignKey]
    # @!method has_and_belongs_to_many(method_name, *targets, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::HasMany} class for the `:has_and_belongs_to_many` macro.
    #
    #   @param [#to_s] method_name
    #   @param [Array<ActsAsTable::Mapper::RecordModel>] targets
    #   @yieldparam [ActsAsTable::Mapper::HasAndBelongsToMany] has_and_belongs_to_many
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::HasAndBelongsToMany]
    # @!method has_many(method_name, *targets, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::HasMany} class for the `:has_many` macro.
    #
    #   @param [#to_s] method_name
    #   @param [Array<ActsAsTable::Mapper::RecordModel>] targets
    #   @yieldparam [ActsAsTable::Mapper::HasMany] has_many
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::HasMany]
    # @!method has_one(method_name, target, &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::BelongsTo} class for the `:has_one` macro.
    #
    #   @param [#to_s] method_name
    #   @param [ActsAsTable::Mapper::RecordModel] target
    #   @yieldparam [ActsAsTable::Mapper::HasOne] has_one
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::HasOne]
    # @!method primary_key(position_or_key = nil, method_name = 'id', &block)
    #   Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::PrimaryKey} class.
    #
    #   @param [Integer, Symbol, nil] position_or_key
    #   @param [#to_s] method_name
    #   @yieldparam [ActsAsTable::Mapper::PrimaryKey] primary_key
    #   @yieldreturn [void]
    #   @return [ActsAsTable::Mapper::PrimaryKey]
    class RecordModel < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::RecordModel} class.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @param [Hash<Symbol, ActsAsTable::ColumnModel>] column_model_by_key
      # @param [#to_s] class_name
      # @yieldparam [ActsAsTable::Mapper::RecordModel] record_model
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::RecordModel]
      def initialize(row_model, column_model_by_key, class_name, &block)
        @row_model, @column_model_by_key = row_model, column_model_by_key

        @record_model = row_model.record_models.build(class_name: class_name)

        super(&block)
      end

      {
        attribute: :Lense,
        belongs_to: :BelongsTo,
        foreign_key: :ForeignKey,
        has_and_belongs_to_many: :HasAndBelongsToMany,
        has_many: :HasMany,
        has_one: :HasOne,
        primary_key: :PrimaryKey,
      }.each do |method_name, const_name|
        define_method(method_name) do |*args, &block|
          ActsAsTable::Mapper.const_get(const_name).new(@row_model, @column_model_by_key, @record_model, *args, &block)
        end
      end
    end

    # ActsAsTable mapper object for an instance of the {ActsAsTable::RowModel} class.
    #
    # @see ActsAsTable::RowModel#draw
    class RowModel < Base
      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::RowModel} class.
      #
      # @param [ActsAsTable::RowModel] row_model
      # @yieldparam [ActsAsTable::Mapper::RowModel] row_model
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::RowModel]
      def initialize(row_model, &block)
        @row_model, @column_model_by_key = row_model, {}

        super(&block)
      end

      # Builds new ActsAsTable column models in the scope of this ActsAsTable row model and caches them by key, if given.
      #
      # @param [#each_pair, #each, #to_s] object
      # @return [ActsAsTable::Mapper::RowModel]
      def columns=(object)
        # @return [Integer]
        column_models_count = @row_model.column_models.size

        # @return [void]
        ::Enumerator.new { |enumerator|
          _dfs(object) { |path|
            enumerator << path
          }
        }.each do |path|
          # @return [Symbol, nil]
          key = path[-1].is_a?(::Symbol) ? path.pop : nil

          column_models_count += 1

          # @return [ActsAsTable::ColumnModel]
          column_model = @row_model.column_models.build(position: column_models_count, **_to_column_model_attributes(path))

          unless key.nil?
            @column_model_by_key[key] = column_model
          end
        end

        self
      end

      # Set the root ActsAsTable record model for this ActsAsTable row model.
      #
      # @param [ActsAsTable::Mapper::RecordModel] target
      # @return [ActsAsTable::Mapper::RowModel]
      def root_model=(target)
        @row_model.root_record_model = target.send(:instance_variable_get, :@record_model)

        self
      end

      # Returns a new ActsAsTable mapper object an instance of the {ActsAsTable::RecordModel} class.
      #
      # @param [#to_s] class_name
      # @yieldparam [ActsAsTable::Mapper::RecordModel] record_model
      # @yieldreturn [void]
      # @return [ActsAsTable::Mapper::RecordModel]
      def model(class_name, &block)
        ActsAsTable::Mapper::RecordModel.new(@row_model, @column_model_by_key, class_name, &block)
      end

      private

      # Performs a depth-first search of the given object and yields each path from root to leaf.
      #
      # @param [#each_pair, #each, #to_s] object
      # @param [Array<#to_s>] path
      # @yieldparam [Array<#to_s>] path
      # @yieldreturn [void]
      # @return [void]
      def _dfs(object, path = [], &block)
        unless block.nil?
          if object.respond_to?(:each_pair)
            object.each_pair do |pair|
              # @return [Array<#to_s>]
              key, new_object = *pair

              # @return [Array<#to_s>]
              new_path = path + [key]

              _dfs(new_object, new_path, &block)
            end
          elsif object.respond_to?(:each)
            object.each do |new_object|
              _dfs(new_object, path, &block)
            end
          else
            # @return [Array<#to_s>]
            new_path = path + [object]

            case block.arity
              when 1 then block.call(new_path)
              else new_path.instance_exec(&block)
            end
          end
        end

        return
      end

      # @return [String]
      COLUMN_MODEL_SEPARATOR_ = "\t".freeze

      # @return [String]
      WHITESPACE_PATTERN_ = /\s+/i.freeze

      # @return [String]
      WHITESPACE_REPLACEMENT_ = ' '.freeze

      # Returns the +ActsAsTable::ColumnModel#attributes+ for the given path.
      #
      # @param [Array<#to_s>] path
      # @return [Hash<Symbol, Object>]
      def _to_column_model_attributes(path)
        {
          name: path.collect(&:to_s).collect(&:strip).collect { |s| s.strip.gsub(WHITESPACE_PATTERN_, WHITESPACE_REPLACEMENT_) }.join(COLUMN_MODEL_SEPARATOR_),
          separator: COLUMN_MODEL_SEPARATOR_,
        }
      end
    end
  end
end
