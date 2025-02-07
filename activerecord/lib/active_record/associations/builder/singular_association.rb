# frozen_string_literal: true

# This class is inherited by the has_one and belongs_to association classes

module ActiveRecord::Associations::Builder # :nodoc:
  class SingularAssociation < Association # :nodoc:
    def self.valid_options(options)
      super + [:required, :touch]
    end

    def self.define_accessors(model, reflection)
      super
      mixin = model.generated_association_methods
      name = reflection.name
      association_deprecated = reflection.try(:association_deprecated?) || false
      model_name = model.name

      define_constructors(mixin, name, association_deprecated, model_name) unless reflection.polymorphic?

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def reload_#{name}
          if #{association_deprecated}
            ActiveRecord.deprecator.warn("The association #{name} #{model_name.present? and "on #{model_name}"} has been deprecated.")
          end

          association(:#{name}).force_reload_reader
        end

        def reset_#{name}
          if #{association_deprecated}
            ActiveRecord.deprecator.warn("The association #{name} #{model_name.present? and "on #{model_name}"} has been deprecated.")
          end

          association(:#{name}).reset
        end
      CODE
    end

    # Defines the (build|create)_association methods for belongs_to or has_one association
    def self.define_constructors(mixin, name, association_deprecated = false, model_name = nil)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def build_#{name}(*args, &block)
          if #{association_deprecated}
            ActiveRecord.deprecator.warn("The association #{name} #{model_name.present? and "on #{model_name}"} has been deprecated.")
          end

          association(:#{name}).build(*args, &block)
        end

        def create_#{name}(*args, &block)
          if #{association_deprecated}
            ActiveRecord.deprecator.warn("The association #{name} #{model_name.present? and "on #{model_name}"} has been deprecated.")
          end

          association(:#{name}).create(*args, &block)
        end

        def create_#{name}!(*args, &block)
          if #{association_deprecated}
            ActiveRecord.deprecator.warn("The association #{name} #{model_name.present? and "on #{model_name}"} has been deprecated.")
          end

          association(:#{name}).create!(*args, &block)
        end
      CODE
    end

    private_class_method :valid_options, :define_accessors, :define_constructors
  end
end
