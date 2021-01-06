module ActsAsTable
  class Engine < ::Rails::Engine
    isolate_namespace ActsAsTable

    initializer 'acts_as_table.active_record' do |app|
      ::ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Base.class_eval do
          include ActsAsTable::ValueProvider
          include ActsAsTable::ValueProviderAssociationMethods
        end
      end
    end
  end
end
