require 'singleton'

module ActsAsTable
  # ActsAsTable record model class methods (concern).
  module RecordModelClassMethods
    extend ::ActiveSupport::Concern

    class_methods do
      # Returns `true` if the target ActsAsTable record model is reachable from the source ActsAsTable record model. Otherwise, returns `false`.
      #
      # @param [ActsAsTable::RecordModel] source_record_model
      # @param [ActsAsTable::RecordModel] target_record_model
      # @return [Boolean]
      def reachable_record_model_for?(source_record_model, target_record_model)
        Inject.instance.inject(false, source_record_model) { |acc, path, &block|
          # @note Continue until the target ActsAsTable record model is reached.
          acc || (path.options.dig(:data, :target_record_model) == target_record_model) || block.call(acc)
        }
      end

      # Returns the ActsAsTable record models that are reachable from the given ActsAsTable record models (in topological order).
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @return [Array<ActsAsTable::RecordModel>]
      def reachable_record_models_for(record_model)
        Inject.instance.inject([], record_model) { |acc, path, &block|
          # @return [ActsAsTable::RecordModel]
          target_record_model = path.options.dig(:data, :target_record_model)

          # @note Continue until every target ActsAsTable record is reached one or more times.
          if acc.include?(target_record_model)
            acc
          else
            acc << target_record_model

            block.call(acc)
          end
        }
      end

      # Get the value for the given record using the given options.
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      # @raise [ArgumentError]
      def get_value_for(record_model, base = nil, **options)
        GetValue.new(**options).call(record_model, base)
      end

      # Set the new value for the given record using the given options.
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<ActsAsTable::RecordModel, Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>>] new_value_by_record_model_and_value_provider
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      # @raise [ArgumentError]
      def set_value_for(record_model, base = nil, new_value_by_record_model_and_value_provider = {}, **options)
        SetValue.new(new_value_by_record_model_and_value_provider, **options).call(record_model, base)
      end
    end

    # ActsAsTable "non-destructive" traversal (does not create new records if they are not found).
    class Inject
      include ::Singleton

      # Combine all ActsAsTable paths using an associative binary operation.
      #
      # @param [Object] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @yieldparam [Object] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Object]
      # @return [Object]
      def inject(acc, record_model, &block)
        # @return [Class]
        klass = record_model.class_name.constantize

        # @return [ActsAsTable::Path]
        path = ActsAsTable::Path.new(klass, nil, data: {
          source_record_model: nil,
          target_record_model: record_model,
        })

        _inject(acc, path, &block)
      end

      private

      # @param [Object] orig_acc
      # @yieldparam [ActsAsTable::Path] orig_path
      # @yieldparam [Object] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Object]
      # @return [Object]
      def _inject(orig_acc, orig_path, &block)
        block.call(orig_acc, orig_path) do |new_acc|
          # @return [ActsAsTable::RecordModel]
          source_record_model = orig_path.options.dig(:data, :target_record_model)

          %i(belongs_to).each do |macro|
            # @return [Array<ActsAsTable::BelongsTo>]
            macro_reflection_models = source_record_model.persisted? ? source_record_model.send(:"#{macro.to_s.pluralize}_as_source").to_a : source_record_model.row_model.send(:"#{macro.to_s.pluralize}").to_a.select { |macro_reflection_model| macro_reflection_model.source_record_model == source_record_model }

            macro_reflection_models.each do |macro_reflection_model|
              # @return [ActsAsTable::RecordModel]
              target_record_model = macro_reflection_model.target_record_model

              # @return [ActsAsTable::Path]
              new_path = orig_path.send(macro_reflection_model.macro, macro_reflection_model.method_name, data: {
                source_record_model: source_record_model,
                target_record_model: target_record_model,
              })

              new_acc = _inject(new_acc, new_path, &block)
            end
          end

          %i(has_many).each do |macro|
            # @return [Array<ActsAsTable::HasMany>]
            macro_reflection_models = source_record_model.persisted? ? source_record_model.send(:"#{macro.to_s.pluralize}_as_source").to_a : source_record_model.row_model.send(:"#{macro.to_s.pluralize}").to_a.select { |macro_reflection_model| macro_reflection_model.source_record_model == source_record_model }

            macro_reflection_models.each do |macro_reflection_model|
              # @return [Array<ActsAsTable::HasManyTarget>]
              macro_reflection_model_targets = macro_reflection_model.persisted? ? macro_reflection_model.send(:"#{macro.to_s.singularize}_targets").to_a : macro_reflection_model.send(:"#{macro.to_s.singularize}_targets").to_a.sort_by(&:position)

              macro_reflection_model_targets.each do |macro_reflection_model_target|
                # @return [ActsAsTable::RecordModel]
                target_record_model = macro_reflection_model_target.record_model

                # @return [Integer]
                index = macro_reflection_model_target.position - 1

                # @return [ActsAsTable::Path]
                new_path = orig_path.send(macro_reflection_model.macro, macro_reflection_model.method_name, index, data: {
                  source_record_model: source_record_model,
                  target_record_model: target_record_model,
                })

                new_acc = _inject(new_acc, new_path, &block)
              end
            end
          end

          new_acc
        end
      end
    end

    # ActsAsTable "destructive" traversal (creates new records if they are not found and updates persisted records).
    class FindOrInitializeBy
      # Returns the number of mandatory arguments.
      #
      # @return [Integer]
      def arity
        1
      end

      # Invokes the traversal.
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
      def call(record_model, base = nil)
        raise ::NotImplementedError.new("#{self.class}#call")
      end

      # Combine all ActsAsTable paths using an associative binary operation.
      #
      # @param [Object] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @yieldparam [Object] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Object]
      # @return [Object]
      # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
      def inject(acc, record_model, base = nil)
        # @return [Class]
        klass = record_model.class_name.constantize

        # @return [ActsAsTable::Path]
        path = ActsAsTable::Path.new(klass, nil, data: {
          source_record_model: nil,
          source_record: nil,
          target_record_model: record_model,
          target_record: base,
        })

        _inject(acc, path, **{
          find_or_initialize_by: ::Proc.new { |*args, &block|
            ActsAsTable.adapter.find_or_initialize_by_for(record_model, klass, :find_by!, *args, &block)
          },
          new: ::Proc.new { |*args, &block|
            ActsAsTable.adapter.new_for(record_model, klass, :new, *args, &block)
          },
        })
      end

      protected

      # @param [Object] acc
      # @param [ActsAsTable::Path] path
      # @yieldparam [Object] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Object]
      # @return [Object]
      # @raise [ArgumentError]
      def _around_inject(acc, path, &block)
        block.call(acc)
      end

      # @param [Object] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<Symbol, Object>] options
      # @option options [#call] :find_or_initialize_by
      # @option options [#call] :new
      # @return [Array<Object>]
      def _find_or_initialize(acc, record_model, base = nil, **options)
        [acc, base]
      end

      # @param [Object] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @return [ActiveRecord::Base, nil]
      def _at(acc, record_model)
        nil
      end

      private

      # @param [Object] orig_acc
      # @param [ActsAsTable::Path] orig_path
      # @param [Hash<Symbol, Object>] options
      # @option options [#call] :find_or_initialize_by
      # @option options [#call] :new
      # @yieldparam [ActsAsTable::Path] orig_path
      # @yieldparam [Object] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Object]
      # @return [Object]
      # @raise [ArgumentError]
      def _inject(orig_acc, orig_path, **options)
        options.assert_valid_keys(:find_or_initialize_by, :new)

        _around_inject(orig_acc, orig_path) do |new_acc|
          # @return [ActsAsTable::RecordModel]
          source_record_model = orig_path.options.dig(:data, :target_record_model)

          # @return [ActiveRecord::Base, nil]
          source_record = orig_path.options.dig(:data, :target_record)

          unless source_record.nil? || source_record.class.name.eql?(source_record_model.class_name)
            raise ::ArgumentError.new("#{self.name}#_inject - source_record - expected: #{source_record_model.class_name.inspect}, found: #{source_record.inspect}")
          end

          new_acc, source_record = *_find_or_initialize(new_acc, source_record_model, source_record, **options)

          unless source_record.nil?
            %i(belongs_to).each do |macro|
              # @return [Array<ActsAsTable::BelongsTo>]
              macro_reflection_models = source_record_model.persisted? ? source_record_model.send(:"#{macro.to_s.pluralize}_as_source").to_a : source_record_model.row_model.send(:"#{macro.to_s.pluralize}").to_a.select { |macro_reflection_model| macro_reflection_model.source_record_model == source_record_model }

              macro_reflection_models.each do |macro_reflection_model|
                # @return [ActsAsTable::RecordModel]
                target_record_model = macro_reflection_model.target_record_model

                # @return [ActiveRecord::Reflection::MacroReflection]
                reflection = source_record.class.reflect_on_association(macro_reflection_model.method_name)

                # @return [ActiveRecord::Base, nil]
                target_record = source_record.send(reflection.name)

                if target_record.nil?
                  target_record = source_record.send(:"#{reflection.name}=", _at(new_acc, target_record_model))
                end

                # @return [ActsAsTable::Path]
                new_path = orig_path.send(macro_reflection_model.macro, macro_reflection_model.method_name, data: {
                  source_record_model: source_record_model,
                  source_record: source_record,
                  target_record_model: target_record_model,
                  target_record: target_record,
                })

                new_acc = _inject(new_acc, new_path, **options.merge({
                  find_or_initialize_by: ::Proc.new { |*args, &block|
                    source_record.send(:"#{reflection.name}=", ActsAsTable.adapter.find_or_initialize_by_for(target_record_model, reflection.klass, :find_by!, *args, &block))
                  },
                  new: ::Proc.new { |*args, &block|
                    source_record.send(:"#{reflection.name}=", nil)

                    ActsAsTable.adapter.new_for(target_record_model, source_record, :"build_#{reflection.name}", *args, &block)
                  },
                }))
              end
            end

            %i(has_many).each do |macro|
              # @return [Array<ActsAsTable::HasMany>]
              macro_reflection_models = source_record_model.persisted? ? source_record_model.send(:"#{macro.to_s.pluralize}_as_source").to_a : source_record_model.row_model.send(:"#{macro.to_s.pluralize}").to_a.select { |macro_reflection_model| macro_reflection_model.source_record_model == source_record_model }

              macro_reflection_models.each do |macro_reflection_model|
                # @return [ActiveRecord::Reflection::MacroReflection]
                reflection = source_record.class.reflect_on_association(macro_reflection_model.method_name)

                # @return [ActiveRecord::Relation<ActiveRecord::Base>]
                relation = source_record.send(reflection.name)

                # @return [Array<ActiveRecord::Base>]
                target_records = relation.to_a

                # @return [Array<ActsAsTable::HasManyTarget>]
                macro_reflection_model_targets = macro_reflection_model.persisted? ? macro_reflection_model.send(:"#{macro.to_s.singularize}_targets").to_a : macro_reflection_model.send(:"#{macro.to_s.singularize}_targets").to_a.sort_by(&:position)

                macro_reflection_model_targets.each do |macro_reflection_model_target|
                  # @return [ActsAsTable::RecordModel]
                  target_record_model = macro_reflection_model_target.record_model

                  # @return [Integer]
                  index = macro_reflection_model_target.position - 1

                  target_record = \
                    if (index >= 0) && (index < target_records.size)
                      target_records[index]
                    else
                      nil
                    end

                  if target_record.nil?
                    target_record = _at(new_acc, target_record_model)

                    unless target_record.nil? || target_records.include?(target_record)
                      relation.proxy_association.add_to_target(target_record)
                    end
                  end

                  # @return [ActsAsTable::Path]
                  new_path = orig_path.send(macro_reflection_model.macro, macro_reflection_model.method_name, index, data: {
                    source_record_model: source_record_model,
                    source_record: source_record,
                    target_record_model: target_record_model,
                    target_record: target_record,
                  })

                  new_acc = _inject(new_acc, new_path, **options.merge({
                    find_or_initialize_by: ::Proc.new { |*args, &block|
                      ActsAsTable.adapter.find_or_initialize_by_for(target_record_model, relation, :find_by!, *args, &block)
                    },
                    new: ::Proc.new { |*args, &block|
                      ActsAsTable.adapter.new_for(target_record_model, relation, :build, *args, &block)
                    },
                  }))
                end
              end
            end
          end

          new_acc
        end
      end
    end

    # Get the value for the given record using the given options.
    #
    # @!attribute [r] options
    #   The options for this ActsAsTable "destructive" traversal.
    #
    #   @return [Hash<Symbol, Object>]
    class GetValue < FindOrInitializeBy
      attr_reader :options

      # Returns a new ActsAsTable "destructive" traversal.
      #
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::RecordModelClassMethods::GetValue]
      def initialize(**options)
        super()

        options.assert_valid_keys(:default)

        @options = options.dup
      end

      # Invokes the traversal.
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
      def call(record_model, base = nil)
        ActsAsTable.adapter.wrap_value_for(record_model, base, nil, self.inject({}, record_model, base))
      end

      protected

      # @param [Hash<ActsAsTable::RecordModel, ActsAsTable::ValueProvider::WrappedValue>] acc
      # @param [ActsAsTable::Path] path
      # @yieldparam [Hash<ActsAsTable::RecordModel, ActsAsTable::ValueProvider::WrappedValue>] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Hash<ActsAsTable::RecordModel, ActsAsTable::ValueProvider::WrappedValue>]
      # @return [Hash<ActsAsTable::RecordModel, ActsAsTable::ValueProvider::WrappedValue>]
      # @raise [ArgumentError]
      def _around_inject(acc, path, &block)
        acc.key?(path.options.dig(:data, :target_record_model)) ? acc : block.call(acc)
      end

      # @param [Hash<ActsAsTable::RecordModel, ActsAsTable::ValueProvider::WrappedValue>] acc
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<Symbol, Object>] options
      # @option options [#call] :find_or_initialize_by
      # @option options [#call] :new
      # @return [Array<Object>]
      # @raise [ArgumentError]
      def _find_or_initialize(acc, record_model, base = nil, **options)
        acc[record_model] ||= ActsAsTable.adapter.get_value_for(record_model, base, **@options)

        [acc, base]
      end
    end

    # Set the new value for the given record using the given options.
    #
    # @!attribute [r] new_value_by_record_model_and_value_provider
    #   The new values by ActsAsTable record model and value provider for this ActsAsTable "destructive" traversal.
    #
    #   @return [Hash<ActsAsTable::RecordModel, Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>>]
    # @!attribute [r] options
    #   The options for this ActsAsTable "destructive" traversal.
    #
    #   @return [Hash<Symbol, Object>]
    class SetValue < FindOrInitializeBy
      attr_reader :new_value_by_record_model_and_value_provider, :options

      # Returns a new ActsAsTable "destructive" traversal.
      #
      # @param [Hash<ActsAsTable::RecordModel, Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>>] new_value_by_record_model_and_value_provider
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::RecordModelClassMethods::SetValue]
      def initialize(new_value_by_record_model_and_value_provider = {}, **options)
        super()

        options.assert_valid_keys(:default)

        @new_value_by_record_model_and_value_provider, @options = new_value_by_record_model_and_value_provider, options.dup
      end

      # Invokes the traversal.
      #
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
      def call(record_model, base = nil)
        ActsAsTable.adapter.wrap_value_for(record_model, base, nil, self.inject({}, record_model, base))
      end

      protected

      # @param [Hash<ActsAsTable::RecordModel, Array<Object>>] acc
      # @param [ActsAsTable::Path] path
      # @yieldparam [Hash<ActsAsTable::RecordModel, Array<Object>>] acc
      # @yieldparam [ActsAsTable::Path] path
      # @yieldreturn [Hash<ActsAsTable::RecordModel, Array<Object>>]
      # @return [Hash<ActsAsTable::RecordModel, Array<Object>>]
      # @raise [ArgumentError]
      def _around_inject(acc, path, &block)
        # @return [ActsAsTable::RecordModel]
        source_record_model = path.options.dig(:data, :source_record_model)

        # @return [ActsAsTable::RecordModel]
        target_record_model = path.options.dig(:data, :target_record_model)

        if path.collect(&:options).any? { |options| options.dig(:data, :source_record_model) == target_record_model }
          acc
        else
          # @return [Hash<ActsAsTable::RecordModel, Array<Object>>]
          new_acc = block.call(acc)

          unless source_record_model.nil?
            if new_acc[target_record_model][1].changed?
              new_acc[source_record_model][1].changed!
            end
          end

          new_acc
        end
      end

      # @param [Hash<ActsAsTable::RecordModel, Array<Object>>] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @return [ActiveRecord::Base, nil]
      def _at(acc, record_model)
        acc.key?(record_model) ? acc[record_model][0] : nil
      end

      # @param [Hash<ActsAsTable::RecordModel, Array<Object>>] acc
      # @param [ActsAsTable::RecordModel] record_model
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<Symbol, Object>] options
      # @option options [#call] :find_or_initialize_by
      # @option options [#call] :new
      # @return [Array<Object>]
      # @raise [ArgumentError]
      def _find_or_initialize(acc, record_model, base = nil, **options)
        acc[record_model] ||= begin
          # @return [Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>, nil]
          orig_value_by_value_provider = @new_value_by_record_model_and_value_provider.try(:[], record_model)

          unless (primary_key = record_model.primary_keys.first).nil? || (base_id = orig_value_by_value_provider.try(:[], primary_key)).nil?
            # @return [ActiveRecord::Base]
            # @raise [ActiveRecord::RecordNotFound]
            base = options[:find_or_initialize_by].call({
              primary_key.method_name => base_id,
            })

            # @return [Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>, nil]
            new_value_by_value_provider = orig_value_by_value_provider.try(:each_pair).try(:all?) { |pair|
              (pair[0] == primary_key) || pair[0].column_model.nil? || pair[1].nil?
            } ? orig_value_by_value_provider.try(:delete_if) { |value_provider, value|
              value_provider != primary_key
            } : orig_value_by_value_provider.try(:delete_if) { |value_provider, value|
              value_provider.column_model.nil?
            }

            [
              base,
              ActsAsTable.adapter.set_value_for(record_model, base, new_value_by_value_provider, **@options),
            ]
          else
            if base.nil?
              base = options[:new].call
            end

            [
              base,
              ActsAsTable.adapter.set_value_for(record_model, base, orig_value_by_value_provider, **@options),
            ]
          end
        end

        [acc, base]
      end
    end
  end
end
