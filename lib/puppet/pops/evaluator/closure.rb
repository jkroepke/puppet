

class Puppet::Pops::Evaluator::Lambda
  attr_reader :evaluator
  attr_reader :model
  attr_reader :enclosing_scope

  def initialize(evaluator, model, scope)
    @evaluator = evaluator
    @model = model
    @enclosing_scope = scope
  end

  # marker method checked with respond_to :puppet_lambda
  def puppet_lambda()
    true
  end

  # compatible with 3x AST::Lambda
  def call(scope, *args)
    @evaluator.call(self, args, @enclosing_scope)
  end

  # incompatible with 3x except that it is an array of the same size
  def parameters()
    @model.parameters || []
  end

  # Returns the number of parameters (required and optional)
  # @return [Integer] the total number of accepted parameters
  def parameter_count
    # yes, this is duplication of code, but it saves a method call
    (@model.parameters || []).size
  end

end
